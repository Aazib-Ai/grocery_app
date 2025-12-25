import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/auth/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/custom_button.dart';
import 'widgets/selection_tile.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  const DeliveryDetailsScreen({super.key});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  int _selectedMethod = 0; // 0: Door delivery, 1: Pick up

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              "Delivery",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Address details",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                 TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Change",
                    style: TextStyle(color: AppColors.primaryGreen),
                  ),
                )
              ],
            ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.currentUser;
              // Fallback data if user attributes are missing (Supabase user metadata might be used for name/phone)
              final name = user?.userMetadata?['name'] ?? 'Guest';
              final phone = user?.phone ?? 'No phone'; 
              
              // Address would realistically come from a separate table or metadata. 
              // For now, we'll use a placeholder or check metadata.
              final address = user?.userMetadata?['address'] ?? 'No address set';

              return InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(),
                    Text(address, style: const TextStyle(color: Colors.grey)),
                    const Divider(),
                    Text(phone, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            },
          ),
            const SizedBox(height: 30),
            const Text(
              "Delivery method.",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            InfoCard(
              child: Column(
                children: [
                  SelectionTile(
                    title: "Door delivery",
                    isSelected: _selectedMethod == 0,
                    onTap: () => setState(() => _selectedMethod = 0),
                  ),
                  const Divider(),
                  SelectionTile(
                    title: "Pick up",
                    isSelected: _selectedMethod == 1,
                    onTap: () => setState(() => _selectedMethod = 1),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "23,000",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: "Proceed to payments",
              onPressed: () {
                context.go('/payment');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
