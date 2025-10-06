import 'dart:async';
import 'package:booking_app/screens/homeScreen.dart';
import 'package:booking_app/screens/signup.dart';
import 'package:booking_app/screens/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../../../theme/app_colors.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool showConfetti = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Initialize safely before any rebuilds
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Start fade animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      setState(() {
        isLoading = false;
        showConfetti = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login successful! 🎉")));

      Future.delayed(const Duration(seconds: 2), () {
        setState(() => showConfetti = false);

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, anim, __) =>
                FadeTransition(opacity: anim, child: const HomeScreen()),
          ),
        );
      });
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "No user found with this email";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unexpected error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Animated gradient background
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF101820),
                  Color(0xFF2E3192),
                  Color(0xFF1BFFFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🎊 Confetti effect
          if (showConfetti)
            Center(
              child: Lottie.asset(
                'assets/animations/confetti.json',
                repeat: false,
                width: 300,
                height: 300,
              ),
            ),

          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Hero(
                      tag: "authTitle",
                      child: Text(
                        "Welcome Back",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    _animatedField(
                      CustomTextField(
                        controller: emailController,
                        hintText: "Email",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      0,
                    ),
                    const SizedBox(height: 16),
                    _animatedField(
                      CustomTextField(
                        controller: passwordController,
                        hintText: "Password",
                        isPassword: true,
                      ),
                      1,
                    ),
                    const SizedBox(height: 24),

                    // ✨ Glowing Sign In button
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(
                                  0.6 * (_glowAnimation.value / 12),
                                ),
                                blurRadius: _glowAnimation.value,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _signin,
                                  child: const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    Hero(
                      tag: "signinButton",
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: const Duration(
                                milliseconds: 600,
                              ),
                              pageBuilder: (_, anim, __) => FadeTransition(
                                opacity: anim,
                                child: const SignupScreen(),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Don’t have an account? Sign up",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedField(Widget child, int index) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeController,
        curve: Interval(0.1 * index, 1, curve: Curves.easeIn),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _fadeController,
                curve: Interval(0.1 * index, 1, curve: Curves.easeOut),
              ),
            ),
        child: child,
      ),
    );
  }
}
