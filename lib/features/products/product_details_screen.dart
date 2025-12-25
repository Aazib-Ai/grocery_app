import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';
import '../../shared/widgets/custom_button.dart';
import 'providers/product_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImage = 0;
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final product = await context.read<ProductProvider>().getProductById(widget.productId);

    setState(() {
      _product = product;
      _isLoading = false;
      if (product == null) {
        _errorMessage = 'Product not found';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _product == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Product not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product!;

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
            onPressed: () {
              // TODO: Add to favorites functionality
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Carousel
              Center(
                child: SizedBox(
                  height: 300,
                  child: product.imageUrl != null
                      ? Image.asset(
                          product.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.shopping_bag,
                                size: 100,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.shopping_bag,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Dots Indicator (keeping for visual consistency)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(1, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImage == index
                          ? AppColors.primaryGreen
                          : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Product Name
              Text(
                product.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),

              // Price
              Center(
                child: Text(
                  "Rs ${product.price.toStringAsFixed(0)}/${product.unit}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stock Info
              if (product.stockQuantity > 0)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${product.stockQuantity} ${product.unit}s in stock',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Out of stock',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // Description
              if (product.description != null) ...[
                const Text(
                  "Description",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description!,
                  style: TextStyle(color: Colors.grey[600], height: 1.5),
                ),
                const SizedBox(height: 24),
              ],

              // Delivery Info
              const Text(
                "Delivery Info",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "Delivered between monday and Saturday from 8 Am to 9:00 Pm",
                style: TextStyle(color: Colors.grey[600], height: 1.5),
              ),

              const SizedBox(height: 24),

              // Return Policy
              const Text(
                "Return Policy",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "All our foods are double checked before leaving our stores so by any case you found a broken food please contact our hotline immediately.",
                style: TextStyle(color: Colors.grey[600], height: 1.5),
              ),

              const SizedBox(height: 48),

              PrimaryButton(
                text: product.stockQuantity > 0 ? "Add to cart" : "Out of stock",
                onPressed: product.stockQuantity > 0
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    : null,
              )
            ],
          ),
        ),
      ),
    );
  }
}


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
