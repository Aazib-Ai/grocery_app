import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../products/providers/product_provider.dart';
import '../categories/providers/category_provider.dart';
import '../riders/providers/rider_provider.dart';
import '../orders/providers/order_provider.dart';
import 'users/providers/admin_user_provider.dart';
import 'analytics/providers/analytics_provider.dart';
import 'analytics/widgets/metrics_card.dart';
import 'analytics/widgets/sales_chart.dart';
import 'analytics/widgets/top_products_list.dart';

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
      context.read<AnalyticsProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analyticsProvider, child) {
        final metrics = analyticsProvider.metrics;

        if (analyticsProvider.isLoading && metrics == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<ProductProvider>().refresh(includeInactive: true),
              context.read<CategoryProvider>().refresh(),
              context.read<RiderProvider>().refresh(),
              context.read<OrderProvider>().fetchOrders(),
              context.read<AdminUserProvider>().fetchUsers(),
              context.read<AnalyticsProvider>().refresh(),
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
                if (metrics != null)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      MetricsCard(
                        icon: Icons.attach_money,
                        title: 'Total Revenue',
                        value: '\$${metrics.totalRevenue.toStringAsFixed(2)}',
                        color: Colors.green,
                      ),
                      MetricsCard(
                        icon: Icons.shopping_bag,
                        title: 'Total Products',
                        value: metrics.totalProducts.toString(),
                        color: Colors.blue,
                      ),
                      MetricsCard(
                        icon: Icons.shopping_basket,
                        title: 'Total Orders',
                        value: metrics.totalOrders.toString(),
                        color: Colors.orange,
                      ),
                      MetricsCard(
                        icon: Icons.people,
                        title: 'Total Users',
                        value: metrics.totalUsers.toString(),
                        color: Colors.purple,
                      ),
                    ],
                  ),
              
              const SizedBox(height: 24),
              
              // Sales Chart
              if (analyticsProvider.salesData.isNotEmpty) ...[
                SalesChart(salesData: analyticsProvider.salesData),
                const SizedBox(height: 24),
              ],

              // Top Products
              if (analyticsProvider.topProducts.isNotEmpty) ...[
                TopProductsList(products: analyticsProvider.topProducts),
                const SizedBox(height: 24),
              ],
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
                icon: Icons.map,
                title: 'Active Deliveries',
                subtitle: 'Track active deliveries on map',
                onTap: () => context.go('/admin/deliveries'),
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
        );
      },
    );
  }

  /* Removed old _buildMetricCard helper as we use MetricsCard widget now */

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
