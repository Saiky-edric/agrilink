import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/product_service.dart';
import '../../../core/models/product_model.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/modern_bottom_nav.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../core/config/environment.dart';

class CategoriesScreen extends StatefulWidget {
  final String? initialCategory;
  const CategoriesScreen({super.key, this.initialCategory});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  
  late TabController _tabController;
  Map<ProductCategory, List<ProductModel>> _productsByCategory = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ProductCategory.values.length, vsync: this);

    // Jump to initial category if provided
    final initial = widget.initialCategory?.trim().toLowerCase();
    if (initial != null && initial.isNotEmpty) {
      final index = ProductCategory.values.indexWhere((c) => c.name == initial || c.displayName.toLowerCase() == initial);
      if (index >= 0) {
        _tabController.index = index;
      }
    }

    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      EnvironmentConfig.log('Loading products by category...');
      
      // Load all available products using ProductService
      final allProducts = await _productService.getAvailableProducts(
        limit: 100, // Get more products for categorization
        offset: 0,
      );
      
      EnvironmentConfig.log('Loaded ${allProducts.length} total products for categorization');

      // Group products by category
      final Map<ProductCategory, List<ProductModel>> grouped = {};
      for (final category in ProductCategory.values) {
        grouped[category] = allProducts
            .where((product) => product.category == category)
            .toList();
        EnvironmentConfig.log('Category ${category.name}: ${grouped[category]!.length} products');
      }

      setState(() {
        _productsByCategory = grouped;
        _isLoading = false;
      });
    } catch (e) {
      EnvironmentConfig.logError('Failed to load products by category', e);
      setState(() {
        _productsByCategory = {};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () => context.push(RouteNames.search),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: AppTheme.textPrimary,
                size: 20,
              ),
            ),
            onPressed: () => context.push(RouteNames.cart),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: _isLoading 
            ? null 
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primaryGreen,
                labelColor: AppTheme.primaryGreen,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: ProductCategory.values.map((category) {
                  final productCount = _productsByCategory[category]?.length ?? 0;
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getCategoryIcon(category), size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Text('${category.displayName} ($productCount)'),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
      body: _isLoading
          ? LoadingWidgets.productGridShimmer()
          : TabBarView(
              controller: _tabController,
              children: ProductCategory.values.map((category) {
                final products = _productsByCategory[category] ?? [];
                return _buildCategoryProducts(category, products);
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.cart),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(
          Icons.shopping_cart,
          color: AppTheme.textOnPrimary,
        ),
      ),
      bottomNavigationBar: const ModernBottomNav(currentIndex: 1),
    );
  }

  Widget _buildCategoryProducts(ProductCategory category, List<ProductModel> products) {
    if (products.isEmpty) {
      return _buildEmptyCategory(category);
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: GridView.builder(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: 100, // Space for bottom navigation
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () => context.push(
              RouteNames.productDetails.replaceAll(':id', product.id),
            ),
            onFavorite: () {
              // Add to favorites functionality
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to favorites!')),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to favorites')),
              );
            } catch (e) {
              // ignore
            }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyCategory(ProductCategory category) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getCategoryIcon(category),
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No ${category.displayName.toLowerCase()} available',
              style: AppTextStyles.heading2.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check back later for fresh ${category.displayName.toLowerCase()} from local farmers',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: ElevatedButton(
                onPressed: () => context.push(RouteNames.search),
                child: const Text('Search Products'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.vegetables:
        return Icons.eco;
      case ProductCategory.fruits:
        return Icons.apple;
      case ProductCategory.grains:
        return Icons.grain;
      case ProductCategory.herbs:
        return Icons.local_florist;
      case ProductCategory.livestock:
        return Icons.pets;
      case ProductCategory.dairy:
        return Icons.local_drink;
      case ProductCategory.others:
        return Icons.category;
    }
  }
}