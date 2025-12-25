import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_button.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Help & Support",
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Need assistance? Our team is here to help! Please describe your issue or question below, and we'll get back to you as soon as possible.",
                textAlign: TextAlign.start, // Left aligned in design?
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              // Full Name
              const Text("Full Name", style: TextStyle(fontWeight: FontWeight.bold)),
              const TextField(
                decoration: InputDecoration(
                   hintText: "ali raza",
                   border: InputBorder.none,
                   contentPadding: EdgeInsets.zero
                ),
              ),
              const Divider(color: Colors.black),
              const SizedBox(height: 16),
        
              // Email
              const Text("Email address", style: TextStyle(fontWeight: FontWeight.bold)),
              const TextField(
                decoration: InputDecoration(
                   hintText: "aliirtiza@gmail.com",
                   border: InputBorder.none,
                   contentPadding: EdgeInsets.zero
                ),
              ),
              const Divider(color: Colors.black),
              const SizedBox(height: 16),
              
              // Message
              const Text("Message", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 150,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryGreen),
                  color: Colors.white,
                ),
                child: const TextField(
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: "help!",
                    border: InputBorder.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              PrimaryButton(
                text: "Submit Request",
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("Request submitted!"))
                   );
                },
              ),
              const SizedBox(height: 24),
              
              const Center(
                child: Column(
                  children: [
                    Text("For urgent issues, contact us directly:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 4),
                    Text("support@alimart.pk", style: TextStyle(fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text("+92 300 1234567", style: TextStyle(fontWeight: FontWeight.w500)),
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
