import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'driver_safety_screen.dart';
import 'profile/statistics_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MainScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      body: Stack(
        children: [
          // Screens
          IndexedStack(
            index: _currentIndex,
            children: [
              DriverSafetyScreen(cameras: widget.cameras),
              const StatisticsScreen(),
              const ProfileScreen(),
            ],
          ),

          // Floating Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35), // "Bit circular"
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.camera_alt_outlined, Icons.camera_alt,
                      'Monitor'),
                  _buildNavItem(
                      1, Icons.bar_chart_outlined, Icons.bar_chart, 'Stats'),
                  _buildNavItem(
                      2, Icons.person_outline, Icons.person, 'Profile'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData iconOutlined, IconData iconFilled, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFE8F5F0),
                borderRadius: BorderRadius.circular(25),
              )
            : null,
        child: Row(
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected ? const Color(0xFF7FC8A9) : Colors.grey,
              size: 28,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7FC8A9),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
