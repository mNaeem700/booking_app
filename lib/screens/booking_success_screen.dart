import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../theme/app_colors.dart';

class BookingSuccessScreen extends StatefulWidget {
  final String serviceName;
  final String date;
  final String time;

  const BookingSuccessScreen({
    super.key,
    required this.serviceName,
    required this.date,
    required this.time,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    )..play();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 🎊 Confetti effect
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -pi / 2,
            emissionFrequency: 0.05,
            numberOfParticles: 12,
            gravity: 0.08,
            colors: const [
              AppColors.primary,
              Colors.pinkAccent,
              Colors.orange,
              Colors.purpleAccent,
            ],
          ),

          // 🌟 Main content (centered)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Big Check Icon
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 110,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 8,
                          offset: Offset(2, 3),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // 🏷️ Title
                    const Text(
                      "Booking Confirmed!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 📅 Booking Details
                    Text(
                      "${widget.serviceName}\n${widget.date} • ${widget.time}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),

                    // 🌈 Glowing Back Button
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, _) {
                        return Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 25 * _fadeAnimation.value,
                                spreadRadius: 1.5 * _fadeAnimation.value,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 70,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () => _navigateBackToHome(context),
                            child: const Text(
                              "Back to Home",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
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

  // ✅ Navigate back to Home
  void _navigateBackToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
