import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';


class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        "question": "How can I place an order on Ali Mart?",
        "answer": "You can place an order by selecting items and proceeding to checkout."
      },
      {
        "question": "How long does delivery take?",
        "answer": "Delivery usually takes 30-45 minutes depending on your location."
      },
      {
        "question": "Can I cancel or modify my order?",
        "answer": "Yes, you can cancel before the rider picks up your order."
      },
       {
        "question": "How can I track my order?",
        "answer": "You can track your order in real-time from the Tracking screen."
      },
       {
        "question": "How do I contact customer support?",
        "answer": "You use the Help & Support form to contact us directly."
      },
    ];

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
