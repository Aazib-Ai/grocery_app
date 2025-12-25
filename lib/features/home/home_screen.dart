import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/product.dart';
import '../../data/repositories/mock_repository.dart';
import '../../shared/widgets/product_card.dart';

import '../../shared/widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final products = MockRepository.getProducts();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Key for Drawer

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
                 
                // Tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primaryGreen,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primaryGreen,
                  indicatorWeight: 3, 
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  tabs: const [
                    Tab(text: "Foods"),
                    Tab(text: "Drinks"),
                    Tab(text: "Snacks"),
                    Tab(text: "Sauces"),
                  ],
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
                SizedBox(
                  height: 320, 
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(top: 10, bottom: 20, right: 24),
                    itemCount: products.length > 5 ? 5 : products.length, // Show top 5 horizontally
                    itemBuilder: (context, index) {
                       return ProductCard(
                         product: products[index],
                         onTap: () => context.push('/product/${products[index].id}'),
                       );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(right: 24.0),
                  child: Text("More Groceries", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                
                // Vertical Grid/List for "Scroll down for seeing more"
                // Using a non-scrolling ListView (shrinkWrap: true) inside SingleChildScrollView
                ListView.builder(
                  padding: const EdgeInsets.only(right: 24.0),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    // Using a horizontal card look for the vertical list? Or just reuse ProductCard in a grid?
                    // Let's use a simple ListTile variant or just the same ProductCard but perhaps wrapped differently?
                    // User said "scroll down for seeing more products".
                    // Let's make a simple vertical list item or a standard grid. 
                    // To be safe and quick, let's use a Wrap or GridView.
                    // Actually, a ListView with a custom list item is often cleaner for "more".
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(
                           backgroundImage: AssetImage(product.imageUrl),
                           backgroundColor: Colors.transparent,
                        ),
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Rs. ${product.price}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart, color: AppColors.primaryGreen),
                          onPressed: () {
                             // Add to cart logic or snackbar
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to cart")));
                          },
                        ),
                        onTap: () => context.push('/product/${product.id}'),
                      ),
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
