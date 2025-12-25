import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/mock_repository.dart';
import '../../shared/widgets/custom_button.dart';
import '../checkout/widgets/selection_tile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String _selectedPayment = 'Card';
  final user = MockRepository.getUserProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F9),
      appBar: AppBar(
        title: const Text("My Proile"), // "Proile" typo in design, likely should be Profile
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(user.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 8),
                         Text(user.address, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text("Payment Mathod", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), // "Mathod" typo in design
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _PaymentTile(
                    title: "Card",
                    icon: Icons.credit_card,
                    color: const Color(0xFF4ADE80), // Green
                    isSelected: _selectedPayment == 'Card',
                    onTap: () => setState(() => _selectedPayment = 'Card'),
                  ),
                  _PaymentTile(
                    title: "Bank account",
                    icon: Icons.account_balance,
                    color: const Color(0xFFE84288), // Pink
                    isSelected: _selectedPayment == 'Bank account',
                    onTap: () => setState(() => _selectedPayment = 'Bank account'),
                  ),
                  _PaymentTile(
                    title: "Paypal",
                    icon: Icons.payment, // Or paypal icon if available, normally needs FontAwesome or custom asset. Using generic for now.
                    color: const Color(0xFF2563EB), // Blue
                    isSelected: _selectedPayment == 'Paypal',
                    onTap: () => setState(() => _selectedPayment = 'Paypal'),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 48),
            PrimaryButton(
              text: "Update",
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for Edit Profile specific Payment Tile to avoid breaking shared widget
class _PaymentTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : Colors.grey,
                  width: isSelected ? 2 : 1,
                ),
              ),
              width: 20, height: 20,
              child: isSelected ? const Center(child: CircleAvatar(radius: 4, backgroundColor: AppColors.primaryGreen)) : null,
            ),
            const SizedBox(width: 16),
             Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
