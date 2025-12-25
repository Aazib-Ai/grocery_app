import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_button.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // As per image (or AppColors.background)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Center(
                child: Text(
                  "Forgot Password",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Enter your registered email address below and we'll send you instructions to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              const Text(
                "Email address",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const TextField(
                decoration: InputDecoration(
                  hintText: "aliirtiza@gmail.com", // Placeholder
                  // border: UnderlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              // Underline usually handled by default TextField, but added the green line manually if needed to match design 100%. 
              // Design shows green underline.
              Container(height: 1, color: AppColors.primaryGreen),
              
              const SizedBox(height: 32),
              PrimaryButton(
                text: "Send Reset Link",
                onPressed: () {
                   // Mock action
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("Reset link sent!"))
                   );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Remember your password? ", style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context), // Back to "Login" (which we might not have, so back)
                      child: const Text(
                        "Login here",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
