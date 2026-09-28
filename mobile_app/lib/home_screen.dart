import 'package:flutter/material.dart';
import 'screens/driver_safety_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/statistics_screen.dart';
import 'main.dart'; // To access cameras list if needed, but better to pass it or use a provider.
// For simplicity in this refactor without state management, I'll assume cameras are passed or global.
// Actually, main.dart passes cameras to MyApp. I need to get them here.
// A quick fix is to make cameras global or pass them down.
// I will modify main.dart to make cameras accessible or pass them.
// For now, let's assume we can get them from a global variable or constructor.

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // We need the cameras list. Since I can't easily change the whole app architecture to Provider/Riverpod right now,
  // I will import the global cameras variable I will add to main.dart.

  @override
  Widget build(BuildContext context) {
    // Pages list
    final List<Widget> _pages = [
      // 0: Monitor (DriverSafetyScreen)
      // We need to pass cameras here. I'll update main.dart to expose `cameras` globally or use a singleton.
      // For this step, I'll assume `cameras` is available globally from main.dart
      DriverSafetyScreen(cameras: cameras),

      // 1: Statistics
      const StatisticsScreen(),

      // 2: Profile
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF7FC8A9),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: 'Monitor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
