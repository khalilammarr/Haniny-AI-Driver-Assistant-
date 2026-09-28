import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user_main_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if user is logged in
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final initialRoute = token != null ? '/user_home' : '/welcome';

  runApp(UserApp(initialRoute: initialRoute));
}

class UserApp extends StatelessWidget {
  final String initialRoute;
  const UserApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haniny User',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        // fontFamily: 'Roboto', // Commented out to use system default to use system default
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
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
