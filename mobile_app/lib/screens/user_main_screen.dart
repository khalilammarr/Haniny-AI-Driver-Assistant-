import 'package:flutter/material.dart';
import 'profile/statistics_screen.dart';
import 'profile/profile_screen.dart';
import '../services/accident_detection_service.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({Key? key}) : super(key: key);

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _currentIndex = 0;
  final AccidentDetectionService _accidentDetection =
      AccidentDetectionService();

  @override
  void initState() {
    super.initState();
    // Start accident detection monitoring
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _accidentDetection.startMonitoring(context);
    });
  }

  @override
  void dispose() {
    _accidentDetection.dispose();
    super.dispose();
  }

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
              const StatisticsScreen(),
              const ProfileScreen(),
            ],
          ),

          // Floating Navigation Bar
          Positioned(
            left: 40,
            right: 40,
            bottom: 30,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(35),
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
                  _buildNavItem(
                      0, Icons.bar_chart_outlined, Icons.bar_chart, 'Stats'),
                  _buildNavItem(
                      1, Icons.person_outline, Icons.person, 'Profile'),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
