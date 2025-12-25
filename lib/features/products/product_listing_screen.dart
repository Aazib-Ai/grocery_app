import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/mock_repository.dart';
import '../../shared/widgets/product_card.dart';

class ProductListingScreen extends StatelessWidget {
  const ProductListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate more items for the grid by duplicating mock data
    final baseProducts = MockRepository.getProducts();
    final products = [...baseProducts, ...baseProducts]; // Duplicate to show grid

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Lays"), // Mock Title
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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Found 6 results",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7, // Adjust for card height
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: products[index],
                  onTap: () {
                     // Navigate to details (To be implemented next)
                     // context.push('/product/${products[index].id});
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
