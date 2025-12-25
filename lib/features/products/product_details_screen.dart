import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/product.dart';
import '../../shared/widgets/custom_button.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Image Carousel Mock
              SizedBox(
                height: 300,
                child: PageView(
                  onPageChanged: (index) => setState(() => _currentImage = index),
                  children: [
                    Image.asset(widget.product.imageUrl, fit: BoxFit.contain),
                     // Add more if needed mock
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) { // 4 dots
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImage == index ? AppColors.primaryGreen : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              
              Text(
                widget.product.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                "Rs ${widget.product.price.toStringAsFixed(0)}/-",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
               const SizedBox(height: 32),
               
               // Delivery Info
               const Align(
                 alignment: Alignment.centerLeft,
                 child: Text("Delivery Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               ),
               const SizedBox(height: 8),
               Text(
                 "Delivered between monday and Saturday from 8 Am to 9:00 Pm",
                 style: TextStyle(color: Colors.grey[600], height: 1.5),
               ),
               
               const SizedBox(height: 24),
               
               // Return Policy
               const Align(
                 alignment: Alignment.centerLeft,
                 child: Text("Return Policy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
               ),
               const SizedBox(height: 8),
               Text(
                 "All our foods are double checked before leaving our stores so by any case you found a broken food please contact our hotline immediately.",
                 style: TextStyle(color: Colors.grey[600], height: 1.5),
               ),
               
               const SizedBox(height: 48),
               
               PrimaryButton(
                 text: "Add to cart",
                 onPressed: () {
                    // Start animation or show snackbar
                 },
               )
            ],
          ),
        ),
      ),
    );
  }
}
