import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const CatchTheTrainApp());
}

class CatchTheTrainApp extends StatelessWidget {
  const CatchTheTrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Local Train Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

