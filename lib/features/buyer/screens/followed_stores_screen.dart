import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/farmer_profile_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../core/models/followed_store_model.dart';

class FollowedStoresScreen extends StatefulWidget {
  const FollowedStoresScreen({super.key});

  @override
  State<FollowedStoresScreen> createState() => _FollowedStoresScreenState();
}

class _FollowedStoresScreenState extends State<FollowedStoresScreen> {
  final FarmerProfileService _farmerService = FarmerProfileService();
  final AuthService _authService = AuthService();

  List<FollowedStore> _followedStores = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadFollowedStores();
  }

  Future<void> _loadFollowedStores() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final stores = await _farmerService.getFollowedStores(currentUser.id);
      
      setState(() {
        _followedStores = stores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _unfollowStore(String sellerId) async {
    try {
      await _farmerService.toggleFollowSeller(sellerId, true); // true = currently following, so unfollow
      
      setState(() {
        _followedStores.removeWhere((store) => store.sellerId == sellerId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store unfollowed'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unfollow store: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followed Stores'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_followedStores.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_followedStores.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? ErrorMessage(
                  message: _error,
                  onRetry: _loadFollowedStores,
                )
              : _followedStores.isEmpty
                  ? _buildEmptyState()
                  : _buildStoresList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Followed Stores',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start following your favorite farmers and stores to stay updated on their latest products and offers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/home');
              },
              icon: const Icon(Icons.explore),
              label: const Text('Discover Stores'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoresList() {
    return RefreshIndicator(
      onRefresh: _loadFollowedStores,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _followedStores.length,
        itemBuilder: (context, index) {
          final store = _followedStores[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FollowedStoreCard(
              store: store,
              onUnfollow: () => _showUnfollowDialog(store),
              onVisit: () => context.push('/public-farmer/${store.sellerId}'),
            ),
          );
        },
      ),
    );
  }

  void _showUnfollowDialog(FollowedStore store) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unfollow Store'),
          content: Text(
            'Are you sure you want to unfollow "${store.storeName}"? You won\'t receive updates about their new products.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unfollowStore(store.sellerId);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Unfollow'),
            ),
          ],
        );
      },
    );
  }
}

class FollowedStoreCard extends StatelessWidget {
  final FollowedStore store;
  final VoidCallback onUnfollow;
  final VoidCallback onVisit;

  const FollowedStoreCard({
    super.key,
    required this.store,
    required this.onUnfollow,
    required this.onVisit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onVisit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Store Avatar/Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                      image: store.storeLogoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(store.storeLogoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: store.storeLogoUrl == null
                        ? Icon(
                            Icons.store,
                            size: 30,
                            color: AppTheme.primaryColor,
                          )
                        : null,
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
                                store.storeName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (store.isVerified)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.verified,
                                        color: Colors.blue,
                                        size: 12,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        if (store.location.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  store.location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],

                        Row(
                          children: [
                            if (store.averageRating > 0) ...[
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${store.averageRating.toStringAsFixed(1)} (${store.totalReviews})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],

                            Icon(
                              Icons.inventory,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                '${store.totalProducts} products',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Column(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 32,
                        child: OutlinedButton(
                          onPressed: onUnfollow,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Unfollow',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Store Description
              if (store.description.isNotEmpty) ...[
                Text(
                  store.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Bottom Info
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Followed ${_formatFollowDate(store.followedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: store.isStoreOpen 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: store.isStoreOpen ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          store.isStoreOpen ? 'Open' : 'Closed',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: store.isStoreOpen ? Colors.green : Colors.red,
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
      ),
    );
  }

  String _formatFollowDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = difference ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = difference ~/ 30;
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }
}

// Remove duplicate class definition since we imported it
// Removing duplicate class definition since we imported from model
/*
class FollowedStore {
  final String sellerId;
  final String sellerName;
  final String storeName;
  final String? storeLogoUrl;
  final String location;
  final String description;
  final bool isVerified;
  final bool isStoreOpen;
  final double averageRating;
  final int totalReviews;
  final int totalProducts;
  final DateTime followedAt;

  const FollowedStore({
    required this.sellerId,
    required this.sellerName,
    required this.storeName,
    this.storeLogoUrl,
    required this.location,
    required this.description,
    required this.isVerified,
    required this.isStoreOpen,
    required this.averageRating,
    required this.totalReviews,
    required this.totalProducts,
    required this.followedAt,
  });

  factory FollowedStore.fromJson(Map<String, dynamic> json) {
    final sellerData = json['users'] ?? {};
    final statsData = json['seller_statistics'] ?? {};
    
    return FollowedStore(
      sellerId: json['seller_id'] ?? '',
      sellerName: sellerData['full_name'] ?? '',
      storeName: sellerData['store_name'] ?? sellerData['full_name'] ?? 'Unknown Store',
      storeLogoUrl: sellerData['store_logo_url'] ?? sellerData['avatar_url'],
      location: '${sellerData['municipality'] ?? ''}, ${sellerData['barangay'] ?? ''}'
          .trim()
          .replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
      description: sellerData['store_description'] ?? '',
      isVerified: json['verification_status'] == 'approved',
      isStoreOpen: sellerData['is_store_open'] ?? true,
      averageRating: (statsData['average_rating'] ?? 0.0).toDouble(),
      totalReviews: statsData['total_reviews'] ?? 0,
      totalProducts: statsData['total_products'] ?? 0,
      followedAt: DateTime.parse(json['followed_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
*/