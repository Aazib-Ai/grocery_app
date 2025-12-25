import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 20, bottom: 20),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none, // Allow image to overflow top
          children: [
            // Card Background
            Container(
              margin: const EdgeInsets.only(top: 40), // Space for image
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rs. ${product.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            // Floating Image
            Positioned(
              top: 0,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200], // Placeholder bg
                  image: product.imageUrl != null
                      ? DecorationImage(
                          image: AssetImage(product.imageUrl!),
                          fit: BoxFit.cover,
                          onError: (_, __) {
                            // Handle image load error gracefully
                          },
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: product.imageUrl == null
                    ? const Icon(Icons.shopping_bag, size: 40, color: Colors.grey)
                    : null,
              ),
            )
          ],
        ),
      ),
    );
  }
}

