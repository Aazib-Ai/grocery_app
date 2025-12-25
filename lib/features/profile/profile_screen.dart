import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/custom_button.dart';
import 'providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load user profile and addresses when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProfileProvider>();
      provider.loadUserProfile();
      provider.loadAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button for bottom nav screens
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/cart'),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && profileProvider.userProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileProvider.error != null && profileProvider.userProfile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading profile',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      profileProvider.loadUserProfile();
                      profileProvider.loadAddresses();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final user = profileProvider.userProfile;
          if (user == null) {
            return const Center(child: Text('No user profile available'));
          }

          final defaultAddress = profileProvider.addresses.isEmpty
              ? null
              : profileProvider.addresses.firstWhere(
                  (addr) => addr.isDefault,
                  orElse: () => profileProvider.addresses.first,
                );

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Profile",
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
                            image: user.avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(user.avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: user.avatarUrl == null
                              ? const Icon(Icons.person, size: 30, color: Colors.grey)
                              : null,
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
                              if (defaultAddress != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  defaultAddress.formattedAddress,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (user.phone != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  user.phone!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  MenuTile(title: "Orders", onTap: () => context.push('/orders')),
                  MenuTile(title: "Addresses", onTap: () => context.push('/addresses')),
                  MenuTile(title: "Favourites", onTap: () => context.push('/favorites')),
                  MenuTile(title: "FAQ", onTap: () => context.push('/faq')),
                  MenuTile(title: "Privacy Policy", onTap: () => context.push('/privacy')),
                  MenuTile(title: "Help", onTap: () => context.push('/help')),
                  const SizedBox(height: 30),
                  PrimaryButton(
                    text: "Update Profile",
                    onPressed: () {
                      context.push('/edit_profile');
                    },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
