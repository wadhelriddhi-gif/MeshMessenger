import 'package:flutter/material.dart';
import '../services/mesh_api.dart';
import '../services/backend_api.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _meshUrl = TextEditingController(text: 'http://10.0.2.2:8081');
  final _backendUrl = TextEditingController(text: 'http://10.0.2.2:8080');
  String? _error;
  bool _busy = false;

  Future<void> _connect() async {
    setState(() { _busy = true; _error = null; });
    try {
      final api = MeshApi(_meshUrl.text.trim());
      await api.getStatus();
      final backend = BackendApi(_backendUrl.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen(api: api, backend: backend)));
    } catch (e) {
      setState(() => _error = 'Could not connect. Is your mesh node running?');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: Column(
            children: [
              const BrandHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Center(child: MeshLogo(size: 72)),
                      const SizedBox(height: 8),
                      const Center(
                          child: Text('Meshline',
                              style: TextStyle(color: AppColors.textDark, fontSize: 22, fontWeight: FontWeight.w800))),
                      const SizedBox(height: 28),
                      const Text('Secure Mesh Messenger', style: AppTextStyles.heading),
                      const SizedBox(height: 4),
                      const Text('Connect your device to the mesh', style: AppTextStyles.subheading),
                      const SizedBox(height: 20),
                      TextField(controller: _meshUrl, style: const TextStyle(color: AppColors.textDark),
                          decoration: meshInputDecoration('Mesh node address')),
                      const SizedBox(height: 12),
                      TextField(controller: _backendUrl, style: const TextStyle(color: AppColors.textDark),
                          decoration: meshInputDecoration('Admin backend address')),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Padding(padding: const EdgeInsets.only(bottom: 12),
                            child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
                      ElevatedButton(
                        onPressed: _busy ? null : _connect,
                        style: meshPrimaryButton(),
                        child: Text(_busy ? 'Connecting...' : 'Connect'),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                          child: Text('Encrypted • Offline-ready • Secure',
                              style: TextStyle(color: AppColors.textGrey, fontSize: 12))),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}