import 'dart:async';
import 'package:flutter/material.dart';
import '../models/mesh_message.dart';
import '../models/room.dart';
import '../services/mesh_api.dart';
import '../theme/app_theme.dart';

class RoomChatScreen extends StatefulWidget {
  final MeshApi api;
  final Room room;
  const RoomChatScreen({super.key, required this.api, required this.room});
  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
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
      final mine = all.where((m) => widget.room.members.contains(m.peer)).toList();
      mine.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (mounted) setState(() => _messages = mine);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    for (final member in widget.room.members) {
      await widget.api.sendMessage(member, text);
    }
    _refresh();
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

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
                  IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
                  Text(widget.room.name, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
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
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(sent ? 'You → ${m.peer}' : m.peer,
                              style: TextStyle(fontSize: 10, color: sent ? Colors.white70 : AppColors.primary, fontWeight: FontWeight.w700)),
                          Text(m.text, style: TextStyle(color: sent ? Colors.white : AppColors.textDark)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Message the room...',
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
}