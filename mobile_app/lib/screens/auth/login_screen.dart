import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (error == null) {
        Navigator.pushReplacementNamed(context, '/user_home');
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color(0xFF2C3E50)), // Dark back button
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background with Watermark
          Container(
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
                Positioned(
                  right: -80,
                  top: -40,
                  child: Opacity(
                    opacity: 0.05,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Image.asset(
                        'assets/haniny_green.png',
                        width: 400,
                        height: 400,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D4739).withOpacity(0.2),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 15,
                              offset: const Offset(-4, -4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: Image.asset(
                            'assets/haniny_last.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Title
                      Text(
                        'Welcome Back',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 28,
                                  color: const Color(0xFF2C3E50),
                                ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Sign in to continue',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF455A64),
                            ),
                      ),

                      const SizedBox(height: 40),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.redAccent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style:
                                      const TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Color(0xFF2C3E50)),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Color(0xFF2C3E50)),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 40),

                      // Login Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7FC8A9), Color(0xFF66B090)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7FC8A9).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'SIGN IN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
