import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dashboard_admin.dart';
import 'dashboard_creator.dart';
import 'dashboard_user.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String message = '';

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> images = [
    'assets/slide1.jpg',
    'assets/slide2.jpg',
    'assets/slide3.jpg',              
    // '../assets/slide1.jpg',
    // '../assets/slide2.jpg',
    // '../assets/slide3.jpg',              
  ];

  Timer? _timer;      

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

  // ================= LOGIN LOGIC (TETAP)
  Future<void> login() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final result = await ApiService.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      if (result['status'] == true && result['user'] != null) {
        final user = result['user'];
        final role = user['role'] ?? 'user';

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['token'] ?? '');
        await prefs.setInt('id_user', int.parse(user['id_user'].toString()));
        await prefs.setString('username', user['username'] ?? '');
        await prefs.setString('email', user['email'] ?? '');
        await prefs.setString('role', role);

        Widget nextPage;
        switch (role) {
          case 'admin':
            nextPage = AdminDashboardPage();
            break;
          case 'creator':
            nextPage = CreatorDashboardPage();
            break;
          default:
            nextPage = UserDashboardPage();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextPage),
        );
      } else {
        setState(() {
          message = result['message'] ?? 'Login gagal';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Terjadi kesalahan: $e';
      });
    }

    setState(() {
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

          /// DARK GRADIENT OVERLAY
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

          /// GLASS LOGIN CARD
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
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Login ke akun kamu',
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
                          controller: passwordController,
                          hint: 'Password',
                          icon: Icons.lock,
                          obscure: true,
                        ),

                        const SizedBox(height: 24),

                        isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RegisterPage()),
                            );
                          },
                          child: const Text(
                            'Belum punya akun? Register',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),

                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            message,
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ]
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
