import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/review_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/models/order_model.dart';
import '../../../shared/widgets/custom_button.dart';

/// Enhanced review screen that allows rating individual products plus seller
class SubmitProductReviewScreen extends StatefulWidget {
  final String orderId;

  const SubmitProductReviewScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<SubmitProductReviewScreen> createState() => _SubmitProductReviewScreenState();
}

class _SubmitProductReviewScreenState extends State<SubmitProductReviewScreen> {
  final _reviewService = ReviewService();
  final _authService = AuthService();
  final _orderService = OrderService();
  final _formKey = GlobalKey<FormState>();
  final _sellerReviewController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  OrderModel? _order;
  bool _isLoading = true;
  
  // Product ratings: productId -> {rating, reviewController, images}
  Map<String, Map<String, dynamic>> _productRatings = {};
  
  // Seller rating
  int _sellerRating = 0;
  bool _isSubmitting = false;
  
  // Word count limits
  static const int _maxWords = 100;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _sellerReviewController.dispose();
    // Dispose all product review controllers
    for (var rating in _productRatings.values) {
      (rating['reviewController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _orderService.getOrderById(widget.orderId);
      
      // Initialize product ratings
      final productRatings = <String, Map<String, dynamic>>{};
      if (order?.items != null) {
        for (var item in order!.items) {
          productRatings[item.productId] = {
            'rating': 0,
            'reviewController': TextEditingController(),
            'productName': item.productName,
            'images': <File>[],
          };
        }
      }
      
      setState(() {
        _order = order;
        _productRatings = productRatings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    // Validate all products are rated
    final unratedProducts = _productRatings.entries
        .where((entry) => entry.value['rating'] == 0)
        .toList();
    
    if (unratedProducts.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate all products'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate seller rating
    if (_sellerRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please rate the seller'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate low ratings have text
    for (var entry in _productRatings.entries) {
      final rating = entry.value['rating'] as int;
      final controller = entry.value['reviewController'] as TextEditingController;
      final error = _validateReviewText(controller.text, rating);
      
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    // Validate seller review text for low ratings
    final sellerError = _validateReviewText(_sellerReviewController.text, _sellerRating);
    if (sellerError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seller review: $sellerError'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Prepare product reviews with images
      List<ProductReviewSubmission> productReviews = _productRatings.entries
          .map((entry) {
            final controller = entry.value['reviewController'] as TextEditingController;
            final images = entry.value['images'] as List<File>;
            return ProductReviewSubmission(
              productId: entry.key,
              rating: entry.value['rating'] as int,
              reviewText: controller.text.trim().isEmpty ? null : controller.text.trim(),
              images: images,
            );
          })
          .toList();

      // Submit complete review (products + seller)
      await _reviewService.submitCompleteReview(
        orderId: widget.orderId,
        buyerId: currentUser.id,
        sellerId: _order!.farmerId,
        productReviews: productReviews,
        sellerRating: _sellerRating,
        sellerReviewText: _sellerReviewController.text.trim().isEmpty 
            ? null 
            : _sellerReviewController.text.trim(),
        sellerReviewType: 'general',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate review was submitted
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        const Text(
                          'How was your experience?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Your feedback helps farmers improve their products and service',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Product Reviews Section
                        _buildProductReviewsSection(),
                        
                        const SizedBox(height: AppSpacing.xl),
                        const Divider(),
                        const SizedBox(height: AppSpacing.xl),

                        // Seller Review Section
                        _buildSellerReviewSection(),

                        const SizedBox(height: AppSpacing.xl),

                        // Submit Button
                        CustomButton(
                          text: _isSubmitting ? 'Submitting...' : 'Submit Review',
                          onPressed: _isSubmitting ? null : _submitReview,
                          width: double.infinity,
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProductReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.shopping_basket, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Rate Your Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ..._productRatings.entries.map((entry) {
          return _buildProductRatingCard(
            productId: entry.key,
            productName: entry.value['productName'] as String,
            rating: entry.value['rating'] as int,
            controller: entry.value['reviewController'] as TextEditingController,
          );
        }),
      ],
    );
  }

  Widget _buildProductRatingCard({
    required String productId,
    required String productName,
    required int rating,
    required TextEditingController controller,
  }) {
    final images = _productRatings[productId]!['images'] as List<File>;
    final wordCount = _countWords(controller.text);
    final errorText = _validateReviewText(controller.text, rating);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Star rating
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _productRatings[productId]!['rating'] = index + 1;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Review text field with validation
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: rating <= 2 && rating > 0 
                    ? 'Please explain your rating (required)' 
                    : 'Tell us about this product (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
                errorText: errorText,
                helperText: '$wordCount / $_maxWords words',
                helperStyle: TextStyle(
                  color: wordCount > _maxWords ? Colors.red : Colors.grey,
                ),
              ),
              maxLines: 3,
              onChanged: (value) {
                setState(() {}); // Refresh word count
              },
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Photo upload section
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: images.length < 5 ? () => _pickImages(productId) : null,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(images.isEmpty ? 'Add Photos' : 'Add More Photos'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${images.length}/5',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            // Display selected images
            if (images.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              images[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: 0,
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () => _removeImage(productId, index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSellerReviewSection() {
    final wordCount = _countWords(_sellerReviewController.text);
    final errorText = _validateReviewText(_sellerReviewController.text, _sellerRating);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.store, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Rate the Seller',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _order?.farmerProfile?.fullName ?? 'Seller',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Seller star rating
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _sellerRating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 36,
              ),
              onPressed: () {
                setState(() {
                  _sellerRating = index + 1;
                });
              },
            );
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _sellerReviewController,
          decoration: InputDecoration(
            hintText: _sellerRating <= 2 && _sellerRating > 0
                ? 'Please explain your rating (required)'
                : 'Share your experience with this seller (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
            errorText: errorText,
            helperText: '$wordCount / $_maxWords words',
            helperStyle: TextStyle(
              color: wordCount > _maxWords ? Colors.red : Colors.grey,
            ),
          ),
          maxLines: 4,
          onChanged: (value) {
            setState(() {}); // Refresh word count
          },
        ),
      ],
    );
  }

  // Helper method to count words
  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  // Helper method to validate text based on rating
  String? _validateReviewText(String? value, int rating) {
    if (rating > 0 && rating <= 2) {
      // Require text for low ratings (1-2 stars)
      if (value == null || value.trim().isEmpty) {
        return 'Please explain your low rating';
      }
    }
    
    if (value != null && value.trim().isNotEmpty) {
      final wordCount = _countWords(value);
      if (wordCount > _maxWords) {
        return 'Review must be $wordCount words or less (currently $wordCount words)';
      }
    }
    
    return null;
  }

  // Pick images for product review
  Future<void> _pickImages(String productId) async {
    // Show compression quality dialog
    final quality = await _showCompressionDialog();
    if (quality == null) return;
    
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: quality['maxWidth']!.toDouble(),
        maxHeight: quality['maxHeight']!.toDouble(),
        imageQuality: quality['quality'],
      );
      
      if (images.isNotEmpty) {
        final currentImages = _productRatings[productId]!['images'] as List<File>;
        final totalImages = currentImages.length + images.length;
        
        if (totalImages > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 5 images allowed per product'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        setState(() {
          currentImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove image from product review
  void _removeImage(String productId, int index) {
    setState(() {
      final images = _productRatings[productId]!['images'] as List<File>;
      images.removeAt(index);
    });
  }

  // Show compression options dialog
  Future<Map<String, int>?> _showCompressionDialog() async {
    return await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose image quality for upload:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('High Quality'),
              subtitle: const Text('Best quality, larger file size'),
              leading: const Icon(Icons.high_quality, color: Colors.green),
              onTap: () => Navigator.pop(context, {
                'quality': 95,
                'maxWidth': 1920,
                'maxHeight': 1920,
              }),
            ),
            ListTile(
              title: const Text('Standard Quality'),
              subtitle: const Text('Good balance (Recommended)'),
              leading: const Icon(Icons.image, color: Colors.blue),
              onTap: () => Navigator.pop(context, {
                'quality': 85,
                'maxWidth': 1200,
                'maxHeight': 1200,
              }),
            ),
            ListTile(
              title: const Text('Lower Quality'),
              subtitle: const Text('Faster upload, smaller file'),
              leading: const Icon(Icons.data_saver_on, color: Colors.orange),
              onTap: () => Navigator.pop(context, {
                'quality': 70,
                'maxWidth': 800,
                'maxHeight': 800,
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
