import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';
import '../../shared/widgets/custom_button.dart';
import 'providers/product_provider.dart';
import '../cart/providers/cart_provider.dart';
import '../favorites/providers/favorites_provider.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _quantity = 1;

  void _incrementQuantity() {
    if (_product != null && _quantity < _product!.stockQuantity) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

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
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    if (_errorMessage != null || _product == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent, foregroundColor: Colors.black),
        body: Center(child: Text(_errorMessage ?? 'Product not found')),
      );
    }

    final product = _product!;

    return Scaffold(
      backgroundColor: AppColors.primaryGreen.withOpacity(0.05), // Subtle green bg
      body: Stack(
        children: [
          // Background Image Area
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.45,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Center(
                child: Hero(
                  tag: 'product_${product.id}',
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          height: 250,
                          fit: BoxFit.contain,
                        )
                      : Icon(Icons.shopping_bag, size: 100, color: Colors.grey[400]),
                ),
              ),
            ),
          ),

          // Custom App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Consumer<FavoritesProvider>(
                      builder: (context, favoritesProvider, child) {
                        final isFavorite = favoritesProvider.isFavorite(product.id);
                        return CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.black,
                            ),
                            onPressed: () async {
                              await favoritesProvider.toggleFavorite(product.id);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Sheet with Details
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                   BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                   )
                ]
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          "Rs ${product.price.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${product.stockQuantity} ${product.unit} available",
                       style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quantity Selector
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _decrementQuantity,
                                color: _quantity > 1 ? Colors.black : Colors.grey,
                              ),
                              Text(
                                "$_quantity",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _incrementQuantity,
                                color: (_product != null && _quantity < _product!.stockQuantity)
                                    ? AppColors.primaryGreen
                                    : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "Total: ",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "Rs ${(product.price * _quantity).toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    
                    const Text(
                      "Description",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          product.description ?? "No description available for this product.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                         return SizedBox(
                           width: double.infinity,
                           child: ElevatedButton(
                             style: ElevatedButton.styleFrom(
                               backgroundColor: AppColors.primaryGreen,
                               padding: const EdgeInsets.symmetric(vertical: 18),
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(30),
                               ),
                               elevation: 5,
                               shadowColor: AppColors.primaryGreen.withOpacity(0.4),
                             ),
                              onPressed: product.stockQuantity > 0 ? () async {
                                  final success = await cartProvider.addToCart(product, quantity: _quantity);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(content: Text(success ? "Added $_quantity item(s) to Cart" : "Failed to add"), backgroundColor: success ? AppColors.primaryGreen : Colors.red),
                                  );
                              } : null,
                             child: const Text("Add to Cart", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                           ),
                         );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

