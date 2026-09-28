import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'driver_safety_screen.dart';
import 'user_main_screen.dart';
import 'auth/welcome_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const ModeSelectionScreen({Key? key, required this.cameras})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/haniny_green.png',
                height: 120,
              ),
              const SizedBox(height: 40),
              const Text(
                'Select Mode',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 40),
              _buildModeButton(
                context,
                title: 'Hardware Mode',
                subtitle: 'Driver Monitoring & Alerts',
                icon: Icons.camera_alt,
                color: const Color(0xFF2C3E50),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DriverSafetyScreen(cameras: cameras),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildModeButton(
                context,
                title: 'User App Mode',
                subtitle: 'Stats, Profile & Settings',
                icon: Icons.person,
                color: const Color(0xFF7FC8A9),
                onTap: () {
                  // Navigate to User App Entry (UserMainScreen or Login)
                  // We can reuse the logic from main_user.dart or just go to UserMainScreen
                  // But main_user.dart handles the auth check.
                  // Let's just navigate to the UserApp wrapper if possible, or directly to Splash/Login
                  // For simplicity, let's go to the UserApp widget from main_user.dart if it was a widget,
                  // but it's a main function.
                  // So we'll navigate to the UserApp's initial route logic.
                  // Since we are already in an app, we can just push the UserMainScreen or LoginScreen.
                  // But better to use the UserApp root widget if we refactor main_user.dart.

                  // For now, let's assume we want to go to the "User App" flow.
                  // We'll navigate to a wrapper that decides login vs home, similar to main_user.dart
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UserAppLauncher()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// Wrapper to handle User App initial navigation logic
class UserAppLauncher extends StatefulWidget {
  const UserAppLauncher({super.key});

  @override
  State<UserAppLauncher> createState() => _UserAppLauncherState();
}

class _UserAppLauncherState extends State<UserAppLauncher> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (mounted) {
      if (token != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserMainScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5E6D3),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
