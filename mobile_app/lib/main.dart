import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user_main_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/mode_selection_screen.dart';

// Global cameras variable
List<CameraDescription> cameras = [];

Future<List<CameraDescription>> safeAvailableCameras() async {
  if (kIsWeb || Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    debugPrint('💻 Desktop/Web detected: skipping cameras...');
    return [];
  }
  try {
    return await availableCameras();
  } catch (e) {
    debugPrint('Error initializing cameras: $e');
    return [];
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await safeAvailableCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Driver Safety Monitor',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5E6D3),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF7FC8A9),
          secondary: const Color(0xFFFF8C42),
          surface: Colors.white,
          background: const Color(0xFFF5E6D3),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          bodyLarge: TextStyle(color: Color(0xFF455A64)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFF7FC8A9),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF7FC8A9), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF455A64)),
          prefixIconColor: const Color(0xFF7FC8A9),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
        ),
        useMaterial3: true,
      ),
      // Show ModeSelectionScreen first
      home: ModeSelectionScreen(cameras: cameras),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/user_home': (context) => const UserMainScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
