import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/supabase_service.dart';

class ExpiredProductsScreen extends StatefulWidget {
  const ExpiredProductsScreen({super.key});

  @override
  State<ExpiredProductsScreen> createState() => _ExpiredProductsScreenState();
}

class _ExpiredProductsScreenState extends State<ExpiredProductsScreen> {
  final ProductService _productService = ProductService();
  final SupabaseService _supabase = SupabaseService.instance;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _expiredProducts = [];
  List<ProductModel> _deletedProducts = [];
  List<ProductModel> _hiddenProducts = [];
  List<ProductModel> _availableProducts = [];

  @override
  void initState() {
    super.initState();
    _loadExpiredProducts();
  }

  Future<void> _loadExpiredProducts() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.currentUser?.id;
      if (userId == null) return;

      final expired = await _productService.getExpiredProducts(userId);
      final deleted = await _productService.getDeletedProducts(userId);
      final hidden = await _productService.getHiddenProducts(userId);
      final available = await _productService.getAvailableProductsForFarmer(userId);

      setState(() {
        _expiredProducts = expired;
        _deletedProducts = deleted;
        _hiddenProducts = hidden;
        _availableProducts = available;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _productService.deleteProduct(productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _loadExpiredProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _restoreProduct(String productId) async {
    try {
      await _productService.restoreProduct(productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product restored successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _loadExpiredProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
  
  Future<void> _toggleVisibility(ProductModel product) async {
    try {
      await _productService.toggleProductVisibility(product.id);
      if (mounted) {
        final newStatus = !product.isHidden ? 'hidden' : 'visible';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product is now $newStatus'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _loadExpiredProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle visibility: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExpiredProducts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Product Management',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Available: Active products visible to buyers\n'
                            '• Hidden: Products you manually hid from buyers\n'
                            '• Expired: Products past shelf life (auto-hidden)\n'
                            '• Deleted: Soft-deleted products (can restore if not expired)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Expired Products Section
                    _buildSectionHeader(
                      'Expired Products',
                      _expiredProducts.length,
                      Icons.warning_amber_rounded,
                      AppTheme.errorRed,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_expiredProducts.isEmpty)
                      _buildEmptyState('No expired products', Icons.check_circle_outline)
                    else
                      ..._expiredProducts.map((product) => _buildExpiredProductCard(product)),

                    const SizedBox(height: AppSpacing.lg),

                    // Available Products Section
                    _buildSectionHeader(
                      'Available Products',
                      _availableProducts.length,
                      Icons.check_circle,
                      AppTheme.successGreen,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_availableProducts.isEmpty)
                      _buildEmptyState('No available products', Icons.inventory_2_outlined)
                    else
                      ..._availableProducts.map((product) => _buildAvailableProductCard(product)),

                    const SizedBox(height: AppSpacing.lg),

                    // Hidden Products Section
                    _buildSectionHeader(
                      'Hidden Products',
                      _hiddenProducts.length,
                      Icons.visibility_off,
                      Colors.orange,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_hiddenProducts.isEmpty)
                      _buildEmptyState('No hidden products', Icons.check_circle_outline)
                    else
                      ..._hiddenProducts.map((product) => _buildHiddenProductCard(product)),

                    const SizedBox(height: AppSpacing.lg),

                    // Deleted Products Section
                    _buildSectionHeader(
                      'Deleted Products',
                      _deletedProducts.length,
                      Icons.delete_outline,
                      Colors.grey,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_deletedProducts.isEmpty)
                      _buildEmptyState('No deleted products', Icons.check_circle_outline)
                    else
                      ..._deletedProducts.map((product) => _buildDeletedProductCard(product)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredProductCard(Map<String, dynamic> product) {
    final productId = product['product_id'] as String;
    final productName = product['product_name'] as String;
    final daysSinceExpired = product['days_since_expired'] as int;
    final expiredDate = DateTime.parse(product['expired_date'] as String);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.errorRed,
          child: Icon(Icons.warning, color: Colors.white),
        ),
        title: Text(
          productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expired: ${_formatDate(expiredDate)}'),
            Text(
              '$daysSinceExpired days ago',
              style: const TextStyle(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_forever, color: AppTheme.errorRed),
          onPressed: () => _confirmDelete(productId, productName),
        ),
      ),
    );
  }

  Widget _buildDeletedProductCard(ProductModel product) {
    final canRestore = !product.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(Icons.delete, color: Colors.white),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deleted: ${_formatDate(product.deletedAt!)}'),
            if (product.isExpired)
              const Text(
                'Cannot restore - product expired',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: canRestore
            ? IconButton(
                icon: const Icon(Icons.restore, color: AppTheme.successGreen),
                onPressed: () => _confirmRestore(product.id, product.name),
              )
            : const Icon(Icons.block, color: Colors.grey),
      ),
    );
  }

  Widget _buildAvailableProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.successGreen,
          child: const Icon(Icons.check_circle, color: Colors.white),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: ₱${product.price.toStringAsFixed(2)}'),
            Text('Stock: ${product.stock} ${product.unit}'),
            if (product.isExpiringWithin3Days)
              Text(
                'Expiring in ${product.daysUntilExpiry} days',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility_off, color: Colors.orange),
          tooltip: 'Hide product',
          onPressed: () => _confirmToggleVisibility(product, true),
        ),
      ),
    );
  }

  Widget _buildHiddenProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.visibility_off, color: Colors.white),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: ₱${product.price.toStringAsFixed(2)}'),
            Text('Stock: ${product.stock} ${product.unit}'),
            const Text(
              'Hidden from buyers',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility, color: AppTheme.successGreen),
          tooltip: 'Make visible',
          onPressed: () => _confirmToggleVisibility(product, false),
        ),
      ),
    );
  }

  void _confirmDelete(String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to permanently delete "$productName"?\n\n'
          'This will hide the product from your inventory. Products with existing orders cannot be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(productId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Product'),
        content: Text(
          'Restore "$productName" to your active products?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restoreProduct(productId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmToggleVisibility(ProductModel product, bool willHide) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(willHide ? 'Hide Product' : 'Show Product'),
        content: Text(
          willHide
              ? 'Hide "${product.name}" from buyers? You can make it visible again later.'
              : 'Make "${product.name}" visible to buyers?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleVisibility(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: willHide ? Colors.orange : AppTheme.successGreen,
            ),
            child: Text(willHide ? 'Hide' : 'Show'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
