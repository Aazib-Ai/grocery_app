import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';

/// Admin navigation wrapper with side drawer navigation.
/// 
/// Provides navigation to admin dashboard sections:
/// - Dashboard (overview)
/// - Products management
/// - Categories management
class AdminWrapper extends StatelessWidget {
  final Widget child;

  const AdminWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.currentUser?.userMetadata?['name'] ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          // Dashboard/Home button - quick access back to main admin page
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () => context.go('/admin'),
            tooltip: 'Dashboard',
          ),
          // Back to customer store
          IconButton(
            icon: const Icon(Icons.storefront),
            onPressed: () => context.go('/home'),
            tooltip: 'Back to Store',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                context.go('/auth');
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 35,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Administrator',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              route: '/admin',
            ),
            const Divider(),
            _buildDrawerItem(
              context,
              icon: Icons.shopping_bag,
              title: 'Products',
              route: '/admin/products',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.category,
              title: 'Categories',
              route: '/admin/categories',
            ),
            const Divider(),
            _buildDrawerItem(
              context,
              icon: Icons.receipt_long,
              title: 'Orders',
              route: '/admin/orders',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.delivery_dining,
              title: 'Riders',
              route: '/admin/riders',
            ),
            _buildDrawerItem(
              context,
              icon: Icons.analytics,
              title: 'Analytics',
              route: '/admin/analytics',
              enabled: false,
            ),
            const Divider(),
            _buildDrawerItem(
              context,
              icon: Icons.people,
              title: 'Users',
              route: '/admin/users',
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Back to Store'),
              onTap: () => context.go('/home'),
            ),
          ],
        ),
      ),
      body: child,
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool enabled = true,
  }) {
    final currentRoute = GoRouterState.of(context).uri.toString();
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppColors.primaryGreen
            : (enabled ? Colors.black87 : Colors.grey),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? AppColors.primaryGreen
              : (enabled ? Colors.black87 : Colors.grey),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primaryGreen.withOpacity(0.1),
      enabled: enabled,
      onTap: enabled
          ? () {
              context.go(route);
              Navigator.of(context).pop(); // Close drawer
            }
          : null,
    );
  }
}
