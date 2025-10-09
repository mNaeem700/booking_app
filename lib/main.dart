import 'package:booking_app/screens/booking/booking_screen.dart';
import 'package:booking_app/screens/booking/booking_success_screen.dart';
import 'package:booking_app/screens/booking/salon_detail_screen.dart';
import 'package:booking_app/screens/home/homeScreen.dart';
import 'package:booking_app/screens/booking/my_bookings_screen.dart';
import 'package:booking_app/screens/auth/signin.dart';
import 'package:booking_app/screens/auth/signup.dart';
import 'package:booking_app/screens/widgets/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("Firebase initialized");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Salon Booking App',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.textDark, fontSize: 16),
          titleLarge: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: AppColors.secondary,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
