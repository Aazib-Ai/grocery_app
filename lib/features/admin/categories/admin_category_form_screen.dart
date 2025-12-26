import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/image_storage_service.dart';
import '../../categories/providers/category_provider.dart';
import '../../../domain/entities/category.dart' as entities;

/// Admin category form screen for creating and editing categories.
/// 
/// Supports image upload with R2 storage integration.
class AdminCategoryFormScreen extends StatefulWidget {
  final String? categoryId;

  const AdminCategoryFormScreen({super.key, this.categoryId});

  bool get isEditMode => categoryId != null;

  @override
  State<AdminCategoryFormScreen> createState() =>
      _AdminCategoryFormScreenState();
}

class _AdminCategoryFormScreenState extends State<AdminCategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');

  late final ImageStorageService _imageStorage;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isSaving = false;
  File? _selectedImage;
  String? _currentImageUrl;
  entities.Category? _category;

  @override
  void initState() {
    super.initState();
    // Use R2ImageStorageService for real image uploads
    _imageStorage = R2ImageStorageService();

    if (widget.isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCategory();
      });
    }
  }

  Future<void> _loadCategory() async {
    setState(() {
      _isLoading = true;
    });

    final categoryProvider = context.read<CategoryProvider>();
    final category = categoryProvider.getCategoryById(widget.categoryId!);

    if (category != null) {
      setState(() {
        _category = category;
        _nameController.text = category.name;
        _sortOrderController.text = category.sortOrder.toString();
        _currentImageUrl = category.imageUrl;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category not found')),
        );
        context.go('/admin/categories');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
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
      final categoryId = widget.categoryId ?? 'new';
      final imageUrl = await _imageStorage.uploadProductImage(
        _selectedImage!,
        categoryId,
      );

      // If updating and old image exists, delete it
      if (widget.isEditMode &&
          _currentImageUrl != null &&
          _currentImageUrl!.isNotEmpty) {
        try {
          await _imageStorage.deleteImage(_currentImageUrl!);
        } catch (e) {
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

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload image if selected
      final imageUrl = await _uploadImage();

      final categoryProvider = context.read<CategoryProvider>();

      final name = _nameController.text.trim();
      final sortOrder = int.parse(_sortOrderController.text);

      if (widget.isEditMode) {
        // Update existing category
        final updatedCategory = await categoryProvider.updateCategory(
          widget.categoryId!,
          name: name,
          imageUrl: imageUrl,
          sortOrder: sortOrder,
        );

        if (mounted) {
          if (updatedCategory != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Category updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/admin/categories');
          } else {
            throw Exception('Failed to update category');
          }
        }
      } else {
        // Create new category
        final newCategory = await categoryProvider.createCategory(
          name: name,
          imageUrl: imageUrl,
          sortOrder: sortOrder,
        );

        if (mounted) {
          if (newCategory != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Category created successfully'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/admin/categories');
          } else {
            throw Exception('Failed to create category');
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Category' : 'Add Category'),
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
                    width: 150,
                    height: 150,
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
                        : _currentImageUrl != null &&
                                _currentImageUrl!.isNotEmpty
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
                      : 'Add Image (Optional)'),
                ),
              ),
              const SizedBox(height: 24),

              // Category name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Sort order
              TextFormField(
                controller: _sortOrderController,
                decoration: const InputDecoration(
                  labelText: 'Sort Order',
                  border: OutlineInputBorder(),
                  hintText: 'Lower numbers appear first',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter sort order';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.isEditMode
                        ? 'Update Category'
                        : 'Create Category'),
              ),
              const SizedBox(height: 16),

              // Cancel button
              OutlinedButton(
                onPressed:
                    _isSaving ? null : () => context.go('/admin/categories'),
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
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          'Tap to add image',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}
