import 'package:flutter/material.dart';
import '../models/device_record.dart';
import '../services/backend_api.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  final BackendApi backend;
  const AdminScreen({super.key, required this.backend});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<DeviceRecord> _devices = [];
  String? _error;

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    try {
      final devices = await widget.backend.getDevices();
      if (mounted) setState(() { _devices = devices; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not reach the backend server.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Admin • Device Revocation',
              style: TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)))
                  : ListView.separated(
                itemCount: _devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final d = _devices[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(16)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Fingerprint: ${d.fingerprint}', style: AppTextStyles.subheading),
                      const SizedBox(height: 4),
                      Text(d.revoked ? 'Status: revoked' : 'Status: active',
                          style: TextStyle(color: d.revoked ? AppColors.danger : AppColors.online, fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: d.revoked ? AppColors.primary : AppColors.danger,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                          onPressed: () async {
                            if (d.revoked) { await widget.backend.restore(d.id); } else { await widget.backend.revoke(d.id); }
                            _refresh();
                          },
                          child: Text(d.revoked ? 'Restore' : 'Revoke', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}