import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              "Ali Mart Privacy & Policy",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              "1. Introduction",
              "Welcome to Ali Mart! Your privacy is our top priority. This Privacy Policy explains how we collect, use, and protect your personal information when you use our grocery delivery app.",
            ),
            _buildSection(
              context,
              "2. Information We Collect",
              "• Personal information such as name, phone number, and address.\n• Payment details for order processing (secured through trusted gateways).\n• Location data to provide delivery and live rider tracking services.\n• Device and usage data to improve app performance and features.",
            ),
            _buildSection(
              context,
              "3. How We Use Your Information",
              "• To process and deliver your orders efficiently.\n• To improve user experience and offer personalized deals.\n• To ensure security and prevent fraudulent activities.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
