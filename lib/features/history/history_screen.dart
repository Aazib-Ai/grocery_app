import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/empty_state_widget.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Show Empty State by default as per requirement/design
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false, // No back button for bottom nav screens
      ),
      body: EmptyStateWidget(
        icon: Icons.calendar_today, // Calendar icon
        title: "No history yet",
        message: "Hit the button down below\nto Create an order.",
        buttonText: "Order Now",
        onButtonPressed: () {
          // Go to Home?
        },
      ),
    );
  }
}
