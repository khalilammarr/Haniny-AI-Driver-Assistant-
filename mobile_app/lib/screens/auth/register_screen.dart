import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _carModelController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _carModelController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await _apiService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _carModelController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (error == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        setState(() {
          if (error.contains('Email already registered')) {
            _errorMessage = 'Email already in use';
          } else if (error.contains('Connection error')) {
            _errorMessage = 'Connection error';
          } else {
            _errorMessage = 'Registration failed';
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unexpected error: ${e.toString()}';
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
          // Background
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
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7FC8A9).withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.asset(
                            'assets/haniny_green.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Create Account',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 28,
                                  color: const Color(0xFF2C3E50),
                                ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Join Haniny for safer driving',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF455A64),
                            ),
                      ),

                      const SizedBox(height: 32),

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

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Color(0xFF2C3E50)),
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

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
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Car Model Field
                      TextFormField(
                        controller: _carModelController,
                        style: const TextStyle(color: Color(0xFF2C3E50)),
                        decoration: const InputDecoration(
                          labelText: 'Car Model',
                          prefixIcon: Icon(Icons.directions_car_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your car model';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

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
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Color(0xFF2C3E50)),
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 40),

                      // Register Button
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
                          onPressed: _isLoading ? null : _register,
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
                                  'CREATE ACCOUNT',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),
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
