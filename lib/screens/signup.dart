import 'dart:async';
import 'package:booking_app/screens/custom_text_field.dart';
import 'package:booking_app/screens/signin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../../../theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool showConfetti = false;

  late AnimationController _fadeController;
  late AnimationController _buttonGlowController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for fields
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Glowing button animation
    _buttonGlowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _buttonGlowController, curve: Curves.easeInOut),
    );

    Timer(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _buttonGlowController.dispose();
    super.dispose();
  }

  bool isStrongPassword(String password) {
    final hasLetter = password.contains(RegExp(r'[A-Za-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    return password.length >= 6 && hasLetter && hasNumber;
  }

  Future<void> _signup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    if (!isStrongPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password must be at least 6 characters and contain letters & numbers",
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCred.user!.uid;

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": name,
        "email": email,
        "createdAt": FieldValue.serverTimestamp(),
      });

      setState(() {
        isLoading = false;
        showConfetti = true;
      });

      // 🎉 Play confetti for 2 seconds, then navigate
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => showConfetti = false);

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, anim, __) =>
                FadeTransition(opacity: anim, child: const SigninScreen()),
          ),
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signup successful! 🎉")));
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      String message = "Something went wrong";
      if (e.code == 'weak-password') {
        message = "Password is too weak";
      } else if (e.code == 'email-already-in-use') {
        message = "Email already exists";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unexpected error occurred")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🟣 Animated background gradient
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

          // 🎉 Confetti animation overlay
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
                        "Create Account",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 🔹 Animated text fields
                    _animatedField(
                      CustomTextField(
                        controller: nameController,
                        hintText: "Full Name",
                      ),
                      0,
                    ),
                    const SizedBox(height: 16),
                    _animatedField(
                      CustomTextField(
                        controller: emailController,
                        hintText: "Email",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      1,
                    ),
                    const SizedBox(height: 16),
                    _animatedField(
                      CustomTextField(
                        controller: passwordController,
                        hintText: "Password",
                        isPassword: true,
                      ),
                      2,
                    ),
                    const SizedBox(height: 16),
                    _animatedField(
                      CustomTextField(
                        controller: confirmPasswordController,
                        hintText: "Re-enter Password",
                        isPassword: true,
                      ),
                      3,
                    ),

                    const SizedBox(height: 30),

                    // ✨ Glowing animated button
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
                                  onPressed: _signup,
                                  child: const Text(
                                    "Sign Up",
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

                    const SizedBox(height: 20),

                    // 🔁 Hero transition link
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
                                child: const SigninScreen(),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Already have an account? Sign in",
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
