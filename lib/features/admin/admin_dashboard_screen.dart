import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../products/providers/product_provider.dart';
import '../categories/providers/category_provider.dart';
import '../riders/providers/rider_provider.dart';
import '../orders/providers/order_provider.dart';
import '../users/providers/admin_user_provider.dart';

/// Admin dashboard landing screen.
/// 
/// Displays overview cards and quick actions for admin management.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data for dashboard metrics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(includeInactive: true);
      context.read<CategoryProvider>().loadCategories();
      context.read<RiderProvider>().loadRiders();
      context.read<OrderProvider>().fetchOrders();
      context.read<AdminUserProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final totalProducts = productProvider.products.length;
    final activeProducts =
        productProvider.products.where((p) => p.isActive).length;
    final inactiveProducts = totalProducts - activeProducts;
    final totalCategories = categoryProvider.categories.length;
    final orderProvider = context.watch<OrderProvider>();
    final pendingOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final totalOrders = orderProvider.orders.length;
    final riderProvider = context.watch<RiderProvider>();
    final totalRiders = riderProvider.riders.length;
    final userProvider = context.watch<AdminUserProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<ProductProvider>().refresh(includeInactive: true),
            context.read<CategoryProvider>().refresh(),
            context.read<RiderProvider>().refresh(),
            context.read<OrderProvider>().fetchOrders(),
            context.read<AdminUserProvider>().fetchUsers(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              const Text(
                'Welcome to Admin Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your grocery store from here',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Overview cards
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricCard(
                    icon: Icons.shopping_bag,
                    title: 'Total Products',
                    value: totalProducts.toString(),
                    color: Colors.blue,
                  ),
                  _buildMetricCard(
                    icon: Icons.check_circle,
                    title: 'Active Products',
                    value: activeProducts.toString(),
                    color: Colors.green,
                  ),
                  _buildMetricCard(
                    icon: Icons.remove_circle,
                    title: 'Inactive Products',
                    value: inactiveProducts.toString(),
                    color: Colors.orange,
                  ),
                  _buildMetricCard(
                    icon: Icons.category,
                    title: 'Categories',
                    value: totalCategories.toString(),
                    color: Colors.purple,
                  ),
                  _buildMetricCard(
                    icon: Icons.receipt_long,
                    title: 'Pending Orders',
                    value: pendingOrders.toString(),
                    color: Colors.orange,
                  ),
                  _buildMetricCard(
                    icon: Icons.shopping_basket,
                    title: 'Total Orders',
                    value: totalOrders.toString(),
                    color: Colors.blueGrey,
                  ),
                  _buildMetricCard(
                    icon: Icons.directions_bike,
                    title: 'Total Riders',
                    value: totalRiders.toString(),
                    color: Colors.teal,
                  ),
                  _buildMetricCard(
                    icon: Icons.people,
                    title: 'Total Users',
                    value: userProvider.users.length.toString(),
                    color: Colors.indigo,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActionButton(
                context,
                icon: Icons.add_shopping_cart,
                title: 'Add New Product',
                subtitle: 'Create a new product',
                onTap: () => context.go('/admin/products/new'),
              ),
              const SizedBox(height: 12),
              _buildQuickActionButton(
                context,
                icon: Icons.add_box,
                title: 'Add New Category',
                subtitle: 'Create a new category',
                onTap: () => context.go('/admin/categories/new'),
              ),
              const SizedBox(height: 12),
              _buildQuickActionButton(
                context,
                icon: Icons.shopping_bag_outlined,
                title: 'Manage Products',
                subtitle: 'View and edit all products',
                onTap: () => context.go('/admin/products'),
              ),
              const SizedBox(height: 12),
              _buildQuickActionButton(
                context,
                icon: Icons.category_outlined,
                title: 'Manage Categories',
                subtitle: 'View and edit all categories',
                onTap: () => context.go('/admin/categories'),
              ),
              const SizedBox(height: 12),
              _buildQuickActionButton(
                context,
                icon: Icons.receipt_long_outlined,
                title: 'Manage Orders',
                subtitle: 'View and process customer orders',
                onTap: () => context.go('/admin/orders'),
              ),
              const SizedBox(height: 12),
              _buildQuickActionButton(
                context,
                icon: Icons.directions_bike_outlined,
                title: 'Manage Riders',
                subtitle: 'View and edit all delivery riders',
                onTap: () => context.go('/admin/riders'),
              ),
              const SizedBox(height: 12),
              _buildQuickActionButton(
                context,
                icon: Icons.people_outline,
                title: 'Manage Users',
                subtitle: 'View and manage customer accounts',
                onTap: () => context.go('/admin/users'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
          child: Icon(icon, color: AppColors.primaryGreen),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
