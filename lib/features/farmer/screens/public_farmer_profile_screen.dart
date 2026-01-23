import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../chat/services/chat_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/farmer_profile_service.dart';
import '../../../core/services/product_service.dart';
import '../../../core/models/seller_store_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/seller_store_widgets.dart';
import '../../../shared/widgets/star_rating_display.dart';
import '../../../core/models/product_model.dart' hide ProductCategory;
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../shared/widgets/premium_badge.dart';

class PublicFarmerProfileScreen extends StatefulWidget {
  final String farmerId;

  const PublicFarmerProfileScreen({super.key, required this.farmerId});

  @override
  State<PublicFarmerProfileScreen> createState() =>
      _PublicFarmerProfileScreenState();
}

class _PublicFarmerProfileScreenState extends State<PublicFarmerProfileScreen>
    with SingleTickerProviderStateMixin {
  final FarmerProfileService _farmerService = FarmerProfileService();
  final ProductService _productService = ProductService();

  SellerStore? _store;
  List<ProductModel> _featuredProducts = [];
  List<String> _categories = [];
  String? _selectedCategory;
  List<ProductModel> _categoryProducts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  String _error = '';
  FarmInformation? _farmInfo;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStoreData();
  }

  // Helper method to extract categories from products
  List<String> _extractCategoriesFromProducts(
    List<ProductModel> products,
  ) {
    final Set<String> categoryStrings = {};
    for (final product in products) {
      final categoryStr = product.category.name;
      categoryStrings.add(categoryStr);
    }
    return categoryStrings.toList();
  }

  // Helper method to count products per category
  int _getProductCountForCategory(String category) {
    return _featuredProducts.where((product) {
      return product.category.name == category;
    }).length;
  }

  // Helper methods for category styling
  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return '🥬';
      case 'fruits':
        return '🍎';
      case 'grains':
        return '🌾';
      case 'herbs':
        return '🌿';
      case 'roots':
        return '🥕';
      default:
        return '🌱';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables':
        return Colors.green;
      case 'fruits':
        return Colors.orange;
      case 'grains':
        return Colors.amber;
      case 'herbs':
        return Colors.teal;
      case 'roots':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    try {
      // Load data with proper error handling
      SellerStore? store;
      List<ProductModel> featuredProducts = [];
      bool isFollowing = false;

      try {
        store = await _farmerService.getSellerStore(widget.farmerId);
      } catch (e) {
        print('⚠️ Failed to load seller store: $e');
        // Create a basic store from user data
        store = await _createBasicStore();
      }

      try {
        // Use ProductService to get products with ratings
        final allProducts = await _productService.getAvailableProducts();
        featuredProducts = allProducts
            .where((p) => p.farmerId == widget.farmerId)
            .take(6)
            .toList();
      } catch (e) {
        print('⚠️ Failed to load featured products: $e');
        featuredProducts = [];
      }

      try {
        isFollowing = await _farmerService.isFollowingSeller(widget.farmerId);
      } catch (e) {
        print('⚠️ Failed to check follow status: $e');
        isFollowing = false;
      }

      // Load farm information
      FarmInformation? farmInfo;
      try {
        farmInfo = await _farmerService.getFarmInformation(widget.farmerId);
      } catch (e) {
        print('⚠️ Failed to load farm information: $e');
        farmInfo = null;
      }

      final categories = _extractCategoriesFromProducts(featuredProducts);

      if (mounted) {
        setState(() {
          _store = store;
          _featuredProducts = featuredProducts;
          _isFollowing = isFollowing;
          _categories = categories;
          _farmInfo = farmInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading store data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load farmer store information';
          _isLoading = false;
        });
      }
    }
  }

  // Create a basic store when full data is not available
  Future<SellerStore> _createBasicStore() async {
    try {
      final client = SupabaseService.instance.client;

      // Get user data with store customization and farm verification info
      final userResponse = await client
          .from('users')
          .select('''
            id, full_name, store_name, store_description, store_message, business_hours, is_store_open,
            store_banner_url, store_logo_url, municipality, barangay, avatar_url, created_at,
            farmer_verifications!farmer_verifications_farmer_id_fkey (
              farm_name, farm_address, farm_details
            )
          ''')
          .eq('id', widget.farmerId)
          .single();

      // Priority order for store name: store_name (from store customization) > farm_name (from verification) > "{full_name}'s Farm"
      String storeName = 'Farmer Store';
      String farmerName =
          userResponse['full_name']?.toString().trim() ?? 'Farmer';

      // First priority: store customization store name
      final customStoreName = userResponse['store_name']?.toString().trim();
      if (customStoreName != null && customStoreName.isNotEmpty) {
        storeName = customStoreName;
      } else {
        // Second priority: farm name from verification
        final verifications = userResponse['farmer_verifications'] as List?;
        if (verifications?.isNotEmpty == true) {
          final farmName = verifications!.first['farm_name'];
          if (farmName != null && farmName.toString().trim().isNotEmpty) {
            storeName = farmName.toString().trim();
          }
        }

        // Final fallback: "{farmer_name}'s Farm"
        if (storeName == 'Farmer Store') {
          storeName = "$farmerName's Farm";
        }
      }

      // Create basic store data
      return SellerStore.fromBasicData({
        'id': userResponse['id'],
        'store_name': storeName,
        'description':
            userResponse['store_description'] ??
            'Fresh agricultural products from our farm.',
        'owner_name': userResponse['full_name'] ?? 'Farmer',
        'location':
            '${userResponse['municipality'] ?? ''}, ${userResponse['barangay'] ?? ''}',
        'avatar_url': userResponse['avatar_url'],
        'created_at': userResponse['created_at'],
      });
    } catch (e) {
      print('❌ Failed to create basic store: $e');
      throw Exception('Unable to load farmer information');
    }
  }

  Future<void> _toggleFollow() async {
    try {
      await _farmerService.toggleFollowSeller(widget.farmerId, _isFollowing);
      setState(() {
        _isFollowing = !_isFollowing;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFollowing ? 'Following this store!' : 'Unfollowed store',
          ),
          backgroundColor: _isFollowing ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update follow status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadCategoryProducts(String category) async {
    setState(() {
      _selectedCategory = category;
      _categoryProducts = [];
    });

    try {
      // Filter featured products by category
      final products = _featuredProducts.where((p) => p.category.name == category).toList();

      if (mounted) {
        setState(() {
          _categoryProducts = products;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load products: $e')));
    }
  }

  void _startChat() {
    // TODO: Navigate to chat screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Chat feature coming soon!')));
  }

  Future<void> _reportUser() async {
    if (_store == null) return;
    
    final result = await showReportDialog(
      context,
      targetId: widget.farmerId,
      targetType: 'user',
      targetName: _store!.ownerName,
    );
    
    if (result == true && mounted) {
      // Report submitted successfully
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Store'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Store'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: ErrorMessage(message: _error, onRetry: _loadStoreData),
        ),
      );
    }

    if (_store == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Store'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: Text('Store not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: AppTheme.errorRed, size: 20),
                          SizedBox(width: 8),
                          Text('Report User'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'report') {
                      _reportUser();
                    }
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildStoreHeader(),
                collapseMode: CollapseMode.parallax,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryColor,
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Home', icon: Icon(Icons.home, size: 18)),
                      Tab(
                        text: 'Products',
                        icon: Icon(Icons.grid_view, size: 18),
                      ),
                      Tab(text: 'About', icon: Icon(Icons.info, size: 18)),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [_buildHomeTab(), _buildProductsTab(), _buildAboutTab()],
        ),
      ),
    );
  }

  // Home Tab - Store overview with featured products and stats
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadStoreData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Store Statistics
            _buildStoreStats(),
            // Store Rating
            _buildStoreRating(),
            // Product Categories
            if (_categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildProductCategories(),
              const SizedBox(height: 24),
            ],
            // Featured Products
            if (_featuredProducts.isNotEmpty) ...[
              _buildSectionHeader('Featured Products', 'View All', () {
                _tabController.animateTo(1);
              }),
              const SizedBox(height: 12),
              _buildFeaturedProducts(),
              const SizedBox(height: 24),
            ],
            // Store Policies
            _buildStorePolicies(),
            const SizedBox(height: 80), // Bottom padding
          ],
        ),
      ),
    );
  }

  // Products Tab - Browse all products with category filtering
  Widget _buildProductsTab() {
    return Column(
      children: [
        if (_categories.isNotEmpty) ...[
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: ProductCategories(
              categories: _categories
                  .map(
                    (catStr) => ProductCategory(
                      name: catStr,
                      icon: _getCategoryIcon(catStr),
                      productCount: _getProductCountForCategory(catStr),
                      color: _getCategoryColor(catStr),
                    ),
                  )
                  .toList(),
              onCategoryTap: (category) => _loadCategoryProducts(category.name),
            ),
          ),
          const Divider(height: 1),
        ],

        Expanded(
          child: _selectedCategory != null
              ? _buildCategoryProducts()
              : _buildAllProducts(),
        ),
      ],
    );
  }

  // About Tab - Store information and policies
  Widget _buildAboutTab() {
    return RefreshIndicator(
      onRefresh: _loadStoreData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStoreDescription(),
            const SizedBox(height: 24),
            _buildFarmInformation(),
            const SizedBox(height: 24),
            _buildStoreDetails(),
            const SizedBox(height: 24),
            _buildContactInformation(),
          ],
        ),
      ),
    );
  }

  // Section header with title and action button
  Widget _buildSectionHeader(
    String title,
    String actionText,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              actionText,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Featured products horizontal scroll
  Widget _buildFeaturedProducts() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _featuredProducts.length,
        itemBuilder: (context, index) {
          final product = _featuredProducts[index];
          return Container(
            width: 160,
            margin: EdgeInsets.only(
              right: index < _featuredProducts.length - 1 ? 12 : 0,
            ),
            child: ProductCard(
              product: product,
              onTap: () {
                context.push('/buyer/product/${product.id}');
              },
            ),
          );
        },
      ),
    );
  }

  // Store policies and guarantees
  Widget _buildStorePolicies() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Store Guarantees',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._store!.settings.shippingMethods
              .map((method) => _buildPolicyItem(Icons.local_shipping, method))
              ,
          ..._store!.settings.paymentMethods.entries
              .where((entry) => entry.value)
              .map((entry) => _buildPolicyItem(Icons.payment, entry.key))
              ,
          _buildPolicyItem(Icons.verified_user, 'Fresh Quality Guaranteed'),
          _buildPolicyItem(Icons.support_agent, 'Customer Support Available'),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // All products grid
  Widget _buildAllProducts() {
    if (_featuredProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No products available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _featuredProducts.length,
      itemBuilder: (context, index) {
        final product = _featuredProducts[index];
        return ProductCard(
          product: product,
          onTap: () {
            context.push('/buyer/product/${product.id}');
          },
        );
      },
    );
  }

  // Category-filtered products
  Widget _buildCategoryProducts() {
    if (_categoryProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No products in this category',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categoryProducts.length,
      itemBuilder: (context, index) {
        final product = _categoryProducts[index];
        return ProductCard(
          product: product,
          onTap: () {
            context.push('/buyer/product/${product.id}');
          },
        );
      },
    );
  }

  // Store description and about section
  Widget _buildStoreDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Store',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _store!.description,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          if (_store!.settings.storeMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.campaign, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _store!.settings.storeMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Store details and information
  Widget _buildStoreDetails() {
    final joinDate = _store!.joinDate;
    final formattedDate = '${joinDate.month}/${joinDate.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Store Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Owner', _store!.ownerName),
          const SizedBox(height: 8),
          _buildInfoRow('Store Name', _store!.storeName),
          const SizedBox(height: 8),
          _buildInfoRow('Location', _store!.location),
          const SizedBox(height: 8),
          _buildInfoRow('Joined', 'Since $formattedDate'),
          const SizedBox(height: 8),
          _buildInfoRow('Business Hours', _store!.settings.businessHours),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 120,
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _store!.settings.isStoreOpen
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
                        color: _store!.settings.isStoreOpen
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _store!.settings.isStoreOpen ? 'Open' : 'Closed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _store!.settings.isStoreOpen
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Contact information and actions
  Widget _buildContactInformation() {
    Future<void> startChat() async {
      try {
        final currentUser = SupabaseService.instance.client.auth.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to start a chat')),
          );
          return;
        }
        final farmerId = _store?.id;
        if (farmerId == null || farmerId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to start chat: missing store id')),
          );
          return;
        }
        // Create or get conversation then navigate
        final conversation = await ChatService().getOrCreateConversation(
          buyerId: currentUser.id,
          farmerId: farmerId,
        );
        final path = RouteNames.chatConversation.replaceAll(':conversationId', conversation.id);
        context.push(path);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact & Support',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: startChat,
                  icon: const Icon(Icons.chat, size: 20),
                  label: const Text('Start Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
               child: OutlinedButton.icon(
                 onPressed: () async {
                   final phone = _store?.phoneNumber;
                   if (phone != null && phone.isNotEmpty) {
                     final uri = Uri(scheme: 'tel', path: phone);
                     if (await canLaunchUrl(uri)) {
                       await launchUrl(uri);
                     } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Unable to launch dialer')),
                       );
                     }
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('No phone number available')),
                     );
                   }
                 },
                 icon: const Icon(Icons.phone, size: 20),
                 label: const Text('Call Store'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
         if (_store?.phoneNumber != null && _store!.phoneNumber!.isNotEmpty)
           _buildInfoRow('Phone', _store!.phoneNumber!),
         if (_store?.email != null && _store!.email!.isNotEmpty) ...[
           const SizedBox(height: 8),
           _buildInfoRow('Email', _store!.email!),
         ],
         const SizedBox(height: 16),
         Row(
           children: [
             Icon(Icons.support_agent, color: AppTheme.primaryColor, size: 20),
             const SizedBox(width: 8),
             Expanded(
               child: Text(
                 'Average response time: ${_store!.stats.responseTimeText}',
                 style: const TextStyle(fontSize: 13, color: Colors.grey),
               ),
             ),
           ],
         ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  // Farm Information Section
  Widget _buildFarmInformation() {
    if (_farmInfo == null) return const SizedBox.shrink();

    // Only show if farm info has meaningful data
    if (_farmInfo!.size.isEmpty && 
        _farmInfo!.primaryCrops.isEmpty && 
        _farmInfo!.farmingMethods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.agriculture, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'About Our Farm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Farm Location
          if (_farmInfo!.location.isNotEmpty) ...[
            _buildInfoRow('Farm Location', _farmInfo!.location),
            const SizedBox(height: 12),
          ],

          // Farm Size
          if (_farmInfo!.size.isNotEmpty) ...[
            _buildInfoRow('Farm Size', _farmInfo!.size),
            const SizedBox(height: 12),
          ],

          // Years of Experience
          if (_farmInfo!.yearsExperience > 0) ...[
            _buildInfoRow(
              'Farming Experience',
              '${_farmInfo!.yearsExperience} years',
            ),
            const SizedBox(height: 12),
          ],

          // Primary Crops
          if (_farmInfo!.primaryCrops.isNotEmpty) ...[
            const Text(
              'We Grow:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _farmInfo!.primaryCrops.map((crop) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    crop,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Farming Methods
          if (_farmInfo!.farmingMethods.isNotEmpty) ...[
            const Text(
              'Farming Practices:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _farmInfo!.farmingMethods.map((method) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.secondaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.eco,
                        size: 14,
                        color: AppTheme.secondaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        method,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Farm Description
          if (_farmInfo!.description != null && _farmInfo!.description!.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              _farmInfo!.description!,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  // Store header with farmer profile image and basic info
  Widget _buildStoreHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: _store?.storeBannerUrl != null
            ? DecorationImage(
                image: NetworkImage(_store!.storeBannerUrl!),
                fit: BoxFit.cover,
              )
            : null,
        gradient: _store?.storeBannerUrl == null
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.8),
                  AppTheme.primaryColor,
                ],
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              20,
              16,
              60,
            ), // Bottom padding to stay above tab bar
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Avatar
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: _store!.storeLogoUrl != null
                          ? NetworkImage(_store!.storeLogoUrl!)
                          : null,
                      backgroundColor: Colors.white,
                      child: _store!.storeLogoUrl == null
                          ? const Icon(
                              Icons.agriculture,
                              size: 35,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Store Info - More space allocated
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store/Farm Name (primary title) with Premium Badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _store!.storeName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_store!.isPremium) ...[
                                const SizedBox(width: 8),
                                PremiumBadge(
                                  isPremium: true,
                                  size: 14,
                                  showLabel: true,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Farmer Name (subtitle)
                          Text(
                            'Owned by ${_store!.ownerName}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Location with better visibility
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _store!.location.isNotEmpty
                                      ? _store!.location
                                      : 'Agusan del Sur',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Verification Badge
                          if (_store!.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.5),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified Farm',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Follow Button - Fixed positioning
                    ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        foregroundColor: _isFollowing
                            ? AppTheme.primaryColor
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Store statistics display
  Widget _buildStoreStats() {
    if (_store?.stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Products',
                _store!.stats.totalProducts.toString(),
                Icons.inventory_2,
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey.shade200,
            ),
            Expanded(
              child: _buildStatItem(
                'Sales',
                _store!.stats.totalSales.toString(),
                Icons.shopping_bag,
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.grey.shade200,
            ),
            Expanded(
              child: _buildStatItem(
                'Followers',
                _store!.stats.followers.toString(),
                Icons.people,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // Store rating and reviews
  Widget _buildStoreRating() {
    if (_store?.rating == null || _store?.stats == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rating Stars
              StarRatingDisplay(
                rating: _store!.rating.averageRating,
                size: 18,
                color: Colors.amber,
                emptyColor: Colors.grey.shade300,
              ),
              const SizedBox(width: 8),
              Text(
                _store!.rating.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${_store!.rating.totalReviews})',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Response Time Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Responds in ${_store!.stats.responseTimeText}',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Product categories horizontal scroll
  Widget _buildProductCategories() {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Product Categories',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80, maxHeight: 100),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return Container(
                width: 80,
                margin: EdgeInsets.only(
                  right: index < _categories.length - 1 ? 12 : 0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getCategoryColor(category).withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getCategoryIcon(category),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
