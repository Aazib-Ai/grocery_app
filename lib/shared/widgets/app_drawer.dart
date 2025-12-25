import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.primaryGreen,
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, top: 48, bottom: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Spacing for status bar
             const SizedBox(height: 40),
             
             _buildDrawerItem(context, Icons.person_outline, "Profile", () {
               Navigator.pop(context); // Close drawer
               context.push('/profile');
             }),
             _buildDrawerItem(context, Icons.shopping_cart_outlined, "Orders", () {
               Navigator.pop(context);
               context.push('/orders');
             }),
             _buildDrawerItem(context, Icons.local_offer_outlined, "Offer and promo", () {
                Navigator.pop(context);
                context.push('/favorites'); // using favorites as Offer placeholder
             }),
             _buildDrawerItem(context, Icons.assignment_outlined, "Privacy policy", () {
               Navigator.pop(context);
               context.push('/privacy');
             }),
             _buildDrawerItem(context, Icons.security_outlined, "Security", () {}),
             
             const Spacer(),
             
             TextButton.icon(
               onPressed: () => context.go('/auth'),
               icon: const Text("Sign-out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
               label: const Icon(Icons.arrow_forward, color: Colors.white),
               style: TextButton.styleFrom(
                 foregroundColor: Colors.white,
               ),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}
