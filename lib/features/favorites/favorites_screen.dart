import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../cart/providers/cart_provider.dart';
import './providers/favorites_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Load favorites when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Favourites"),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: const Text("💚", style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false, // No back button for bottom nav screens
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          // Loading state
          if (favoritesProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            );
          }

          // Error state
          if (favoritesProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load favorites',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    favoritesProvider.errorMessage ?? '',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Retry',
                    onPressed: () => favoritesProvider.refresh(),
                  ),
                ],
              ),
            );
          }

          final favorites = favoritesProvider.favorites;

          // Empty state
          if (favorites.isEmpty) {
            return Center(
              child: EmptyStateWidget(
                icon: Icons.favorite_border,
                title: 'No favorites yet',
                message: 'Start adding products to your favorites!',
                buttonText: 'Browse Products',
                onButtonPressed: () => context.go('/home'),
              ),
            );
          }

          // List of favorites
          return Column(
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
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final product = favorites[index];
                    
                    return Dismissible(
                      key: Key(product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1F2937),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (direction) {
                        favoritesProvider.removeFavorite(product.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} removed from favorites'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: _FavoriteItemCard(product: product),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    return PrimaryButton(
                      text: "Add All to Cart",
                      onPressed: () async {
                        // Add all favorites to cart
                        var successCount = 0;
                        for (final product in favorites) {
                          final success = await cartProvider.addToCart(product);
                          if (success) successCount++;
                        }

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              successCount == favorites.length
                                  ? 'All favorites added to cart!'
                                  : '$successCount of ${favorites.length} items added to cart',
                            ),
                            backgroundColor: successCount == favorites.length
                                ? AppColors.primaryGreen
                                : Colors.orange,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FavoriteItemCard extends StatelessWidget {
  final dynamic product;

  const _FavoriteItemCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.shopping_bag, size: 40);
                      },
                    ),
                  )
                : const Icon(Icons.shopping_bag, size: 40),
          ),
          const SizedBox(width: 12),
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (product.description != null)
                  Text(
                    product.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        return IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          color: AppColors.primaryGreen,
                          onPressed: () async {
                            final success = await cartProvider.addToCart(product);
                            if (!context.mounted) return;
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Added to cart'
                                      : 'Failed to add to cart',
                                ),
                                duration: const Duration(seconds: 1),
                                backgroundColor: success
                                    ? AppColors.primaryGreen
                                    : Colors.red,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
