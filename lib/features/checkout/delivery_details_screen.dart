import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/auth/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/custom_button.dart';
import '../cart/providers/cart_provider.dart';
import '../profile/providers/profile_provider.dart';
import 'widgets/selection_tile.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  const DeliveryDetailsScreen({super.key});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  int _selectedMethod = 0; // 0: Door delivery, 1: Pick up
  int _selectedAddressIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load addresses when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadAddresses();
    });
  }

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
          onPressed: () => context.pop(),
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
                  onPressed: () => context.push('/addresses'),
                  child: const Text(
                    "Change",
                    style: TextStyle(color: AppColors.primaryGreen),
                  ),
                )
              ],
            ),
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, _) {
                if (profileProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final addresses = profileProvider.addresses;
                if (addresses.isEmpty) {
                  return InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No address saved',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Divider(),
                        TextButton.icon(
                          onPressed: () => context.push('/address_form'),
                          icon: const Icon(Icons.add, color: AppColors.primaryGreen),
                          label: const Text(
                            'Add Address',
                            style: TextStyle(color: AppColors.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Use selected address or default
                final selectedAddress = _selectedAddressIndex < addresses.length 
                    ? addresses[_selectedAddressIndex]
                    : addresses.first;

                return InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedAddress.label ?? 'Address',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Divider(),
                      Text(
                        '${selectedAddress.addressLine1}${selectedAddress.addressLine2 != null ? ', ${selectedAddress.addressLine2}' : ''}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Divider(),
                      Text(
                        '${selectedAddress.city}${selectedAddress.postalCode != null ? ' ${selectedAddress.postalCode}' : ''}',
                        style: const TextStyle(color: Colors.grey),
                      ),
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
            Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Subtotal",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          "Rs ${cartProvider.subtotal.toStringAsFixed(0)}",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Delivery Fee",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        Text(
                          _selectedMethod == 0 ? "Rs ${cartProvider.deliveryFee.toStringAsFixed(0)}" : "Free",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Rs ${_selectedMethod == 0 ? cartProvider.total.toStringAsFixed(0) : cartProvider.subtotal.toStringAsFixed(0)}",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, _) {
                final addresses = profileProvider.addresses;
                final hasAddress = addresses.isNotEmpty;
                
                return PrimaryButton(
                  text: "Proceed to payments",
                  onPressed: hasAddress
                      ? () {
                          final selectedAddress = _selectedAddressIndex < addresses.length 
                              ? addresses[_selectedAddressIndex]
                              : addresses.first;
                          
                          // Build delivery details map
                          final deliveryDetails = {
                            'address_line1': selectedAddress.addressLine1,
                            'address_line2': selectedAddress.addressLine2,
                            'city': selectedAddress.city,
                            'postal_code': selectedAddress.postalCode,
                            'latitude': selectedAddress.latitude,
                            'longitude': selectedAddress.longitude,
                            'delivery_method': _selectedMethod == 0 ? 'delivery' : 'pickup',
                          };
                          
                          context.push('/payment', extra: deliveryDetails);
                        }
                      : null,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
