import 'package:booking_app/screens/custom_text_field.dart';
import 'package:booking_app/screens/signin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  /// 🔒 Check if password is strong
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

    // ✅ Validation before sending to Firebase
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
      // 1. Create user in Firebase Auth
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCred.user!.uid;

      // 2. Save extra info in Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": name,
        "email": email,
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signup successful!")));

      // TODO: Navigate to Home Screen
    } on FirebaseAuthException catch (e) {
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
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Unexpected error")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          // Container(
          //   decoration: const BoxDecoration(
          //     image: DecorationImage(
          //       image: AssetImage("assets/images/bg.jpg"), // your background
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          // ),
          Container(color: Colors.black.withOpacity(0.5)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Create Account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  CustomTextField(
                    controller: nameController,
                    hintText: "Full Name",
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: emailController,
                    hintText: "Email",
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: passwordController,
                    hintText: "Password",
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: confirmPasswordController,
                    hintText: "Re-enter Password",
                    isPassword: true,
                  ),
                  const SizedBox(height: 24),

                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _signup,
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SigninScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Already have an account? Sign in",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
