import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/cart_item.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final bool isCart; // true for Cart (counter), false for Favorites (Add to cart)
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onAddToCart;

  const CartItemWidget({
    super.key,
    required this.item,
    this.isCart = true,
    this.onIncrement,
    this.onDecrement,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image (Placeholder)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              // image: DecorationImage(image: NetworkImage(item.imageUrl)),
            ),
            child: const Icon(Icons.fastfood, color: Colors.orange), // Placeholder icon
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  "#${item.price.toStringAsFixed(0)}", // Assuming currency symbol # from image
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          if (isCart) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: onDecrement,
                    child: const Icon(Icons.remove, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${item.quantity}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onIncrement,
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ],
              ),
            )
          ] else ...[
             // Favorite mode: Add to Cart button logic could go here, or just a simple add icon
             // The design shows the counter even in favorites??
             // Wait, looking at image 2 (Favorites), it DOES show the counter same as Cart.
             // And separate big "Add to Cart" button at bottom.
             // But wait, the design for Favorites items (Image 2) looks Identical to Cart items (Image 1)
             // except there's no Swipe hint explicitly shown but usually implies swipe to delete.
             // Actually, looking closely at Image 2 (Favorites), the items HAVE counters: "- 1 +".
             // This is unusual for a favorites list (usually just Move to Cart).
             // But I will follow the visual design: It has counters.
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "1", // Hardcoded for view
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.add, color: Colors.white, size: 16),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }
}
