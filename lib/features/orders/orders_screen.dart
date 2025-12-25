import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/empty_state_widget.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: EmptyStateWidget(
        icon: Icons.shopping_cart_outlined,
        title: "No order yet",
        message: "Hit the button down below\nto Create an order.",
        buttonText: "Order Now",
        onButtonPressed: () {
          // Navigate to Home or specific tab
        },
      ),
    );
  }
}
