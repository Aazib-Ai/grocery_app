import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/mock_repository.dart';
import '../../shared/widgets/custom_button.dart';
import '../cart/widgets/cart_item_widget.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = MockRepository.getFavoriteItems();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Favourites"), // "Favourites" in image
             const SizedBox(width: 8),
            // Heart emoji/icon from image
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent
              ),
               child: const Text("💚", style: TextStyle(fontSize: 24)), // Emoji as placeholder for the cute heart
            )
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                return Dismissible(
                   key: Key(items[index].id),
                   background: Container(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_border, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1F2937),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                   // Mock functionality for basic list
                   child: CartItemWidget(item: items[index], isCart: false)
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: PrimaryButton(
              text: "Add to Cart",
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
