import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../products/providers/product_provider.dart';
import '../../categories/providers/category_provider.dart';

/// Admin product list screen.
/// 
/// Displays all products (active and inactive) with search, filter, and CRUD actions.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(includeInactive: true);
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    var products = productProvider.products;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      products = products.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/admin/products/new'),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Product list
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : productProvider.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(productProvider.errorMessage!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => productProvider.loadProducts(
                                includeInactive: true,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No products yet'
                                      : 'No products found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_searchQuery.isEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        context.go('/admin/products/new'),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add First Product'),
                                  ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => productProvider.refresh(
                              includeInactive: true,
                            ),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                final category =
                                    categoryProvider.getCategoryById(
                                  product.categoryId ?? '',
                                );

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: product.imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              product.imageUrl,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stack) =>
                                                      Container(
                                                width: 56,
                                                height: 56,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                    Icons.image_not_supported),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.image),
                                          ),
                                    title: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('\$${product.price.toStringAsFixed(2)}'),
                                        if (category != null)
                                          Text('Category: ${category.name}'),
                                        Text('Stock: ${product.stockQuantity}'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Chip(
                                          label: Text(
                                            product.isActive
                                                ? 'Active'
                                                : 'Inactive',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor: product.isActive
                                              ? Colors.green[100]
                                              : Colors.red[100],
                                        ),
                                        PopupMenuButton(
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: product.isActive
                                                  ? 'deactivate'
                                                  : 'activate',
                                              child: Row(
                                                children: [
                                                  Icon(product.isActive
                                                      ? Icons.remove_circle
                                                      : Icons.check_circle),
                                                  const SizedBox(width: 8),
                                                  Text(product.isActive
                                                      ? 'Deactivate'
                                                      : 'Activate'),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              context.go(
                                                '/admin/products/${product.id}',
                                              );
                                            } else if (value == 'deactivate') {
                                              _deactivateProduct(
                                                context,
                                                product.id,
                                              );
                                            } else if (value == 'activate') {
                                              _activateProduct(
                                                context,
                                                product.id,
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    onTap: () => context.go(
                                      '/admin/products/${product.id}',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/admin/products/new'),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _deactivateProduct(BuildContext context, String productId) async {
    final productProvider = context.read<ProductProvider>();
    final success = await productProvider.updateProduct(
      productId,
      isActive: false,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success != null
                ? 'Product deactivated successfully'
                : 'Failed to deactivate product',
          ),
          backgroundColor: success != null ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _activateProduct(BuildContext context, String productId) async {
    final productProvider = context.read<ProductProvider>();
    final success = await productProvider.updateProduct(
      productId,
      isActive: true,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success != null
                ? 'Product activated successfully'
                : 'Failed to activate product',
          ),
          backgroundColor: success != null ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
