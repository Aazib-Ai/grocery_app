import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/app_drawer.dart';
import '../products/providers/product_provider.dart';
import '../categories/providers/category_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load products and categories when home screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign key
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(), // Add Drawer
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(), // Open drawer
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.grey),
            onPressed: () => context.push('/cart'),
          )
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, bottom: 24.0), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20), // Top spacing
                Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Text(
                    "Delicious\nfood for you",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 34,
                    ),
                  ),
                ),
                 const SizedBox(height: 24),
                // Search Bar
                  Padding(
                     padding: const EdgeInsets.only(right: 24.0),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16),
                       decoration: BoxDecoration(
                         color: const Color(0xFFEFEEEE),
                         borderRadius: BorderRadius.circular(30),
                       ),
                       child: TextField(
                         readOnly: true, // Make it act like a button
                         onTap: () {
                            context.push('/search');
                         },
                         decoration: const InputDecoration(
                           icon: Icon(Icons.search, color: Colors.black),
                           hintText: "Search",
                           border: InputBorder.none,
                         ),
                       ),
                     ),
                  ),
                 const SizedBox(height: 30),
                 
                // Tabs - Dynamic from Categories
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    if (categoryProvider.isLoading) {
                      return const SizedBox(
                        height: 40,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (categoryProvider.error != null || categoryProvider.categories.isEmpty) {
                      // Fallback to default tabs if categories fail to load
                      return TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: AppColors.primaryGreen,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.primaryGreen,
                        indicatorWeight: 3,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        tabs: const [
                          Tab(text: "All"),
                          Tab(text: "Popular"),
                          Tab(text: "New"),
                          Tab(text: "Sale"),
                        ],
                      );
                    }

                    // Rebuild TabController with correct length
                    if (_tabController.length != categoryProvider.categories.length) {
                      _tabController.dispose();
                      _tabController = TabController(
                        length: categoryProvider.categories.length,
                        vsync: this,
                      );
                    }

                    return TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AppColors.primaryGreen,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: AppColors.primaryGreen,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      tabs: categoryProvider.categories
                          .map((category) => Tab(text: category.name))
                          .toList(),
                    );
                  },
                ),
                 const SizedBox(height: 20),
                 
                 Padding(
                   padding: const EdgeInsets.only(right: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => context.push('/products'),
                          child: const Text("see more", style: TextStyle(color: AppColors.primaryGreen)),
                        ),
                      ],
                    ),
                 ),

                // Horizontal List
                Consumer<ProductProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const SizedBox(
                        height: 320,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final products = provider.products.take(5).toList();

                    if (products.isEmpty) {
                      return const SizedBox(
                        height: 320,
                        child: Center(child: Text('No products available')),
                      );
                    }

                    return SizedBox(
                      height: 320,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(top: 10, bottom: 20, right: 24),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: products[index],
                            onTap: () => context.push('/product/${products[index].id}'),
                          );
                        },
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(right: 24.0),
                  child: Text("More Groceries", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                
                // Vertical List for "More Groceries"
                Consumer<ProductProvider>(
                  builder: (context, provider, child) {
                    final products = provider.products;

                    if (products.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(right: 24.0),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: product.imageUrl != null
                                ? CircleAvatar(
                                    backgroundImage: AssetImage(product.imageUrl!),
                                    backgroundColor: Colors.transparent,
                                    onBackgroundImageError: (_, __) {},
                                    child: product.imageUrl == null
                                        ? const Icon(Icons.shopping_bag)
                                        : null,
                                  )
                                : CircleAvatar(
                                    backgroundColor: Colors.grey[200],
                                    child: const Icon(
                                      Icons.shopping_bag,
                                      color: Colors.grey,
                                    ),
                                  ),
                            title: Text(
                              product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("Rs. ${product.price.toStringAsFixed(0)}"),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                color: AppColors.primaryGreen,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Added to cart")),
                                );
                              },
                            ),
                            onTap: () => context.push('/product/${product.id}'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
    );
  }
}
