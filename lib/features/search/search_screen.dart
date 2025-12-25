import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/product_card.dart';
import '../products/providers/product_provider.dart'; // Fixed import again


import '../../features/categories/providers/category_provider.dart';
import 'services/search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String? _selectedCategoryId;
  SortBy _sortBy = SortBy.nameAsc;

  @override
  void initState() {
    super.initState();
    // Load categories for filter chips
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
      _performSearch();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  void _performSearch() {
    context.read<ProductProvider>().advancedSearch(
          query: _controller.text,
          categoryId: _selectedCategoryId,
          sortBy: _sortBy,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          onChanged: _onSearchChanged,
          autofocus: true,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Search products...",
            hintStyle: const TextStyle(fontWeight: FontWeight.normal, color: Colors.grey),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _performSearch();
                    },
                  )
                : null,
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          const Divider(height: 1),
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        // Category Chips
        Consumer<CategoryProvider>(
          builder: (context, provider, child) {
            if (provider.categories.isEmpty && provider.isLoading) {
              return const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            return Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text("All"),
                      selected: _selectedCategoryId == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategoryId = null);
                          _performSearch();
                        }
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedCategoryId == null ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  ...provider.categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category.name),
                        selected: _selectedCategoryId == category.id,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = selected ? category.id : null;
                          });
                          _performSearch();
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _selectedCategoryId == category.id ? Colors.white : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
        
        // Sort Option
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Sort by:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<SortBy>(
                value: _sortBy,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: SortBy.nameAsc, child: Text("Name: A-Z")),
                  DropdownMenuItem(value: SortBy.nameDesc, child: Text("Name: Z-A")),
                  DropdownMenuItem(value: SortBy.priceAsc, child: Text("Price: Low to High")),
                  DropdownMenuItem(value: SortBy.priceDesc, child: Text("Price: High to Low")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortBy = value);
                    _performSearch();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.searchResults.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.searchResults.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.search,
            title: "No items found",
            message: "Try searching with a different keyword\nor clearing filters.",
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: provider.searchResults.length,
          itemBuilder: (context, index) {
            final product = provider.searchResults[index];
            return ProductCard(
              product: product,
              onTap: () => GoRouter.of(context).push('/product/${product.id}'),
            );
          },
        );
      },
    );
  }
}
