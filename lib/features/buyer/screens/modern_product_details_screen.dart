import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/full_screen_image_viewer.dart';
import '../../../shared/widgets/star_rating_display.dart';
import '../../chat/services/chat_service.dart';
import '../../../core/services/farmer_profile_service.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../farmer/screens/public_farmer_profile_screen.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/premium_badge.dart';

class ModernProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ModernProductDetailsScreen({super.key, required this.productId});

  @override
  State<ModernProductDetailsScreen> createState() => _ModernProductDetailsScreenState();
}

class _ModernProductDetailsScreenState extends State<ModernProductDetailsScreen> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  final WishlistService _wishlistService = WishlistService();
  
  ProductModel? _product;
  Map<String, dynamic>? _farmerStoreData;
  List<ProductModel> _similarProducts = [];
  bool _isLoading = true;
  bool _isLoadingSimilarProducts = false;
  String? _error;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _isTogglingFavorite = false;
  
  bool _isAddingToCart = false;
  
  
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final product = await _productService.getProductById(widget.productId);
      
      // Check if product is in favorites
      bool fav = false;
      if (product != null) {
        fav = await _wishlistService.isFavorite(product.id);
        
        // Fetch farmer store data
        try {
          final farmerData = await Supabase.instance.client
              .from('users')
              .select('''
                id,
                full_name,
                store_name,
                store_logo_url,
                avatar_url,
                store_description,
                municipality,
                barangay,
                subscription_tier,
                subscription_expires_at,
                farmer_verifications!farmer_verifications_farmer_id_fkey(farm_name, status),
                seller_statistics!seller_statistics_seller_id_fkey(average_rating, total_reviews, total_sales)
              ''')
              .eq('id', product.farmerId)
              .single();
          
          debugPrint('🏪 Raw store data: $farmerData');
          debugPrint('🏪 Store name: ${farmerData['store_name']}');
          debugPrint('🏪 Store logo: ${farmerData['store_logo_url']}');
          debugPrint('🏪 Avatar: ${farmerData['avatar_url']}');
          debugPrint('🏪 Full name: ${farmerData['full_name']}');
          debugPrint('🏪 Verifications: ${farmerData['farmer_verifications']}');
          debugPrint('🏪 Seller Statistics: ${farmerData['seller_statistics']}');
          
          _farmerStoreData = farmerData;
          debugPrint('🏪 Data assigned to state variable');
          
          // Force rebuild after data is loaded
          if (mounted) {
            setState(() {});
            debugPrint('🏪 setState called to trigger rebuild');
          }
        } catch (e) {
          debugPrint('⚠️ Error loading store data: $e');
          debugPrint('⚠️ Farmer ID: ${product.farmerId}');
        }
      }
      
      if (mounted) {
        setState(() {
          _product = product;
          _isFavorite = fav;
          _isLoading = false;
        });
      }
      
      if (product != null) {
        debugPrint('📦 Product loaded: ${product.name}');
        debugPrint('⭐ Rating: ${product.averageRating}, Reviews: ${product.totalReviews}, Sold: ${product.totalSold}');
        debugPrint('💬 Recent reviews: ${product.recentReviews.length}');
        debugPrint('❤️ Is favorite: $fav');
        
        // Load similar products from the same store
        _loadSimilarProducts(product.farmerId, product.id);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchStoreRating(String farmerId) async {
    try {
      final reviews = await Supabase.instance.client
          .from('seller_reviews')
          .select('rating')
          .eq('seller_id', farmerId);

      double averageRating = 0.0;
      int totalReviews = reviews.length;
      
      if (totalReviews > 0) {
        int totalRating = 0;
        for (final review in reviews) {
          totalRating += (review['rating'] as int? ?? 0);
        }
        averageRating = totalRating / totalReviews;
      }

      return {
        'average_rating': averageRating,
        'total_reviews': totalReviews,
      };
    } catch (e) {
      debugPrint('⚠️ Error fetching store rating: $e');
      return {
        'average_rating': 0.0,
        'total_reviews': 0,
      };
    }
  }

  Future<void> _loadSimilarProducts(String farmerId, String currentProductId) async {
    try {
      setState(() {
        _isLoadingSimilarProducts = true;
      });

      List<ProductModel> similarProducts = [];

      // Strategy 1: Try to get products from same store first
      final storeProducts = await _productService.getProductsByFarmer(farmerId);
      final filteredStoreProducts = storeProducts
          .where((p) => p.id != currentProductId)
          .toList();
      
      similarProducts.addAll(filteredStoreProducts);
      
      // Strategy 2: If we have less than 4 products, add products from same category
      if (similarProducts.length < 4 && _product != null) {
        try {
          final categoryProducts = await _productService.getProductsByCategory(
            _product!.category.name,
          );
          
          // Filter out current product and products already added
          final filteredCategoryProducts = categoryProducts
              .where((p) => 
                p.id != currentProductId && 
                !similarProducts.any((sp) => sp.id == p.id) &&
                p.farmerId != farmerId // Don't add same store products again
              )
              .take(4 - similarProducts.length)
              .toList();
          
          similarProducts.addAll(filteredCategoryProducts);
          debugPrint('🔍 Added ${filteredCategoryProducts.length} products from same category');
        } catch (e) {
          debugPrint('⚠️ Could not load category products: $e');
        }
      }
      
      // Shuffle to add variety (optional)
      if (similarProducts.length > 4) {
        similarProducts.shuffle();
      }
      
      // Take only first 5 products
      final finalProducts = similarProducts.take(5).toList();
      
      if (mounted) {
        setState(() {
          _similarProducts = finalProducts;
          _isLoadingSimilarProducts = false;
        });
      }
      
      debugPrint('🛍️ Loaded ${finalProducts.length} similar products (${filteredStoreProducts.length} from store, ${finalProducts.length - filteredStoreProducts.length} from category)');
    } catch (e) {
      debugPrint('⚠️ Error loading similar products: $e');
      if (mounted) {
        setState(() {
          _isLoadingSimilarProducts = false;
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

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Not Found')),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Product Images
          SliverAppBar(
            expandedHeight: 400,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: _isTogglingFavorite
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.black,
                        ),
                  onPressed: _isTogglingFavorite ? null : _toggleFavorite,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.black),
                  onPressed: _shareProduct,
                ),
              ),
              // Report button
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: AppTheme.errorRed, size: 20),
                          SizedBox(width: 8),
                          Text('Report Product'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'report') {
                      _reportProduct();
                    }
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: _buildSwipeableImageGallery(),
                ),
              ),
            ),
          ),

          // Product Content
          SliverToBoxAdapter(
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Product Info Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          _product!.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Rating and Reviews (wrapped to prevent overflow)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StarRatingDisplay(
                                  rating: _product!.averageRating,
                                  size: 18,
                                  color: AppTheme.featuredGold,
                                  emptyColor: Colors.grey.shade300,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _product!.averageRating > 0 
                                      ? _product!.averageRating.toStringAsFixed(1)
                                      : 'No rating',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '(${_product!.totalReviews} ${_product!.totalReviews == 1 ? 'review' : 'reviews'})',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            if (_product!.totalSold > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_product!.totalSold} sold',
                                  style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Price Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price and Unit
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '₱${_product!.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '/${_product?.unit ?? ''}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Stock Status
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _product!.stock > 0 
                                    ? AppTheme.surfaceGreen 
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _product!.stock > 0 
                                      ? AppTheme.accentGreen 
                                      : Colors.red.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _product!.stock > 0 
                                        ? Icons.check_circle 
                                        : Icons.error,
                                    size: 16,
                                    color: _product!.stock > 0 
                                        ? AppTheme.primaryGreen 
                                        : Colors.red.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _product!.stock > 0 
                                        ? '${_product!.stock} ${_product!.unit} available' 
                                        : 'Out of stock',
                                    style: TextStyle(
                                      color: _product!.stock > 0 
                                          ? AppTheme.primaryGreen 
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quantity Selector
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _quantity > 1 
                                    ? () => setState(() => _quantity--) 
                                    : null,
                                icon: const Icon(Icons.remove),
                                color: AppTheme.primaryGreen,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                ),
                                child: Text(
                                  _quantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _quantity < _product!.stock 
                                    ? () => setState(() => _quantity++) 
                                    : null,
                                icon: const Icon(Icons.add),
                                color: AppTheme.primaryGreen,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Product Details
                  _buildModernDetailsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Farmer/Store Info
                  _buildModernStoreCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Product Reviews
                  if (_product!.recentReviews.isNotEmpty)
                    _buildProductReviewsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Similar Products / More from this Store
                  if (_similarProducts.isNotEmpty || _isLoadingSimilarProducts)
                    _buildSimilarProductsSection(),
                  
                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Modern Bottom Action Buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Add to Cart Button
              Expanded(
                flex: 2,
                child: Container(
                  height: 56,
                  margin: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    onPressed: (_product!.stock > 0 && !_isAddingToCart) ? _addToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryGreen,
                      side: BorderSide(color: AppTheme.primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: _isAddingToCart 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shopping_cart_outlined),
                    label: Text(
                      _isAddingToCart ? 'Adding...' : 'Add to Cart',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              
              // Buy Now Button
              Expanded(
                flex: 2,
                child: Container(
                  height: 56,
                  margin: const EdgeInsets.only(left: 8),
                  child: ElevatedButton(
                    onPressed: _product!.stock > 0 ? _buyNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeableImageGallery() {
    final p = _product;
    if (p == null) return const SizedBox.shrink();
    if (_product == null) return Container();

    // Combine cover image and additional images
    final allImages = <String>[
      if (p.coverImageUrl.isNotEmpty) p.coverImageUrl,
      ...(p.additionalImageUrls ?? []),
    ];

    if (allImages.isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(
            Icons.image,
            size: 80,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Image PageView
        PageView.builder(
          controller: _imagePageController,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: allImages.length,
          itemBuilder: (context, index) {
            return Image.network(
              allImages[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                );
              },
            );
          },
        ),

        // Image indicators (only show if more than 1 image)
        if (allImages.length > 1) ...[
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: allImages.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ),

          // Image counter
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${allImages.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Navigation arrows (for larger screens)
          if (allImages.length > 1) ...[
            // Previous button
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    onPressed: _currentImageIndex > 0
                        ? () {
                            _imagePageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                ),
              ),
            ),
            
            // Next button
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                    onPressed: _currentImageIndex < allImages.length - 1
                        ? () {
                            _imagePageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildModernDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Product Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Category', _product!.category.toString().split('.').last),
          _buildDetailRow('Unit', _product!.unit),
          _buildShelfLifeRow(),
          _buildDetailRow('Location', _product!.storeLocation),
          if (_product!.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _product!.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernStoreCard() {
    final p = _product;
    if (p == null) return const SizedBox.shrink();
    
    // Get real store name with fallback priority
    String storeName = 'Farm Store';
    if (_farmerStoreData != null) {
      final customStoreName = _farmerStoreData!['store_name'];
      
      if (customStoreName != null && customStoreName.toString().trim().isNotEmpty) {
        storeName = customStoreName.toString().trim();
      } else {
        // Try farmer_verifications farm_name
        final verifications = _farmerStoreData!['farmer_verifications'];
        
        if (verifications is List && verifications.isNotEmpty) {
          final farmName = verifications.first['farm_name'];
          if (farmName != null && farmName.toString().trim().isNotEmpty) {
            storeName = farmName.toString().trim();
          }
        } else {
          // Fallback to "{full_name}'s Farm"
          final fullName = _farmerStoreData!['full_name'];
          if (fullName != null && fullName.toString().trim().isNotEmpty) {
            storeName = "${fullName.toString().trim()}'s Farm";
          }
        }
      }
    } else {
      if (p.farmName.isNotEmpty) {
        storeName = p.farmName;
      }
    }
    
    // Get store logo URL
    final storeLogoUrl = _farmerStoreData?['store_logo_url'] ?? _farmerStoreData?['avatar_url'];
    
    // Check if premium
    bool isPremium = false;
    if (_farmerStoreData != null) {
      final subscriptionTier = _farmerStoreData!['subscription_tier'] ?? 'free';
      if (subscriptionTier == 'premium') {
        final expiresAt = _farmerStoreData!['subscription_expires_at'];
        if (expiresAt == null) {
          isPremium = true;
        } else {
          final expiryDate = DateTime.tryParse(expiresAt);
          isPremium = expiryDate != null && expiryDate.isAfter(DateTime.now());
        }
      }
    }
    
    // Check if verified
    bool isVerified = false;
    if (_farmerStoreData != null) {
      final verifications = _farmerStoreData!['farmer_verifications'];
      if (verifications is List && verifications.isNotEmpty) {
        isVerified = verifications.first['status'] == 'approved';
      }
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Store Avatar/Logo
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: storeLogoUrl != null && storeLogoUrl.toString().isNotEmpty
                    ? CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: CachedNetworkImageProvider(storeLogoUrl.toString()),
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint('Error loading store logo: $exception');
                        },
                        child: Container(), // Empty container as fallback is handled by backgroundColor
                      )
                    : CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryGreen,
                        child: const Icon(
                          Icons.agriculture,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Store Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            storeName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 8),
                          PremiumBadge(
                            isPremium: true,
                            size: 14,
                            showLabel: true,
                          ),
                        ],
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 12,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.storeLocation ?? 'Unknown location',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Store Rating - using FutureBuilder to fetch from seller_reviews
                    FutureBuilder<Map<String, dynamic>>(
                      future: _fetchStoreRating(p.farmerId),
                      builder: (context, snapshot) {
                        double storeRating = 0.0;
                        int totalReviews = 0;
                        
                        if (snapshot.hasData) {
                          storeRating = snapshot.data!['average_rating'] ?? 0.0;
                          totalReviews = snapshot.data!['total_reviews'] ?? 0;
                        }
                        
                        return Row(
                          children: [
                            StarRatingDisplay(
                              rating: storeRating,
                              size: 14,
                              color: AppTheme.featuredGold,
                              emptyColor: Colors.grey.shade300,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              storeRating > 0 
                                  ? '${storeRating.toStringAsFixed(1)} ($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})'
                                  : 'No ratings yet',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _viewFarmerStore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: BorderSide(color: AppTheme.primaryGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.store, size: 18),
                  label: const Text('Visit Store'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _contactFarmer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade600,
                    side: BorderSide(color: Colors.blue.shade600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShelfLifeRow() {
    final p = _product;
    if (p == null) return Container();
    if (_product == null) return Container();

    final daysRemaining = p.daysUntilExpiry;
    final isExpired = p.isExpired;
    
    IconData statusIcon = Icons.schedule_outlined;
    String statusText = '';

    // Don't show shelf life info if product is expired
    if (isExpired) return const SizedBox.shrink();
    
    // Always use positive green color for freshness
    String badgeText = '';

    if (daysRemaining == 0) {
      statusIcon = Icons.spa_rounded;
      statusText = 'Best quality until today';
      badgeText = 'Order Today';
    } else if (daysRemaining == 1) {
      statusIcon = Icons.eco_rounded;
      statusText = 'Within peak freshness window';
      badgeText = 'Farm Fresh';
    } else if (daysRemaining <= 2) {
      statusIcon = Icons.eco_rounded;
      statusText = 'Within peak freshness window';
      badgeText = 'Farm Fresh';
    } else if (daysRemaining <= 5) {
      statusIcon = Icons.verified_rounded;
      statusText = 'Peak freshness guaranteed';
      badgeText = 'Quality Guaranteed';
    } else {
      statusIcon = Icons.verified_rounded;
      statusText = 'Freshly harvested';
      badgeText = 'Very Fresh';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Icon(
                  Icons.eco_rounded,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  'Freshness',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge with positive message
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 14,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.spa_rounded,
                        size: 14,
                        color: AppTheme.primaryGreen.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Best quality until ${_formatDate(_product!.expiryDate)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    // Validate month is in valid range (1-12)
    if (date.month < 1 || date.month > 12) {
      return date.toIso8601String().split('T')[0]; // Fallback to ISO format
    }
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToCart() async {
    if (_product == null || _product!.stock <= 0) return;

    setState(() => _isAddingToCart = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Check if item already exists in cart (proper e-commerce behavior)
      final existingItems = await Supabase.instance.client
          .from('cart')
          .select('id, quantity')
          .eq('user_id', user.id)
          .eq('product_id', _product!.id);

      if (existingItems.isNotEmpty) {
        // Item exists - update quantity by adding new quantity to existing
        final existingItem = existingItems.first;
        final newQuantity = existingItem['quantity'] + _quantity;
        
        await Supabase.instance.client
            .from('cart')
            .update({'quantity': newQuantity})
            .eq('id', existingItem['id']);
      } else {
        // Item doesn't exist - add new item
        await Supabase.instance.client.from('cart').insert({
          'user_id': user.id,
          'product_id': _product!.id,
          'quantity': _quantity,
        });
      }
      
      if (mounted) {
        // Update badge service with new cart count
        final badgeService = Provider.of<BadgeService>(context, listen: false);
        badgeService.loadCartCount();
        
        // Clear any existing SnackBars first
        ScaffoldMessenger.of(context).clearSnackBars();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Added $_quantity ${_product!.name} to cart!'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(milliseconds: 2500),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'VIEW CART',
              textColor: Colors.white,
              onPressed: () {
                context.go(RouteNames.cart);
              },
            ),
            dismissDirection: DismissDirection.horizontal,
          ),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  Future<void> _buyNow() async {
    if (_product == null || _product!.stock <= 0) return;

    // Add to cart and go to checkout
    await _addToCart();
    if (mounted) {
      // Wait briefly to show the snackbar, then navigate
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        context.go(RouteNames.cart);
      }
    }
  }

  void _viewFarmerStore() {
    if (_product == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublicFarmerProfileScreen(
          farmerId: _product!.farmerId,
        ),
      ),
    );
  }

  Future<void> _contactFarmer() async {
    if (_product == null) return;

    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to chat with the farmer.')),
      );
      context.go(RouteNames.login);
      return;
    }

    try {
      final chatService = ChatService();
      final conversation = await chatService.getOrCreateConversation(
        buyerId: authUser.id,
        farmerId: _product!.farmerId,
      );
      if (!mounted) return;
      final path = RouteNames.chatConversation.replaceAll(':conversationId', conversation.id);
      context.push(path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open chat: ${e.toString()}')),
      );
    }
  }

  void _shareProduct() {
    if (_product == null) return;
    
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share ${_product!.name}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _reportProduct() async {
    if (_product == null) return;
    
    final result = await showReportDialog(
      context,
      targetId: _product!.id,
      targetType: 'product',
      targetName: _product!.name,
    );
    
    if (result == true && mounted) {
      // Report submitted successfully - dialog already shows success message
    }
  }

  Widget _buildSimilarProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.store,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'You May Also Like',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (_similarProducts.length > 4)
                TextButton(
                  onPressed: _viewFarmerStore,
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Loading State
        if (_isLoadingSimilarProducts)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
            ),
          )
        
        // Empty State
        else if (_similarProducts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'No other products from this store',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          )
        
        // 2-Column Grid
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _similarProducts.length > 4 ? 4 : _similarProducts.length,
              itemBuilder: (context, index) {
                final product = _similarProducts[index];
                return ProductCard(
                  product: product,
                  showFarmInfo: false,
                  onTap: () {
                    // Navigate to product details
                    context.push('/product/${product.id}');
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductReviewsCard() {
    debugPrint('🔍 Building reviews card: ${_product!.recentReviews.length} reviews, Avg: ${_product!.averageRating}, Total: ${_product!.totalReviews}');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.featuredGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: AppTheme.featuredGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Customer Reviews',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (_product!.totalReviews > _product!.recentReviews.length)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to all reviews screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All reviews screen - Coming soon')),
                    );
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Reviews List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _product!.recentReviews.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final review = _product!.recentReviews[index];
              return _buildReviewItem(review);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ProductReview review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User info and rating
        Row(
          children: [
            // User avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: review.userAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        review.userAvatar!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            
            // User name and date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatReviewDate(review.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Rating stars
            StarRatingDisplay(
              rating: review.rating.toDouble(),
              size: 16,
              color: AppTheme.featuredGold,
              emptyColor: Colors.grey.shade400,
            ),
          ],
        ),
        
        // Review text
        if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            review.reviewText!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
        
        // Review images
        if (review.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: review.imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(
                          imageUrls: review.imageUrls,
                          initialIndex: index,
                          heroTag: 'review_${review.id}',
                        ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'review_${review.id}_$index',
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: review.imageUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    }
  }

  Future<void> _toggleFavorite() async {
    if (_product == null) return;

    setState(() => _isTogglingFavorite = true);

    try {
      // Toggle the favorite status
      final newFavoriteStatus = await _wishlistService.toggleFavorite(_product!.id);
      
      if (mounted) {
        setState(() {
          _isFavorite = newFavoriteStatus;
        });

        // Show feedback to user
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newFavoriteStatus ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    newFavoriteStatus 
                        ? 'Added to wishlist' 
                        : 'Removed from wishlist',
                  ),
                ),
              ],
            ),
            backgroundColor: newFavoriteStatus ? Colors.red.shade400 : Colors.grey.shade700,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            action: newFavoriteStatus
                ? SnackBarAction(
                    label: 'View Wishlist',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      context.push(RouteNames.wishlist);
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingFavorite = false);
      }
    }
  }
}