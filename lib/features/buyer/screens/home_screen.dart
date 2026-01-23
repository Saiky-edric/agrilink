import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/product_service.dart';
import '../../../core/models/product_model.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/modern_bottom_nav.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../core/services/badge_service.dart';
import '../../../shared/widgets/unread_badge.dart';
import '../../../core/config/environment.dart';
import '../../../core/services/supabase_service.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<ProductModel> _featuredProducts = []; // Premium products for featured carousel
  List<ProductModel> _allProducts = []; // All products for product grid
  final List<String> _categories = ['Vegetables', 'Fruits', 'Grains', 'Dairy', 'Organic', 'Spices'];
  bool _isLoading = true;
  String _userName = '';
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _loadData();
    _initializeBadges();
    _animationController.forward();
  }

  void _initializeBadges() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final badgeService = Provider.of<BadgeService>(context, listen: false);
      badgeService.initializeBadges();
      badgeService.startListening();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load user info
      final user = await _authService.getCurrentUserProfile();
      if (user != null) {
        setState(() => _userName = user.fullName ?? 'User');
      }
      
      // Load featured products (premium only) and all products
      await Future.wait([
        _loadFeaturedProducts(),
        _loadAllProducts(),
      ]);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadAllProducts() async {
    try {
      EnvironmentConfig.log('Loading all products...');
      
      // Get all products (both free and premium farmers)
      final products = await _productService.getAvailableProducts(limit: 20);
      
      EnvironmentConfig.log('Loaded ${products.length} products');
      
      setState(() {
        _allProducts = products;
      });
    } catch (e) {
      EnvironmentConfig.logError('Failed to load products', e);
      // Handle error gracefully
    }
  }


  Future<void> _loadFeaturedProducts() async {
    try {
      EnvironmentConfig.log('Loading premium featured products with daily rotation...');
      
      // Get products from premium farmers only for the featured carousel
      final supabase = SupabaseService.instance;
      final response = await supabase.client
          .from('products')
          .select('''
            *,
            farmer:farmer_id (
              id,
              full_name,
              store_name,
              municipality,
              barangay,
              subscription_tier,
              subscription_expires_at
            )
          ''')
          .eq('is_hidden', false)
          .gt('stock', 0)
          .order('created_at', ascending: false)
          .limit(50); // Get more products to enable rotation

      final premiumProducts = <ProductModel>[];
      for (final item in response) {
        final farmer = item['farmer'] as Map<String, dynamic>?;
        final tier = farmer?['subscription_tier'] as String? ?? 'free';
        final expiresAt = farmer?['subscription_expires_at'] as String?;
        
        final isPremium = tier == 'premium' && 
            (expiresAt == null || DateTime.parse(expiresAt).isAfter(DateTime.now()));
        
        if (isPremium) {
          premiumProducts.add(ProductModel.fromJson(item));
        }
      }
      
      EnvironmentConfig.log('Found ${premiumProducts.length} premium products for rotation');
      
      // Apply daily rotation using today's date as seed
      final rotatedProducts = _applyDailyRotation(premiumProducts, maxCount: 10);
      
      EnvironmentConfig.log('Selected ${rotatedProducts.length} products for today\'s featured carousel');
      
      setState(() {
        _featuredProducts = rotatedProducts;
      });
    } catch (e) {
      EnvironmentConfig.logError('Failed to load featured products', e);
      // Handle error gracefully
      setState(() {
        _featuredProducts = [];
      });
    }
  }
  
  /// Apply daily rotation to products using date-based seed
  /// This ensures the same products are shown all day, but changes daily
  List<ProductModel> _applyDailyRotation(List<ProductModel> products, {required int maxCount}) {
    if (products.isEmpty) return [];
    
    // Get today's date as seed (days since epoch)
    final today = DateTime.now();
    final daysSinceEpoch = today.difference(DateTime(1970, 1, 1)).inDays;
    
    // Create a copy of the list to shuffle
    final shuffledProducts = List<ProductModel>.from(products);
    
    // Use seeded random for consistent daily rotation
    final random = _SeededRandom(daysSinceEpoch);
    
    // Fisher-Yates shuffle with seeded random
    for (int i = shuffledProducts.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffledProducts[i];
      shuffledProducts[i] = shuffledProducts[j];
      shuffledProducts[j] = temp;
    }
    
    // Return up to maxCount products
    final count = shuffledProducts.length < maxCount ? shuffledProducts.length : maxCount;
    return shuffledProducts.take(count).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: _isLoading 
          ? LoadingWidgets.fullScreenLoader(message: 'Loading fresh products...')
          : FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  _buildModernAppBar(context),
                  SliverToBoxAdapter(child: _buildPremiumFeaturedCarousel()),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildCategoriesSection()),
                  SliverToBoxAdapter(child: _buildMoreProductsSection()),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    sliver: _buildMoreProductsGrid(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100), // Space for bottom nav
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const ModernBottomNav(currentIndex: 0),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 60,
      floating: true,
      pinned: false,
      backgroundColor: AppTheme.backgroundWhite,
      surfaceTintColor: AppTheme.backgroundWhite,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.freshGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.agriculture,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'Agrilink',
            style: AppTextStyles.heading3,
          ),
        ],
      ),
      actions: [
        Consumer<BadgeService>(
          builder: (context, badgeService, child) {
            return NotificationBadge(
              unreadCount: badgeService.unreadNotifications,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentPurple.withOpacity(0.15),
                        AppTheme.accentPink.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentPurple.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.accentPurple,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  context.push('/notifications');
                },
              ),
            );
          },
        ),
        Consumer<BadgeService>(
          builder: (context, badgeService, child) {
            return CartBadge(
              itemCount: badgeService.cartItemCount,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentTeal.withOpacity(0.15),
                        AppTheme.primaryGreen.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentTeal.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: AppTheme.accentTeal,
                    size: 20,
                  ),
                ),
                onPressed: () => context.push(RouteNames.cart),
              ),
            );
          },
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildPremiumFeaturedCarousel() {
    // Show loading shimmer if products haven't loaded yet
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        height: 280,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If no products available, show empty state
    if (_featuredProducts.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        height: 280,
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No Premium Products Available',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Check back soon for featured products from premium farmers',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use all featured products (up to 10) for carousel
    final carouselProducts = _featuredProducts;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'PREMIUM FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${carouselProducts.length} items',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Carousel
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                FlutterCarousel(
                  items: carouselProducts.map((product) => _buildFullWidthProductCard(product)).toList(),
                  options: CarouselOptions(
                    height: 280,
                    viewportFraction: 1.0,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 6),
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.easeInOut,
                    enlargeCenterPage: false,
                    showIndicator: false,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentCarouselIndex = index;
                      });
                    },
                  ),
                ),
                // Indicator Dots
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      carouselProducts.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentCarouselIndex == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentCarouselIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFullWidthProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () => context.push('/buyer/product/${product.id}'),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          gradient: AppTheme.freshGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGreen.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Product Image with Overlay
            Positioned.fill(
              child: product.coverImageUrl.isNotEmpty
                  ? Stack(
                      children: [
                        Image.network(
                          product.coverImageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            child: const Icon(
                              Icons.agriculture,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Gradient overlay for better text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryGreenDark.withOpacity(0.7),
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.3, 0.6, 1.0],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryGreen.withOpacity(0.8),
                            AppTheme.primaryGreen,
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.agriculture,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    ),
            ),
            
            // Content Overlay
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top badges row
                    Row(
                      children: [
                        // Featured Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: AppTheme.featuredGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.featuredGold.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'FEATURED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Rating badge
                        if (product.averageRating > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.featuredGold,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '(${product.totalReviews})',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Bottom content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            product.category.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Product Name
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Farm Name with location icon
                        Row(
                          children: [
                            Icon(
                              Icons.store,
                              color: Colors.white.withOpacity(0.9),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                product.farmName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Price and Stock Info
                        Row(
                          children: [
                            // Price
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '₱${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 8),
                            
                            // Stock indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${product.stock} ${product.unit}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // View button
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGreen.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GestureDetector(
        onTap: () => context.push(RouteNames.search),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.surfaceBlue,
                AppTheme.surfaceLight,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentTeal.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentTeal.withOpacity(0.2),
                      AppTheme.primaryGreen.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.search,
                  color: AppTheme.accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Search for fresh products...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shop by Category',
                style: AppTextStyles.heading3,
              ),
              TextButton(
                onPressed: () => context.push(RouteNames.categories),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentTeal,
                  backgroundColor: AppTheme.accentTeal.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('See All'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 95,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryCard(_categories[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String category) {
    // Match icons with categories screen
    final icons = {
      'Vegetables': Icons.eco,              // Eco-friendly vegetables
      'Fruits': Icons.apple,                 // Apple for fruits
      'Grains': Icons.grain,                 // Grain icon
      'Dairy': Icons.local_drink,            // Dairy/milk icon
      'Organic': Icons.eco,                  // Organic/eco icon
      'Spices': Icons.local_florist,         // Herbs/spices
    };

    // Modern gradient colors for each category - MORE VIBRANT
    final gradients = {
      'Vegetables': [AppTheme.surfaceGreen, AppTheme.accentGreen.withOpacity(0.3)],
      'Fruits': [AppTheme.surfacePink, Color(0xFFFCE7F3)],       // Bright pink
      'Grains': [Color(0xFFFEF3C7), AppTheme.accentYellow.withOpacity(0.3)],  // Sunny yellow
      'Dairy': [AppTheme.surfaceBlue, Color(0xFFBBDEFB)],        // Bright blue
      'Organic': [AppTheme.surfaceGreen, AppTheme.primaryGreenLight.withOpacity(0.2)],
      'Spices': [AppTheme.surfaceWarm, AppTheme.accentOrange.withOpacity(0.3)],  // Vibrant orange
    };

    final iconColors = {
      'Vegetables': AppTheme.primaryGreen,
      'Fruits': AppTheme.accentPink,           // Bright pink
      'Grains': AppTheme.accentYellow,         // Sunny yellow
      'Dairy': AppTheme.accentTeal,            // Turquoise
      'Organic': AppTheme.primaryGreen,
      'Spices': AppTheme.accentOrange,         // Coral orange
    };

    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('${RouteNames.categories}?category=$category'),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Modern card with gradient and shadow
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradients[category] ?? [AppTheme.surfaceLight, AppTheme.lightGrey],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (iconColors[category] ?? AppTheme.primaryGreen).withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: (iconColors[category] ?? AppTheme.primaryGreen).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icons[category] ?? Icons.category,
                  color: iconColors[category] ?? AppTheme.primaryGreen,
                  size: 26,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Category label
              Text(
                category,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreProductsSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentYellow.withOpacity(0.2),
                      AppTheme.accentOrange.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: AppTheme.accentOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'More Products',
                style: AppTextStyles.heading3,
              ),
            ],
          ),
          TextButton(
            onPressed: () => context.push(RouteNames.categories),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentOrange,
              backgroundColor: AppTheme.accentOrange.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('View All'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreProductsGrid() {
    if (_isLoading) {
      return SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => LoadingWidgets.productCardShimmer(),
          childCount: 6,
        ),
      );
    }

    if (_allProducts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'No products available at the moment',
              style: AppTextStyles.bodyLarge,
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < _allProducts.length) {
            return ProductCard(product: _allProducts[index]);
          }
          return null;
        },
        childCount: _allProducts.length,
      ),
    );
  }
}

/// Simple seeded random number generator for consistent daily rotation
class _SeededRandom {
  int _seed;
  
  _SeededRandom(this._seed);
  
  int nextInt(int max) {
    if (max <= 0) return 0;
    // Linear congruential generator
    _seed = ((_seed * 1103515245) + 12345) & 0x7fffffff;
    return _seed % max;
  }
}