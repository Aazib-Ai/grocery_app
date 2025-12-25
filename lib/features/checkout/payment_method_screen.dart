import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/custom_button.dart';
import 'widgets/selection_tile.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  int _selectedMethod = 0; // 0: Card, 1: Bank, 2: Paypal

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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const CheckoutNoteModal(),
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
          onPressed: () {},
        ),
      ),
      body: Padding(
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
              "Payment Method", // Small typo in design "Mathod" fixed here
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
              "Delivery method.",
               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
             const SizedBox(height: 16),
             InfoCard(
               child: Column(
                 children: [
                   SelectionTile(
                    title: "Pick up",
                    isSelected: false,
                    onTap: () {},
                  ),
                   const Divider(),
                   SelectionTile(
                    title: "Delivery",
                    isSelected: true,
                    onTap: () {},
                  ),
                 ]
               )
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
              text: "Confirm", // Matches design
              onPressed: () => _showNoteDialog(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class CheckoutNoteModal extends StatelessWidget {
  const CheckoutNoteModal({super.key});

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
              IconButton(onPressed: (){}, icon: const Icon(Icons.close)), // Not in design but good UX? Actually design design has "Please note"
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
          const TextField(
            decoration: InputDecoration(
              hintText: "plz check packet seal",
              border: UnderlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text("DELIVERY TO ADDRESS", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          const Text("Gali k andar masjid k samny wala ghar", style: TextStyle(fontSize: 14)),
           const SizedBox(height: 30),
           Row(
             children: [
               TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
               const Spacer(),
               SizedBox(
                 width: 150,
                 child: PrimaryButton(text: "Proceed", onPressed: (){
                   context.go('/tracking');
                 }),
               )
             ],
           ),
           const SizedBox(height: 20),
        ],
      ),
    );
  }
}
