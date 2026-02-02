import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/models/product_model.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/product_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/error_widgets.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  
  ProductModel? _product;
  Map<String, dynamic>? _farmer;
  bool _isLoading = true;
  String? _error;
  int _quantity = 1;
  bool _isAddingToCart = false;
  final bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final product = await _productService.getProductById(widget.productId);
      _product = product;

      if (product != null) {
        // wishlist placeholder (reverted)
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    if (_product == null) return;

    setState(() => _isAddingToCart = true);

    try {
      await _cartService.addToCart(
        productId: _product!.id,
        quantity: _quantity,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to cart successfully!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorWidget(_error!)
              : _product == null
                  ? const Center(
                      child: Text('Product not found'),
                    )
                  : _buildProductDetails(),
    );
  }

  Widget _buildProductDetails() {
    final p = _product;
    if (p == null) return const SizedBox.shrink();
    return CustomScrollView(
      slivers: [
        // App bar with product images
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppTheme.backgroundWhite,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite_border, color: AppTheme.textPrimary),
              onPressed: () {
                // Add to favorites functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to favorites!')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share, color: AppTheme.textPrimary),
              onPressed: () {
                // Share product functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing feature coming soon!')),
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: AppTheme.lightGrey,
              child: p.coverImageUrl.isNotEmpty
                  ? Image.network(
                      p.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                    ),
            ),
          ),
        ),

        // Product details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Price and unit
                Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '₱${p.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        'per ${p.unit}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Farmer info
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.lightGrey),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.primaryGreen,
                        child: const Icon(Icons.agriculture, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.farmName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Text(
                              'Verified Farmer',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.successGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () => _viewFarmerStore(),
                            icon: const Icon(Icons.store, size: 16),
                            label: const Text('Store'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            onPressed: () => _contactFarmer(),
                            icon: const Icon(Icons.chat, size: 16),
                            label: const Text('Chat'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Description
                if (p.description.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    p.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Product details
                const Text(
                  'Product Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildDetailRow('Category', p.category.toString().split('.').last),
                _buildDetailRow('Unit', p.unit),
                _buildDetailRow('Stock', '${p.stock} available'),
                _buildDetailRow('Location', 
                  p.storeLocation,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Quantity selector
                Row(
                  children: [
                    const Text(
                      'Quantity:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _quantity > 1 
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove),
                            color: AppTheme.textSecondary,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _quantity < p.stock
                                ? () => setState(() => _quantity++)
                                : null,
                            icon: const Icon(Icons.add),
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Add to cart button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isAddingToCart 
                        ? 'Adding...' 
                        : 'Add to Cart • ₱${(p.price * _quantity).toStringAsFixed(2)}',
                    onPressed: _isAddingToCart ? null : _addToCart,
                    isLoading: _isAddingToCart,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
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

  // View Farmer Store Method
  void _viewFarmerStore() {
    final p = _product;
    if (p == null) return;
    context.push('/public-farmer/${p.farmerId}');
  }

  // Contact Farmer Method
  void _contactFarmer() {
    if (_product == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Farmer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat,
              size: 64,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 16),
            Text(
              'Would you like to start a conversation with the farmer?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You can ask about the product, availability, or any other questions.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final p = _product;
              if (p != null) {
                context.push('${RouteNames.chatConversation}/${p.farmerId}');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }
}