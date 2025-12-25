import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/mock_repository.dart';
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
    final user = MockRepository.getUserProfile();

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
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  Text(user.address, style: const TextStyle(color: Colors.grey)),
                  const Divider(),
                  Text(user.phone, style: const TextStyle(color: Colors.grey)),
                ],
              ),
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
