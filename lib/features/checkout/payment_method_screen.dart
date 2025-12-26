import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/supabase_config.dart';
import '../../shared/widgets/common_widgets.dart';
import '../../shared/widgets/custom_button.dart';
import '../cart/providers/cart_provider.dart';
import '../orders/providers/order_provider.dart';
import '../../domain/repositories/order_repository.dart';
import 'widgets/selection_tile.dart';

class PaymentMethodScreen extends StatefulWidget {
  final Map<String, dynamic>? deliveryDetails;

  const PaymentMethodScreen({super.key, this.deliveryDetails});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int _selectedMethod = 0; // 0: Card, 1: Bank, 2: Paypal
  int _selectedDeliveryMethod = 1; // 0: Pick up, 1: Delivery

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  void _showNoteDialog(BuildContext context) {
    // Get payment method name
    final paymentMethods = ['Card', 'Bank Account', 'Paypal'];
    final paymentMethod = paymentMethods[_selectedMethod];

    // Get delivery address (use from widget.deliveryDetails or default)
    final deliveryAddress = widget.deliveryDetails ?? {
      'address_line1': 'Default Address',
      'city': 'City',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CheckoutNoteModal(
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
      ),
    );
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        "Payment",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 30),
                       const Text(
                        "Payment Method",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      InfoCard(
                        child: Column(
                          children: [
                            SelectionTile(
                              title: "Card",
                              icon: _buildIcon(Icons.credit_card, AppColors.greenIconBg),
                              isSelected: _selectedMethod == 0,
                              onTap: () => setState(() => _selectedMethod = 0),
                            ),
                             const Divider(),
                            SelectionTile(
                              title: "Bank account",
                              icon: _buildIcon(Icons.account_balance, AppColors.pinkIconBg),
                              isSelected: _selectedMethod == 1,
                              onTap: () => setState(() => _selectedMethod = 1),
                            ),
                             const Divider(),
                            SelectionTile(
                              title: "Paypal",
                              icon: _buildIcon(Icons.payment, AppColors.blueIconBg),
                              isSelected: _selectedMethod == 2,
                              onTap: () => setState(() => _selectedMethod = 2),
                            ),
                          ],
                        ),
                      ),
                       const SizedBox(height: 30),
                      const Text(
                        "Delivery Method",
                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                       const SizedBox(height: 16),
                       InfoCard(
                         child: Column(
                           children: [
                             SelectionTile(
                              title: "Pick up",
                              isSelected: _selectedDeliveryMethod == 0,
                              onTap: () => setState(() => _selectedDeliveryMethod = 0),
                            ),
                             const Divider(),
                             SelectionTile(
                              title: "Delivery",
                              isSelected: _selectedDeliveryMethod == 1,
                              onTap: () => setState(() => _selectedDeliveryMethod = 1),
                            ),
                           ]
                         )
                       ),
                       const Spacer(),
                       Consumer<CartProvider>(
                         builder: (context, cartProvider, _) {
                           // Check if pickup method is selected (no delivery fee)
                           final isPickup = _selectedDeliveryMethod == 0;
                           final total = isPickup ? cartProvider.subtotal : cartProvider.total;
                           
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
                                     isPickup ? "Free" : "Rs ${cartProvider.deliveryFee.toStringAsFixed(0)}",
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
                                     "Rs ${total.toStringAsFixed(0)}",
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
                      PrimaryButton(
                        text: "Proceed to Payment",
                        onPressed: () => _showNoteDialog(context),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CheckoutNoteModal extends StatefulWidget {
  final String paymentMethod;
  final Map<String, dynamic> deliveryAddress;

  const CheckoutNoteModal({
    super.key,
    required this.paymentMethod,
    required this.deliveryAddress,
  });

  @override
  State<CheckoutNoteModal> createState() => _CheckoutNoteModalState();
}

class _CheckoutNoteModalState extends State<CheckoutNoteModal> {
  final TextEditingController _notesController = TextEditingController();
  bool _isCreatingOrder = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    setState(() => _isCreatingOrder = true);

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      // Get current user
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get cart items
      final cartItems = cartProvider.cartItems;
      if (cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Convert cart items to order items
      final orderItems = cartItems.map((cartItem) {
        return OrderItemDto(
          productId: cartItem.productId,
          productName: cartItem.name,
          productPrice: cartItem.price,
          quantity: cartItem.quantity,
        );
      }).toList();

      // Create order
      final order = await orderProvider.createOrder(
        items: orderItems,
        deliveryAddress: widget.deliveryAddress,
        paymentMethod: widget.paymentMethod,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (order != null) {
        // Clear cart after successful order
        await cartProvider.clearCart();

        if (mounted) {
          Navigator.pop(context); // Close modal
          context.go('/orders'); // Navigate to orders screen
        }
      } else {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderProvider.error ?? 'Failed to create order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
               const Expanded(
                 child: Text(
                  "Please note",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                               ),
               ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("ORDER NOTES", style: TextStyle(color: Colors.grey, fontSize: 12)),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: "Add special instructions for your order",
              border: UnderlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          const Text("DELIVERY TO ADDRESS", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            widget.deliveryAddress['address_line1'] ?? 'No address specified',
            style: const TextStyle(fontSize: 14),
          ),
           const SizedBox(height: 30),
           Row(
             children: [
               TextButton(
                 onPressed: _isCreatingOrder ? null : () => Navigator.pop(context),
                 child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
               ),
               const Spacer(),
               SizedBox(
                 width: 150,
                 child: _isCreatingOrder
                     ? const Center(child: CircularProgressIndicator())
                     : PrimaryButton(
                         text: "Proceed",
                         onPressed: _handleProceed,
                       ),
               )
             ],
           ),
           const SizedBox(height: 20),
        ],
      ),
    );
  }
}
