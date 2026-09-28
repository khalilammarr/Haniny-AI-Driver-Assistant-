import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'dart:ui';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Watermark Effect
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF5E6D3), // Beige
                    Color(0xFFFFF3E0), // Lighter Beige
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Watermark Logo
                  Positioned(
                    right: -100,
                    top: -50,
                    child: Opacity(
                      opacity: 0.05,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Image.asset(
                          'assets/haniny_green.png',
                          width: 500,
                          height: 500,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Logo with Squircle Shape and Enhanced Shadow
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        // Deep shadow for "imprinted" look
                        BoxShadow(
                          color: const Color(0xFF2D4739).withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                          spreadRadius: 0,
                        ),
                        // Inner glow/highlight
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(-5, -5),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.asset(
                        'assets/haniny_last.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App Name
                  Text(
                    'HANINY',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          letterSpacing: 3,
                          color: const Color(0xFF2C3E50),
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Tagline
                  Text(
                    'Your Safety, Our Priority',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          letterSpacing: 1,
                          color: const Color(0xFF455A64),
                        ),
                  ),

                  const Spacer(),

                  // Get Started Button
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7FC8A9), Color(0xFF66B090)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7FC8A9).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'GET STARTED',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF7FC8A9), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        foregroundColor: const Color(0xFF7FC8A9),
                      ),
                      child: const Text(
                        'SIGN IN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
