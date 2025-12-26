import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/image_storage_service.dart';
import '../../../core/config/supabase_config.dart';
import '../../products/providers/product_provider.dart';
import '../../categories/providers/category_provider.dart';
import '../../../domain/entities/product.dart';

/// Admin product form screen for creating and editing products.
/// 
/// Supports image upload with R2 storage integration.
class AdminProductFormScreen extends StatefulWidget {
  final String? productId;

  const AdminProductFormScreen({super.key, this.productId});

  bool get isEditMode => productId != null;

  @override
  State<AdminProductFormScreen> createState() =>
      _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _unitController = TextEditingController(text: 'piece');

  late final ImageStorageService _imageStorage;
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedCategoryId;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isSaving = false;
  File? _selectedImage;
  String? _currentImageUrl;
  Product? _product;

  @override
  void initState() {
    super.initState();
    // Use R2ImageStorageService for real image uploads
    _imageStorage = R2ImageStorageService();

    if (widget.isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProduct();
      });
    }

    // Load categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
    });

    final productProvider = context.read<ProductProvider>();
    final product = await productProvider.getProductById(widget.productId!);

    if (product != null) {
      setState(() {
        _product = product;
        _nameController.text = product.name;
        _descriptionController.text = product.description ?? '';
        _priceController.text = product.price.toString();
        _stockController.text = product.stockQuantity.toString();
        _unitController.text = product.unit;
        _selectedCategoryId = product.categoryId;
        _isActive = product.isActive;
        _currentImageUrl = product.imageUrl;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found')),
        );
        context.go('/admin/products');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) {
      return _currentImageUrl;
    }

    try {
      final productId = widget.productId ?? 'new';
      final imageUrl = await _imageStorage.uploadProductImage(
        _selectedImage!,
        productId,
      );

      // If updating and old image exists, delete it
      if (widget.isEditMode && _currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
        try {
          await _imageStorage.deleteImage(_currentImageUrl!);
        } catch (e) {
          // Log but don't fail - image might not exist
          debugPrint('Failed to delete old image: $e');
        }
      }

      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload image if selected
      final imageUrl = await _uploadImage();

      final productProvider = context.read<ProductProvider>();

      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text);
      final stock = int.parse(_stockController.text);
      final unit = _unitController.text.trim();

      if (widget.isEditMode) {
        // Update existing product
        final updatedProduct = await productProvider.updateProduct(
          widget.productId!,
          name: name,
          description: description,
          price: price,
          categoryId: _selectedCategoryId,
          imageUrl: imageUrl,
          stockQuantity: stock,
          unit: unit,
          isActive: _isActive,
        );

        if (mounted) {
          if (updatedProduct != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/admin/products');
          } else {
            throw Exception('Failed to update product');
          }
        }
      } else {
        // Create new product
        final newProduct = await productProvider.createProduct(
          name: name,
          description: description,
          price: price,
          categoryId: _selectedCategoryId,
          imageUrl: imageUrl ?? '',
          stockQuantity: stock,
          unit: unit,
        );

        if (mounted) {
          if (newProduct != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Product created successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/admin/products');
          } else {
            throw Exception('Failed to create product');
          }
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
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Product' : 'Add Product'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _currentImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) =>
                                      _buildImagePlaceholder(),
                                ),
                              )
                            : _buildImagePlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(_selectedImage != null || _currentImageUrl != null
                      ? 'Change Image'
                      : 'Add Image'),
                ),
              ),
              const SizedBox(height: 24),

              // Product name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Price must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: categoryProvider.categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stock quantity
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter stock quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) < 0) {
                    return 'Stock cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Unit
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., piece, kg, liter',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Active status toggle
              SwitchListTile(
                title: const Text('Active'),
                subtitle: Text(_isActive
                    ? 'Product is visible to customers'
                    : 'Product is hidden from customers'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: AppColors.primaryGreen,
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.isEditMode ? 'Update Product' : 'Create Product'),
              ),
              const SizedBox(height: 16),

              // Cancel button
              OutlinedButton(
                onPressed: _isSaving ? null : () => context.go('/admin/products'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          'Tap to add image',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
