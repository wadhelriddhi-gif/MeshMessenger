import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/mesh_api.dart';
import '../theme/app_theme.dart';
import 'room_chat_screen.dart';

class RoomsScreen extends StatefulWidget {
  final MeshApi api;
  const RoomsScreen({super.key, required this.api});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final List<Room> _rooms = [];

  Future<void> _createRoom() async {
    final peers = await widget.api.getPeers();
    final nameController = TextEditingController();
    final selected = <String>{};
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New room', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameController, style: const TextStyle(color: AppColors.textDark), decoration: meshInputDecoration('Room name')),
            const SizedBox(height: 12),
            ...peers.map((p) => CheckboxListTile(
              activeColor: AppColors.primary,
              title: Text(p.name, style: const TextStyle(color: AppColors.textDark)),
              value: selected.contains(p.name),
              onChanged: (v) => setDialog(() { if (v == true) { selected.add(p.name); } else { selected.remove(p.name); } }),
            )),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty || selected.isEmpty) return;
                setState(() => _rooms.add(Room(name: nameController.text.trim(), members: selected.toList())));
                Navigator.pop(ctx);
              },
              child: const Text('Create', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Rooms', style: AppTextStyles.heading),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _createRoom, style: meshPrimaryButton(), child: const Text('+ Create room')),
          const SizedBox(height: 20),
          Expanded(
            child: _rooms.isEmpty
                ? const Center(child: Text('No rooms yet', style: AppTextStyles.subheading))
                : ListView.separated(
              itemCount: _rooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final r = _rooms[i];
                return Material(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => RoomChatScreen(api: widget.api, room: r))),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('${r.members.length} members', style: AppTextStyles.subheading),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}