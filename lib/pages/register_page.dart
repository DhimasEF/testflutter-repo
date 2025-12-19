import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String message = '';

  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> images = [
    'assets/slide1.jpg',
    'assets/slide2.jpg',
    'assets/slide3.jpg',              
    // '../assets/slide1.jpg',
    // '../assets/slide2.jpg',
    // '../assets/slide3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _currentPage = (_currentPage + 1) % images.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ================= REGISTER LOGIC (TETAP)
  Future<void> register() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    final result = await ApiService.register(
      usernameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      message = result['message'] ?? '';
      isLoading = false;
    });
  }

  // ================= UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND SLIDESHOW
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            itemBuilder: (_, index) {
              return Image.asset(
                images[index],
                fit: BoxFit.cover,
              );
            },
          ),

          /// DARK OVERLAY
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          /// GLASS REGISTER CARD
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Daftar akun baru',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),

                        _inputField(
                          controller: usernameController,
                          hint: 'Username',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),

                        _inputField(
                          controller: emailController,
                          hint: 'Email',
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 16),

                        _inputField(
                          controller: passwordController,
                          hint: 'Password',
                          icon: Icons.lock,
                          obscure: true,
                        ),

                        const SizedBox(height: 24),

                        isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Register',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Sudah punya akun? Login',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),

                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
