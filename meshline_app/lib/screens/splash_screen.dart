import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SetupScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradient(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MeshLogo(size: 88),
              const SizedBox(height: 16),
              const Text('Meshline',
                  style: TextStyle(color: AppColors.textDark, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Resilient mesh messenger', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}