import 'dart:async';
import 'package:flutter/material.dart';
import '../models/peer.dart';
import '../services/mesh_api.dart';
import '../services/backend_api.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'rooms_screen.dart';
import 'admin_screen.dart';

class HomeScreen extends StatefulWidget {
  final MeshApi api;
  final BackendApi backend;
  const HomeScreen({super.key, required this.api, required this.backend});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  List<Peer> _peers = [];
  Map<String, dynamic>? _status;
  Map<String, dynamic>? _metrics;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final peers = await widget.api.getPeers();
      final status = await widget.api.getStatus();
      final metrics = await widget.api.getMetrics();
      if (mounted) setState(() { _peers = peers; _status = status; _metrics = metrics; });
    } catch (_) {}
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final revoked = _status?['revoked'] == true;
    final bodies = [_peersTab(revoked), RoomsScreen(api: widget.api), AdminScreen(backend: widget.backend)];

    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('MESHLINE', style: AppTextStyles.wordmark),
                    if (_status != null)
                      Text('${_status!['name']}',
                          style: const TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(child: bodies[_tab]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wifi_tethering), label: 'Peers'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Rooms'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }

  Widget _peersTab(bool revoked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Nearby devices', style: AppTextStyles.heading),
            const SizedBox(height: 4),
            Text('${_peers.length} device${_peers.length == 1 ? '' : 's'} found', style: AppTextStyles.subheading),
          ]),
        ),
        if (revoked)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Text('This device has been revoked by admin',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
          ),
        if (_metrics != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _metricChip('Sent', '${_metrics!['sent']}'),
              _metricChip('Delivered', '${_metrics!['delivered']}'),
              _metricChip('Queued', '${_metrics!['queued']}'),
              _metricChip('Reconnects', '${_metrics!['reconnections']}'),
            ]),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: _peers.isEmpty
              ? const Center(child: Text('Searching for nearby devices...', style: AppTextStyles.subheading))
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: _peers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = _peers[i];
              return Material(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: p.revoked
                      ? null
                      : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChatScreen(api: widget.api, peerName: p.name))),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: p.revoked ? AppColors.danger : AppColors.online)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name,
                              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(p.revoked ? 'revoked' : 'online',
                              style: TextStyle(
                                  color: p.revoked ? AppColors.danger : AppColors.online,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textGrey),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _metricChip(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 18)),
    Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
  ]);
}