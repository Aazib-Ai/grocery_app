import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/promo_banner.dart';
import '../products/providers/product_provider.dart';
import '../categories/providers/category_provider.dart';
import '../cart/providers/cart_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    Image(
                      image: const AssetImage('assets/images/logo_1.png'),
                      // Fallback or use Text if no logo
                      height: 30,
                      errorBuilder: (_, __, ___) => const Text(
                        "GROCERY",
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: AppColors.primaryGreen),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          return Badge(
                            isLabelVisible: cart.itemCount > 0,
                            label: Text('${cart.itemCount}'),
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            child: IconButton(
                              icon: const Icon(Icons.shopping_cart_outlined,
                                  size: 20, color: Colors.black),
                              onPressed: () => context.push('/cart'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar & Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Find Your Daily\nGrocery",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            height: 1.2,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 24),
                    SearchField(
                      onTap: () => context.push('/search'),
                    ),
                  ],
                ),
              ),
            ),

            // Categories Section
            SliverToBoxAdapter(
              child: Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  if (categoryProvider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: LinearProgressIndicator(color: AppColors.primaryGreen),
                    );
                  }

                  final categories = categoryProvider.categories.take(8).toList(); // Show top 8
                  final allProducts = context.watch<ProductProvider>().products;

                  if (categories.isEmpty) return const SizedBox.shrink();

                  return SizedBox(
                    height: 200, // Fixed height for grid
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75, // Adjust for Icon + Text
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final productCount = allProducts.where((p) => p.categoryId == category.id).length;
                        
                        return GestureDetector(
                          onTap: () {
                            context.push(
                              '/products',
                              extra: {
                                'categoryId': category.id,
                                'categoryName': category.name,
                              },
                            );
                          },
                          child: Column(
                            children: [
                              Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6), // Light grey bg
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: category.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.network(
                                          category.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.category, color: AppColors.primaryGreen),
                                        ),
                                      )
                                    : const Icon(Icons.category, color: AppColors.primaryGreen),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${category.name} ($productCount)',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Banner Section
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                child: PromoBanner(),
              ),
            ),

            // Popular Deals Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Popular Deals",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "See all",
                       style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Products Section
             SliverPadding(
               padding: const EdgeInsets.symmetric(horizontal: 24.0),
               sliver: Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return SliverToBoxAdapter(
                      child: SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          itemBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: SkeletonLoader(width: 150, height: 200, borderRadius: 20),
                          ),
                        ),
                      ),
                    );
                  }

                  final products = provider.products;

                  if (products.isEmpty) {
                    return const SliverToBoxAdapter(child: Text("No products found"));
                  }

                   return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7, // Adjust for card height
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return ProductCard(
                          product: products[index],
                          onTap: () => context.push('/product/${products[index].id}'),
                        );
                      },
                      childCount: products.length,
                    ),
                  );
                },
              ),
             ),
             
             const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }
}
