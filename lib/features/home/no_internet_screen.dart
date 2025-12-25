import 'package:flutter/material.dart';
import '../../shared/widgets/empty_state_widget.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F9),
      appBar: AppBar(
         backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
         leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
         title: const Text("Spicy chickens"), // Mock title from image
         centerTitle: true,
      ),
      body: EmptyStateWidget(
        icon: Icons.wifi,
        isIconCrossed: true, // Custom property we added
        title: "No internet Connection",
        message: "Your internet connection is currently\nnot available please check or try again.",
        buttonText: "Try again",
        onButtonPressed: () {},
      ),
    );
  }
}
