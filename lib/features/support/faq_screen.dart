import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/mock_repository.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = MockRepository.getFAQs();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Frequently Asked Questions (FAQs)",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 32),
            ...faqs.map((faq) => _buildFAQTile(context, faq["question"]!, faq["answer"]!)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTile(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.green, width: 0.5)), // Green underline as per image
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
             color: Colors.grey,
             fontWeight: FontWeight.w500,
             fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              answer,
              style: const TextStyle(color: Colors.black87),
            ),
          )
        ],
      ),
    );
  }
}
