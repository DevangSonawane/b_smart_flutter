import 'package:flutter/material.dart';
import 'home_dashboard.dart';

// Legacy redirect - keeping for compatibility
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeDashboard();
  }
}
