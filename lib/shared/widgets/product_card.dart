import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/product_model.dart';
import '../../core/router/route_names.dart';
import '../../core/services/wishlist_service.dart';
import '../widgets/star_rating_display.dart';
import 'premium_badge.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool showFarmInfo;
  final bool showActions;
  final bool showFavorite;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.showFarmInfo = true,
    this.showActions = false,
    this.showFavorite = true,
    this.isFavorite = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  final WishlistService _wishlistService = WishlistService();
  bool _isFavorite = false;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _loadFavoriteStatus();
    
    // Debug: Log what the product card receives
    if (widget.product.id == 'fd7de843-52ba-417a-bf5c-4ccd636fcb23') {
      debugPrint('🎴 ProductCard for ${widget.product.name}:');
      debugPrint('   - Rating: ${widget.product.averageRating}');
      debugPrint('   - Reviews: ${widget.product.totalReviews}');
      debugPrint('   - Sold: ${widget.product.totalSold}');
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFav = await _wishlistService.isFavorite(widget.product.id);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    } catch (e) {
      // Silently fail - not critical for card display
      debugPrint('Error loading favorite status: $e');
    }
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      context.push(RouteNames.productDetails.replaceAll(':id', widget.product.id));
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;

    setState(() => _isTogglingFavorite = true);

    try {
      final newStatus = await _wishlistService.toggleFavorite(widget.product.id);
      
      if (mounted) {
        setState(() {
          _isFavorite = newStatus;
          _isTogglingFavorite = false;
        });

        // Show quick feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Added to wishlist' : 'Removed from wishlist',
            ),
            backgroundColor: newStatus ? Colors.red.shade400 : Colors.grey.shade700,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Call parent callback if provided
        widget.onFavorite?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTogglingFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(AppBorderRadius.large),
          border: Border.all(
            color: AppTheme.lightGrey,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppBorderRadius.large),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppBorderRadius.large),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: widget.product.coverImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.lightGrey,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.lightGrey,
                          child: const Center(
                            child: Icon(
                              Icons.agriculture,
                              color: AppTheme.primaryGreen,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Premium Badge - Top Left (below fresh badge if present)
                  if (widget.product.farmerIsPremium)
                    Positioned(
                      top: widget.product.isExpired ? AppSpacing.sm : AppSpacing.sm + 32,
                      left: AppSpacing.sm,
                      child: PremiumBadge(
                        isPremium: true,
                        size: 12,
                        showLabel: false,
                      ),
                    ),
                  
                  // Favorite button
                  if (widget.showFavorite)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: GestureDetector(
                        onTap: _isTogglingFavorite ? null : _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.cardWhite.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.textPrimary.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isTogglingFavorite
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.errorRed,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _isFavorite ? Icons.favorite : Icons.favorite_outline,
                                  color: _isFavorite ? AppTheme.errorRed : AppTheme.neutralGrey,
                                  size: 16,
                                ),
                        ),
                      ),
                    ),

                  // Freshness badge - Based on shelf life
                  if (!widget.product.isExpired)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: _buildFreshnessBadge(),
                    ),
                ],
              ),
            ),
            
            // Product Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      widget.product.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Price and rating row
                    Row(
                      children: [
                        // Price with unit - takes priority space
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '₱${widget.product.price.toStringAsFixed(2)}',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                TextSpan(
                                  text: '/${widget.product.unit}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.neutralGrey,
                                  ),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        const SizedBox(width: 4),
                        
                        // Rating with compact display - shrinks if needed
                        if (widget.product.averageRating > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.product.averageRating.toStringAsFixed(1),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppTheme.neutralGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppTheme.featuredGold,
                              ),
                            ],
                          )
                        else
                          Text(
                            'No rating',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppTheme.neutralGrey,
                            ),
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

  /// Build freshness badge based on days until expiry
  Widget _buildFreshnessBadge() {
    final daysRemaining = widget.product.daysUntilExpiry;
    
    String badgeText;
    IconData badgeIcon;
    Color badgeColor;
    
    // Badge system based on shelf life documentation - Shortened for space
    if (daysRemaining == 0) {
      badgeText = 'Today';
      badgeIcon = Icons.spa_rounded;
      badgeColor = const Color(0xFF2E7D32); // Dark green for urgency
    } else if (daysRemaining <= 2) {
      badgeText = 'Fresh';
      badgeIcon = Icons.eco_rounded;
      badgeColor = const Color(0xFF388E3C); // Medium green
    } else if (daysRemaining <= 5) {
      badgeText = 'Quality';
      badgeIcon = Icons.verified_rounded;
      badgeColor = AppTheme.successGreen; // Standard green
    } else {
      badgeText = 'Very Fresh';
      badgeIcon = Icons.local_florist_rounded;
      badgeColor = const Color(0xFF66BB6A); // Light green
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}