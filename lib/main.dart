import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
<<<<<<< HEAD
      systemNavigationBarColor: Color(0xFF000000),
=======
      systemNavigationBarColor: Color(0xFF0A0E21),
>>>>>>> 49ff633392ff1748c09a530ced8f14c475302a7d
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CatchTheTrainApp());
}

class CatchTheTrainApp extends StatelessWidget {
  const CatchTheTrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catch The Train',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
<<<<<<< HEAD
    const primaryColor = Color(0xFF1a1a1a);
    const accentColor = Color(0xFF00FF41);
    const bgColor = Color(0xFF000000);
    const surfaceColor = Color(0xFF0a0a0a);
    const cardColor = Color(0xFF1a1a1a);
=======
    const primaryColor = Color(0xFF6C63FF);
    const accentColor = Color(0xFF00D4AA);
    const bgColor = Color(0xFF0A0E21);
    const surfaceColor = Color(0xFF141831);
    const cardColor = Color(0xFF1E2340);
>>>>>>> 49ff633392ff1748c09a530ced8f14c475302a7d

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
<<<<<<< HEAD
          borderSide: const BorderSide(color: Color(0xFF2a2a2a), width: 1.5),
=======
          borderSide: const BorderSide(color: Color(0xFF2E3460), width: 1.5),
>>>>>>> 49ff633392ff1748c09a530ced8f14c475302a7d
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
<<<<<<< HEAD
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 14),
=======
        labelStyle: const TextStyle(color: Color(0xFF8B92B8), fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF4A5178), fontSize: 14),
>>>>>>> 49ff633392ff1748c09a530ced8f14c475302a7d
        prefixIconColor: primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
