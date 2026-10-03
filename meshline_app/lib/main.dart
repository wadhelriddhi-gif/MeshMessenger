import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MeshlineApp());
}

class MeshlineApp extends StatelessWidget {
  const MeshlineApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meshline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white, useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}