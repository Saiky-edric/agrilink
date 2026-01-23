import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/farmer_profile_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/star_rating_display.dart';
import '../../../shared/widgets/premium_badge.dart';

class ModernSearchScreen extends StatefulWidget {
  const ModernSearchScreen({super.key});

  @override
  State<ModernSearchScreen> createState() => _ModernSearchScreenState();
}

class _ModernSearchScreenState extends State<ModernSearchScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  
  List<ProductModel> _searchResults = [];
  List<Map<String, dynamic>> _storeResults = [];
  String _filter = 'All'; // All | Stores | Products
  List<ProductModel> _allProducts = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _currentQuery = '';
  String? _selectedCategory;
  
  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits', 
    'Grains',
    'Herbs',
    'Dairy',
    'Meat',
    'Organic'
  ];
  
  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;
  
  // Recommendations based on available farm crops and methods
  final List<String> _recommendedSearches = [
    // Primary Crops
    'Rice',
    'Corn',
    'Vegetables',
    'Fruits',
    'Banana',
    'Coconut',
    'Cassava',
    'Coffee',
    // Farming Methods
    'Organic Farming',
    'Sustainable Agriculture',
    'Hydroponic',
    'Pesticide-free',
    'Farm fresh'
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadAllProducts();
    _searchController.addListener(_onSearchChanged);
  }

  // Load recent searches from local storage
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_recentSearchesKey) ?? [];
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      // If loading fails, just use empty list
      setState(() {
        _recentSearches = [];
      });
    }
  }

  // Save recent searches to local storage
  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, _recentSearches);
    } catch (e) {
      // Silently fail if save doesn't work
    }
  }

  // Add a search query to recent searches
  Future<void> _addToRecentSearches(String query) async {
    if (query.trim().isEmpty) return;
    
    final trimmedQuery = query.trim();
    
    setState(() {
      // Remove if already exists
      _recentSearches.remove(trimmedQuery);
      // Add to the beginning
      _recentSearches.insert(0, trimmedQuery);
      // Keep only the last N searches
      if (_recentSearches.length > _maxRecentSearches) {
        _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
      }
    });
    
    await _saveRecentSearches();
  }

  // Remove a single search from recent searches
  Future<void> _removeFromRecentSearches(String query) async {
    setState(() {
      _recentSearches.remove(query);
    });
    await _saveRecentSearches();
  }

  // Clear all recent searches
  Future<void> _clearRecentSearches() async {
    setState(() {
      _recentSearches.clear();
    });
    await _saveRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      } else {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
        });
      }
    });
  }

  Future<void> _loadAllProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getAvailableProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    setState((){ _currentQuery = query; _isLoading = true; });
    if (query.isEmpty) return;

    // Add to recent searches
    await _addToRecentSearches(query);

    setState(() {
      _isLoading = true;
      _currentQuery = query;
      _hasSearched = true;
    });

    try {
      // Smart search: name, description, category, farm name + store search (including crops and methods)
      // Parallel store search
      final storeRows = await FarmerProfileService().searchStores(query);
      _storeResults = storeRows;

      final results = _allProducts.where((product) {
        final searchLower = query.toLowerCase();
        return product.name.toLowerCase().contains(searchLower) ||
               product.description.toLowerCase().contains(searchLower) ||
               product.category.toString().toLowerCase().contains(searchLower) ||
               product.farmName.toLowerCase().contains(searchLower);
      }).toList();

      // Filter by category if selected (case-insensitive)
      final filteredResults = _selectedCategory == null || _selectedCategory == 'All'
          ? results
          : results.where((p) => 
              p.category.toString().toLowerCase().contains(_selectedCategory!.toLowerCase())
            ).toList();
      
      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectSearch(String query) {
    setState((){ _filter = 'All'; });
    _searchController.text = query;
    _performSearch(query);
  }

  void _clearSearch() {
    setState((){ _filter = 'All'; });
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
      _currentQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      resizeToAvoidBottomInset: false, // Prevents keyboard from resizing screen
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            _buildCategoryFilter(),
            _buildFilterChips(),
            Expanded(child: _buildSearchContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search fresh products...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: _performSearch,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = isSelected ? null : category;
              });
              if (_hasSearched) {
                _performSearch(_currentQuery);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasSearched) {
      return _buildSearchSuggestions();
    }
    if (_filter == 'Stores') return _buildStoresResults();
    if (_filter == 'Products') return _buildProductResultsOnly();
    if (_searchResults.isEmpty && _storeResults.isEmpty) {
      return _buildEmptyState();
    }
    return _buildSearchResults();
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recentSearches.isNotEmpty) ...[
            _buildSuggestionSection('Recent Searches', _recentSearches, Icons.history),
            const SizedBox(height: 24),
          ],
          _buildSuggestionSection('Recommended for You', _recommendedSearches, Icons.recommend),
        ],
      ),
    );
  }

  Widget _buildSuggestionSection(String title, List<String> items, IconData icon) {
    final isRecentSearches = title == 'Recent Searches';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (isRecentSearches && items.isNotEmpty)
              TextButton(
                onPressed: () async {
                  // Show confirmation dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Recent Searches'),
                      content: const Text('Are you sure you want to clear all recent searches?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Clear', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    await _clearRecentSearches();
                  }
                },
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => _buildSuggestionChip(item, isRecentSearch: isRecentSearches)).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text, {bool isRecentSearch = false}) {
    return GestureDetector(
      onTap: () => _selectSearch(text),
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: isRecentSearch ? 8 : 16,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRecentSearch) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _removeFromRecentSearches(text),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Clear Search', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return RefreshIndicator(
      onRefresh: () => _performSearch(_currentQuery),
      child: Column(
        children: [
          if (_storeResults.isNotEmpty) _buildStoresSection(),
          Expanded(child: _buildProductResultsOnly()),
        ],
      ),
    );
  }

  // Filter chips for All / Stores / Products
  Widget _buildFilterChips() {
    final base = const ['All', 'Stores', 'Products'];
    // Build dynamic labels with counts after a search completes
    final labels = base.map((opt) {
      if (!_hasSearched) return opt;
      final storesCount = _storeResults.length;
      final productsCount = _searchResults.length;
      final allCount = storesCount + productsCount;
      switch (opt) {
        case 'All':
          return 'All ($allCount)';
        case 'Stores':
          return 'Stores ($storesCount)';
        case 'Products':
          return 'Products ($productsCount)';
        default:
          return opt;
      }
    }).toList(growable: false);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: base.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = base[index];
          final label = labels[index];
          final selected = _filter == opt;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            selectedColor: AppTheme.primaryGreen.withOpacity(0.15),
            labelStyle: TextStyle(
              color: selected ? AppTheme.primaryGreen : AppTheme.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
            shape: StadiumBorder(side: BorderSide(color: selected ? AppTheme.primaryGreen : Colors.grey.shade300)),
            onSelected: (_) {
              setState(() {
                _filter = opt;
              });
            },
          );
        },
      ),
    );
  }

  // Compact Stores section shown in "All" view
  Widget _buildStoresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Icon(Icons.storefront, size: 18, color: AppTheme.textPrimary),
              const SizedBox(width: 8),
              Text(
                'Stores (${_storeResults.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const Spacer(),
              if (_storeResults.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() { _filter = 'Stores'; }),
                  child: const Text('See all'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _storeResults.length.clamp(0, 10),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final store = _storeResults[index];
              return _buildStoreCard(store, compact: true);
            },
          ),
        ),
      ],
    );
  }

  // Full Stores results view when filter == 'Stores'
  Widget _buildStoresResults() {
    if (_storeResults.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: () => _performSearch(_currentQuery),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _storeResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final store = _storeResults[index];
          return _buildStoreCard(store);
        },
      ),
    );
  }

  // Generic empty state when both stores and products are empty
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12), // Top spacing
            // Lottie Animation
            Lottie.asset(
              'assets/lottie/no_search_results.json',
              width: 240,
              height: 240,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            const Text(
              'No results found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Clear Search', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 40), // Add bottom spacing for balance
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> row, {bool compact = false}) {
    final id = (row['id'] ?? '').toString();
    final verification = row['farmer_verifications'];
    // Derive display name with fallbacks: store_name > farmer_verifications.farm_name > full_name
    String? farmName;
    if (verification is List && verification.isNotEmpty) {
      final first = verification.first;
      farmName = (first['farm_name'] as String?)?.trim();
    } else if (verification is Map) {
      farmName = (verification['farm_name'] as String?)?.trim();
    }
    final rawStoreName = (row['store_name'] as String?)?.trim();
    final displayName = (rawStoreName != null && rawStoreName.isNotEmpty)
        ? rawStoreName
        : ((farmName != null && farmName.isNotEmpty)
            ? farmName
            : ((row['full_name'] as String?) ?? 'Store'));
    final storeName = displayName;
    final muni = (row['municipality'] ?? '').toString();
    final brgy = (row['barangay'] ?? '').toString();
    final location = [muni, brgy].where((e) => e.isNotEmpty).join(', ');
    final stats = row['seller_statistics'] as Map<String, dynamic>?;
    final totalProducts = (stats?['total_products'] ?? 0).toString();
    final avgRating = (stats?['average_rating'] ?? 0).toString();
    final totalReviews = (stats?['total_reviews'] ?? 0).toString();
    String status = '';
    if (verification is List && verification.isNotEmpty) {
      status = (verification.first['status'] ?? '').toString();
    } else if (verification is Map) {
      status = (verification['status'] ?? '').toString();
    }
    final isVerified = status == 'accepted' || status == 'verified';
    final logoUrl = (row['store_logo_url'] ?? row['avatar_url']) as String?;
    
    // Check premium status
    bool isPremium = false;
    final subscriptionTier = row['subscription_tier'] ?? 'free';
    if (subscriptionTier == 'premium') {
      final expiresAt = row['subscription_expires_at'];
      if (expiresAt == null) {
        isPremium = true;
      } else {
        final expiryDate = DateTime.tryParse(expiresAt);
        isPremium = expiryDate != null && expiryDate.isAfter(DateTime.now());
      }
    }

    final bannerUrl = (row['store_banner_url'] as String?)?.trim();
    final hasBanner = bannerUrl != null && bannerUrl.isNotEmpty;

    final card = Container(
      width: compact ? 260 : null,
      height: compact ? 120 : 120,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: hasBanner ? Colors.green.shade50 : AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        image: hasBanner
            ? DecorationImage(
                image: NetworkImage(bannerUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Gradient overlay to ensure text remains readable (stronger only if banner exists)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: hasBanner
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color.fromARGB(80, 0, 0, 0), // ~0.31 opacity
                        ],
                        stops: [0.0, 0.6, 1.0],
                      )
                    : null,
              ),
            ),
          ),
          // Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: logoUrl != null && logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                    child: (logoUrl == null || logoUrl.isEmpty)
                        ? const Icon(Icons.storefront, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                storeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (isPremium) ...[
                              const SizedBox(width: 6),
                              PremiumBadge(
                                isPremium: true,
                                size: 14,
                                showLabel: false,
                              ),
                            ],
                            if (isVerified) const SizedBox(width: 6),
                            if (isVerified)
                              const Icon(Icons.verified, color: Colors.lightGreenAccent, size: 18),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (location.isNotEmpty)
                          Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withOpacity(0.9)),
                          ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            StarRatingDisplay(
                              rating: double.tryParse(avgRating) ?? 0.0,
                              size: 14,
                              color: Colors.amber,
                              emptyColor: Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '$avgRating ($totalReviews) • $totalProducts products',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tap target
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => context.push('/public-farmer/$id'),
                splashColor: Colors.white24,
                highlightColor: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );

    if (compact) {
      return SizedBox(width: 260, child: card);
    }
    return card;
  }

  Widget _buildProductResultsOnly() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_searchResults.length} results for "$_currentQuery"',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (_selectedCategory != null && _selectedCategory != 'All') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'in $_selectedCategory',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
         child: RefreshIndicator(
           onRefresh: () => _performSearch(_currentQuery),
           child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return ProductCard(
                product: product,
                onTap: () => context.push('/buyer/product/${product.id}'),
                // onFavorite removed
              );
            },
          ),
        ),
        ),
      ],
    );
  }
}