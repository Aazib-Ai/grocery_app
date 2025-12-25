import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/mock_repository.dart';
import '../../shared/widgets/custom_button.dart';
import 'widgets/cart_item_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final items = MockRepository.getCartItems();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swipe, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                "swipe on an item to delete",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Dismissible(
                  key: Key(item.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    color: Colors.transparent, // Background shows icons
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen, // Heart
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_border, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1F2937), // Trash/Black
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      items.removeAt(index);
                    });
                  },
                  child: CartItemWidget(
                    item: item,
                    onIncrement: () => setState(() => item.quantity++),
                    onDecrement: () => setState(() {
                      if (item.quantity > 1) item.quantity--;
                    }),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: PrimaryButton(
              text: "Complete order",
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
