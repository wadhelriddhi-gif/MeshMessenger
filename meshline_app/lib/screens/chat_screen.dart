import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/mesh_message.dart';
import '../services/mesh_api.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final MeshApi api;
  final String peerName;
  const ChatScreen({super.key, required this.api, required this.peerName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<MeshMessage> _messages = [];
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final all = await widget.api.getMessages();
      final mine = all.where((m) => m.peer == widget.peerName).toList();
      if (mounted) setState(() => _messages = mine);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await widget.api.sendMessage(widget.peerName, text);
    _refresh();
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 3 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Please choose a smaller image (under 3MB).')));
      }
      return;
    }
    await widget.api.sendFile(widget.peerName, picked.name, base64Encode(bytes));
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(children: [
                  IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                      onPressed: () => Navigator.pop(context)),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.peerName,
                          style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
                      Row(children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.online)),
                        const SizedBox(width: 6),
                        const Text('encrypted connection',
                            style: TextStyle(color: AppColors.online, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    final sent = m.direction == 'SENT';
                    return Align(
                      alignment: sent ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: const BoxConstraints(maxWidth: 270),
                        decoration: BoxDecoration(
                          color: sent ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (m.fileData != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(base64Decode(m.fileData!), width: 200, fit: BoxFit.cover),
                            )
                          else
                            Text(m.text,
                                style: TextStyle(
                                    color: sent ? Colors.white : AppColors.textDark,
                                    fontWeight: sent ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(_label(m.status),
                              style: TextStyle(fontSize: 11, color: sent ? Colors.white70 : AppColors.textGrey)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickAndSendImage,
                      child: const Padding(
                          padding: EdgeInsets.all(12), child: Icon(Icons.attach_file, color: AppColors.textGrey)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: AppColors.textGrey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _send,
                      child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.send, color: Colors.white, size: 20)),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(String status) {
    switch (status) {
      case 'DELIVERED':
        return '✓✓ delivered';
      case 'QUEUED':
        return '⏳ queued (offline)';
      case 'BLOCKED':
        return '⛔ blocked (revoked)';
      default:
        return status;
    }
  }
}