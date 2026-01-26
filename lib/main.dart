import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/instagram_theme.dart';

void main() {
  runApp(const BSmartApp());
}

class BSmartApp extends StatelessWidget {
  const BSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'b Smart',
      debugShowCheckedModeBanner: false,
      theme: InstagramTheme.theme,
      home: const LoginScreen(),
    );
  }
}
