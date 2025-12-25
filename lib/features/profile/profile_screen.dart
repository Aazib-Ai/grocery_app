import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/mock_repository.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = MockRepository.getUserProfile();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // Demo: Go to Forgot Password on back click? Or just pop.
             context.push('/forgot_password'); // Demo link for Auth 
          }, 
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/cart'),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My offers",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Personal details",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/edit_profile'),
                    child: Text(
                      "change",
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 15,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              InfoCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(user.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.address,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.phone,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              MenuTile(title: "Orders", onTap: () => context.push('/orders')),
              MenuTile(title: "Favourites", onTap: () => context.push('/favorites')), 
              MenuTile(title: "FAQ", onTap: () => context.push('/faq')),
              MenuTile(title: "Privacy Policy", onTap: () => context.push('/privacy')),
              MenuTile(title: "Help", onTap: () => context.push('/help')),
              const SizedBox(height: 30),
              PrimaryButton(
                text: "Update",
                onPressed: () {
                  context.push('/edit_profile'); 
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
