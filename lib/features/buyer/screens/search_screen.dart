import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/product_service.dart';
import '../../../core/models/product_model.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../core/config/environment.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ProductService _productService = ProductService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<ProductModel> _searchResults = [];
  List<String> _recentSearches = [];
  final List<String> _suggestions = [
    'Fresh tomatoes',
    'Organic vegetables',
    'Local fruits',
    'Dairy products',
    'Whole grains',
    'Herbs and spices'
  ];
  
  bool _isLoading = false;
  bool _hasSearched = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    
    _loadRecentSearches();
    _searchFocusNode.requestFocus();
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    // Load recent searches from shared preferences
    // This would typically use SharedPreferences to load saved search history
    setState(() {
      _recentSearches = ['Organic tomatoes', 'Fresh lettuce', 'Local honey'];
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasSearched = false;
      _currentQuery = query.trim();
    });

    try {
      EnvironmentConfig.log('Searching for products with query: "$query"');
      
      // Use ProductService to search products
      final products = await _productService.searchProducts(query.trim());
      
      EnvironmentConfig.log('Found ${products.length} products matching "$query"');

      setState(() {
        _searchResults = products;
        _isLoading = false;
        _hasSearched = true;
      });

      // Add to recent searches
      if (!_recentSearches.contains(query)) {
        setState(() {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }
    } catch (e) {
      EnvironmentConfig.logError('Search failed for query: "$query"', e);
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: AppTheme.lightGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search fresh products...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _hasSearched = false;
                          _searchResults.clear();
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: _performSearch,
            onChanged: (value) => setState(() {}),
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.lightGrey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? LoadingWidgets.productGridShimmer()
            : _hasSearched
                ? _buildSearchResults()
                : _buildSearchSuggestions(),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: AppTextStyles.heading3,
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _recentSearches.clear());
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...(_recentSearches.map((search) => _buildSearchItem(
              search,
              Icons.history,
              onTap: () => _performSearch(search),
              onDelete: () {
                setState(() => _recentSearches.remove(search));
              },
            )).toList()),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Suggested searches
          const Text(
            'Popular Searches',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...(_suggestions.map((suggestion) => _buildSearchItem(
            suggestion,
            Icons.trending_up,
            onTap: () => _performSearch(suggestion),
          )).toList()),
        ],
      ),
    );
  }

  Widget _buildSearchItem(
    String text,
    IconData icon, {
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        title: Text(
          text,
          style: AppTextStyles.bodyMedium,
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
                onPressed: onDelete,
              )
            : const Icon(
                Icons.call_made,
                color: AppTheme.textSecondary,
                size: 18,
              ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppTheme.lightGrey.withOpacity(0.5),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return ErrorWidgets.noDataFound(
        title: 'No products found',
        message: 'Try searching with different keywords or browse categories.',
        onRefresh: () => _performSearch(_currentQuery),
        icon: Icons.search_off,
      );
    }

    return Column(
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchResults.length} results for "$_currentQuery"',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Filter button could be added here
            ],
          ),
        ),

        // Results grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.75,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return ProductCard(
                product: product,
                onTap: () {
                  context.push(
                    RouteNames.productDetails.replaceAll(':id', product.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}