import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/custom_error_widget.dart';
import 'providers/product_provider.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({super.key});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  @override
  void initState() {
    super.initState();
    // Load products when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Products"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: SkeletonLoader(width: double.infinity, height: double.infinity, borderRadius: 12),
                    ),
                    const SizedBox(height: 8),
                    const SkeletonLoader(width: 100, height: 16),
                    const SizedBox(height: 4),
                    const SkeletonLoader(width: 60, height: 16),
                  ],
                );
              },
            );
          }

          if (provider.errorMessage != null) {
            return CustomErrorWidget(
              message: provider.errorMessage!,
              onRetry: () => provider.refresh(),
            );
          }

          final products = provider.products;

          if (products.isEmpty) {
            return const Center(
              child: Text('No products available'),
            );
          }

          return Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Found ${products.length} results",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: products[index],
                      onTap: () {
                        context.push('/product/${products[index].id}');
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



