import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/farmer_profile_service.dart';
import '../../../core/services/badge_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/modern_cards.dart';
import '../../../shared/widgets/modern_buttons.dart';
import '../../../shared/widgets/modern_loading.dart';
import '../../../shared/widgets/modern_animations.dart';
import '../../../shared/widgets/unread_badge.dart';
import '../../../shared/widgets/farmer_bottom_nav.dart';
import 'product_list_screen.dart';
import 'farmer_orders_screen.dart';
import 'farmer_profile_screen.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  final AuthService _authService = AuthService();
  final SupabaseService _supabase = SupabaseService.instance;
  int _currentIndex = 0;

  bool _isLoading = true;
  bool _isFarmerVerified = false;
  Map<String, dynamic>? _verificationData;
  Map<String, dynamic> _dashboardStats = {
    'totalProducts': 0,
    'activeOrders': 0,
    'totalSales': 0.0,
    'pendingOrders': 0,
  };

  // Agricultural Analytics Data
  Map<String, dynamic> _agriculturalStats = {
    'lowStockProducts': 0,
    'expiringSoon': 0,
    'topCategory': 'vegetables',
    'harvestValue': 0.0,
  };

  // Chart data
  List<FlSpot> _salesChartData = [];
  List<BarChartGroupData> _ordersChartData = [];
  List<PieChartSectionData> _productsChartData = [];
  final Map<String, double> _weeklyStats = {};

  // Real-time update components
  Timer? _refreshTimer;
  final StreamController<Map<String, dynamic>> _chartDataController = StreamController.broadcast();
  final FarmerProfileService _farmerProfileService = FarmerProfileService();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startRealTimeUpdates();
    _initializeBadges();
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
    _refreshTimer?.cancel();
    _chartDataController.close();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Check verification status
      final verification = await _supabase.farmerVerifications
          .select()
          .eq('farmer_id', currentUser.id)
          .maybeSingle();

      // Load dashboard statistics
      final productCountResponse = await _supabase.products
          .select('id')
          .eq('farmer_id', currentUser.id)
          .eq('is_hidden', false);

      final activeOrdersResponse = await _supabase.orders
          .select('id')
          .eq('farmer_id', currentUser.id)
          .neq('farmer_status', 'completed');

      final pendingOrdersResponse = await _supabase.orders
          .select('id')
          .eq('farmer_id', currentUser.id)
          .eq('farmer_status', 'newOrder');

      // Load agricultural analytics data
      await _loadAgriculturalData();

      // Generate chart data with actual responses
      _generateChartData(
        productCountResponse,
        activeOrdersResponse,
        pendingOrdersResponse,
      );

      setState(() {
        _verificationData = verification;
        _isFarmerVerified =
            verification != null && verification['status'] == 'approved';
        _dashboardStats = {
          'totalProducts': productCountResponse.length,
          'activeOrders': activeOrdersResponse.length,
          'totalSales': _weeklyStats.values.fold(0.0, (a, b) => a + b),
          'pendingOrders': pendingOrdersResponse.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startRealTimeUpdates() {
    // Start timer for automatic refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadRealTimeChartData();
    });
    
    // Initial load of real-time data
    _loadRealTimeChartData();
  }

  Future<void> _loadRealTimeChartData() async {
    try {
      final userId = AuthService().currentUser?.id;
      if (userId == null) return;

      // Fetch both chart data AND verification status
      final chartData = await _fetchRealTimeChartData(userId);
      final verification = await _supabase.farmerVerifications
          .select()
          .eq('farmer_id', userId)
          .maybeSingle();

      _chartDataController.add(chartData);
      
      // Update chart data
      _generateChartData(
        chartData['products'] ?? [],
        chartData['orders'] ?? [],
        chartData['sales'] ?? [],
      );
      
      if (mounted) {
        setState(() {
          // Update verification data in real-time
          _verificationData = verification;
          _isFarmerVerified = verification != null && verification['status'] == 'approved';
          
          // Also update dashboard stats
          if (chartData['products'] != null) {
            _dashboardStats['totalProducts'] = (chartData['products'] as List).length;
          }
          if (chartData['orders'] != null) {
            final orders = chartData['orders'] as List;
            _dashboardStats['activeOrders'] = orders.where((o) => o['farmer_status'] != 'completed').length;
            _dashboardStats['pendingOrders'] = orders.where((o) => o['farmer_status'] == 'newOrder').length;
          }
          _dashboardStats['totalSales'] = _weeklyStats.values.fold(0.0, (a, b) => a + b);
        });
      }
    } catch (e) {
      print('Error loading real-time data: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchRealTimeChartData(String farmerId) async {
    final client = SupabaseService.instance.client;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    try {
      // Fetch real sales data for last 7 days
      final salesResponse = await client
          .from('orders')
          .select('created_at, total_amount')
          .eq('farmer_id', farmerId)
          .eq('farmer_status', 'completed')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at');

      // Fetch daily orders for last 7 days
      final ordersResponse = await client
          .from('orders')
          .select('created_at, farmer_status')
          .eq('farmer_id', farmerId)
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at');

      // Fetch products by category
      final productsResponse = await client
          .from('products')
          .select('category')
          .eq('farmer_id', farmerId)
          .eq('is_hidden', false);

      return {
        'sales': salesResponse,
        'orders': ordersResponse,
        'products': productsResponse,
      };
    } catch (e) {
      print('Error fetching real-time data: $e');
      return {};
    }
  }

  Future<void> _loadAgriculturalData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Fetch products with detailed agricultural information
      final productResponse = await _supabase.products
          .select('id, name, stock, category, shelf_life_days, created_at, price')
          .eq('farmer_id', currentUser.id)
          .eq('is_hidden', false);

      _calculateAgriculturalMetrics(productResponse);
    } catch (e) {
      print('Error loading agricultural data: $e');
    }
  }

  void _calculateAgriculturalMetrics(List<dynamic> products) {
    if (products.isEmpty) return;

    int lowStock = 0;
    int expiringSoon = 0;
    double harvestValue = 0.0;
    Map<String, int> categoryCount = {};

    for (var product in products) {
      // Calculate low stock (less than 5 units)
      final stock = product['stock'] ?? 0;
      if (stock < 5 && stock > 0) lowStock++;

      // Calculate expiring soon (within 3 days)
      final shelfLife = product['shelf_life_days'] ?? 7;
      final createdAt = DateTime.parse(product['created_at']);
      final expiryDate = createdAt.add(Duration(days: shelfLife));
      final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
      if (daysUntilExpiry <= 3 && daysUntilExpiry >= 0) expiringSoon++;

      // Calculate total harvest value
      final price = (product['price'] ?? 0.0).toDouble();
      harvestValue += price * stock;

      // Count categories
      final category = product['category'] ?? 'others';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    // Find top category
    String topCategory = 'vegetables';
    int maxCount = 0;
    categoryCount.forEach((category, count) {
      if (count > maxCount) {
        maxCount = count;
        topCategory = category;
      }
    });

    _agriculturalStats = {
      'lowStockProducts': lowStock,
      'expiringSoon': expiringSoon,
      'topCategory': topCategory,
      'harvestValue': harvestValue,
    };
  }

  void _generateChartData(dynamic products, dynamic orders, dynamic sales) {
    // Convert products to list if it's a count
    final List<dynamic> productsList = products is List ? products : [];
    final List<dynamic> ordersList = orders is List ? orders : [];
    final List<dynamic> salesList = sales is List ? sales : [];
    final now = DateTime.now();
    
    // Generate real sales chart data
    _weeklyStats.clear();
    _salesChartData = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      // Calculate actual sales for this day
      double dailySales = 0.0;
      for (var sale in salesList) {
        final saleDate = DateTime.parse(sale['created_at']);
        if (saleDate.isAfter(dayStart) && saleDate.isBefore(dayEnd)) {
          dailySales += (sale['total_amount'] ?? 0.0);
        }
      }
      
      // Keep actual sales data (including 0 for days with no sales)
      // No fallback - use real data only
      
      _weeklyStats['${day.day}/${day.month}'] = dailySales;
      return FlSpot(index.toDouble(), dailySales);
    });

    // Generate real orders chart data
    _ordersChartData = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      // Count actual orders for this day
      int dailyOrders = 0;
      for (var order in ordersList) {
        final orderDate = DateTime.parse(order['created_at']);
        if (orderDate.isAfter(dayStart) && orderDate.isBefore(dayEnd)) {
          dailyOrders++;
        }
      }
      
      // Keep actual orders data (including 0 for days with no orders)
      // No fallback - use real data only
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: dailyOrders.toDouble(),
            color: AppTheme.primaryGreen,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    // Generate real products by category pie chart
    final categoryMap = <String, int>{};
    for (var product in productsList) {
      final category = product['category'] ?? 'Other';
      categoryMap[category] = (categoryMap[category] ?? 0) + 1;
    }

    final categories = ['vegetables', 'fruits', 'grains', 'herbs', 'dairy', 'livestock'];
    final colors = [
      AppTheme.primaryGreen, 
      AppTheme.accentGreen, 
      AppTheme.warningOrange, 
      AppTheme.infoBlue,
      Colors.purple,
      Colors.brown,
    ];
    
    _productsChartData = [];
    for (int index = 0; index < categories.length; index++) {
      final category = categories[index];
      final value = categoryMap[category]?.toDouble() ?? 0.0;
      
      if (value > 0) {
        _productsChartData.add(PieChartSectionData(
          value: value,
          title: '${value.toInt()}',
          color: colors[index % colors.length],
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ));
      }
    }
    
    // If no products exist, show empty state indicator
    if (_productsChartData.isEmpty) {
      _productsChartData.add(PieChartSectionData(
        value: 1,
        title: '',
        color: Colors.grey.withOpacity(0.3),
        radius: 50,
        titleStyle: const TextStyle(fontSize: 0),
      ));
    }
  }

  List<Widget> get _pages => [
    _buildDashboardContent(),                          // Index 0 - Dashboard
    const _ScreenWrapper(child: FarmerOrdersScreen()), // Index 1 - Orders
    const _ScreenWrapper(child: ProductListScreen()),  // Index 2 - Products  
    const Center(                                      // Index 3 - Messages
      child: ElevatedButton(
        onPressed: () => context.go(RouteNames.chatInbox),
        child: Text('Open Messages'),
      ),
    ), 
    _ScreenWrapper(child: FarmerProfileScreen()), // Index 4 - Profile
  ];

  Widget _buildDashboardContent() {
    return _isLoading
        ? _buildModernLoadingState()
        : Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              backgroundColor: AppTheme.cardWhite,
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Extra bottom padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modern Welcome Header
                    _buildModernWelcomeHeader(),

                    const SizedBox(height: 24),

                    // Verification Status Card
                    _buildModernVerificationCard(),

                    if (_isFarmerVerified) ...[
                      const SizedBox(height: 24),

                      // Modern Stats Grid
                      _buildModernStatsGrid(),

                      const SizedBox(height: 32),

                      // Quick Actions with Modern Design
                      _buildModernQuickActions(),

                      const SizedBox(height: 32),

                      // Recent Activity
                      _buildModernRecentActivity(),
                    ],
                  ],
                ),
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Farmer Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () async {
              // Manual refresh for verification status and badges
              await _loadDashboardData();
              final badgeService = Provider.of<BadgeService>(context, listen: false);
              await badgeService.initializeBadges();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Dashboard refreshed'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            tooltip: 'Refresh verification status',
          ),
          Consumer<BadgeService>(
            builder: (context, badgeService, child) {
              return IconButton(
                icon: NotificationBadge(
                  unreadCount: badgeService.pureNotificationCount,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () {
                  context.push('/notifications');
                },
              );
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  context.push('/farmer/profile');
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.store),
                  title: Text('Store Customization'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  context.push(RouteNames.storeCustomization);
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Store Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  context.push(RouteNames.storeSettings);
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  context.push('/settings');
                },
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () async {
                  await _authService.signOut();
                  if (context.mounted) {
                    context.go(RouteNames.login);
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Consumer<BadgeService>(
        builder: (context, badgeService, child) {
          return FarmerBottomNav(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture,
              color: AppTheme.primaryGreen,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                FutureBuilder(
                  future: _authService.getCurrentUserProfile(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return const Text(
                      'Farmer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    if (_verificationData == null) {
      // No verification submitted
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppTheme.warningOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          border: Border.all(
            color: AppTheme.warningOrange.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.warning_rounded,
              color: AppTheme.warningOrange,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Verification Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.warningOrange,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'You need to complete farmer verification before you can start selling products.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomButton(
              text: 'Start Verification',
              type: ButtonType.primary,
              isFullWidth: true,
              onPressed: () => context.push(RouteNames.uploadVerification),
            ),
          ],
        ),
      );
    }

    final status = _verificationData!['status'];
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = AppTheme.warningOrange;
        statusIcon = Icons.pending;
        statusText = 'Verification Pending';
        break;
      case 'approved':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.verified;
        statusText = 'Verified Farmer';
        break;
      case 'rejected':
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.cancel;
        statusText = 'Verification Rejected';
        break;
      default:
        statusColor = AppTheme.textSecondary;
        statusIcon = Icons.info;
        statusText = 'Unknown Status';
    }

    return GestureDetector(
      onTap: () => context.push(RouteNames.verificationStatus),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 32),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (status == 'pending')
                    const Text(
                      'Review in progress...',
                      style: AppTextStyles.bodySmall,
                    ),
                  if (status == 'rejected')
                    const Text(
                      'Tap to see feedback and resubmit',
                      style: AppTextStyles.bodySmall,
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: statusColor, size: 16),
          ],
        ),
      ),
    );
  }


  Widget _buildCompactStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _buildActionCard(
              'Add Product',
              Icons.add_box,
              AppTheme.primaryGreen,
              () => context.push(RouteNames.addProduct),
            ),
            _buildActionCard(
              'Manage Products',
              Icons.inventory_2,
              AppTheme.accentGreen,
              () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _buildActionCard(
              'View Orders',
              Icons.receipt_long,
              AppTheme.warningOrange,
              () {
                setState(() {
                  _currentIndex = 2;
                });
              },
            ),
            _buildActionCard(
              'Messages',
              Icons.chat_bubble,
              AppTheme.infoBlue,
              () => context.push(RouteNames.chatInbox),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              SizedBox(
                height: 32,
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 10,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.clip,
                    softWrap: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
          child: const Center(
            child: Text('No recent activity', style: AppTextStyles.bodyMedium),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      selectedItemColor: AppTheme.primaryGreen,
      unselectedItemColor: AppTheme.textSecondary,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'Orders',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
      ],
    );
  }

  // Modern UI Methods
  Widget _buildModernLoadingState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 40),
            const ModernSkeletonLoader(height: 80, borderRadius: 20),
            const SizedBox(height: 24),
            const ModernSkeletonLoader(height: 120, borderRadius: 20),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: ModernCardSkeleton(height: 100)),
                const SizedBox(width: 16),
                Expanded(child: ModernCardSkeleton(height: 100)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: ModernCardSkeleton(height: 100)),
                const SizedBox(width: 16),
                Expanded(child: ModernCardSkeleton(height: 100)),
              ],
            ),
            const SizedBox(height: 100), // Bottom padding for safe area
          ],
        ),
      ),
    );
  }

  Widget _buildModernWelcomeHeader() {
    return ModernGlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.eco, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getGreeting()}!',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Welcome back, Farmer',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/farmer/profile'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernVerificationCard() {
    if (_verificationData == null) {
      // No verification submitted
      return ModernGlassCard(
        backgroundColor: AppTheme.warningOrange,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Required',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload your documents to start selling',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ModernPrimaryButton(
              text: 'Start Verification',
              icon: Icons.upload_file,
              onPressed: () => context.push(RouteNames.uploadVerification),
              backgroundColor: Colors.white,
              textColor: AppTheme.warningOrange,
              isFullWidth: true,
            ),
          ],
        ),
      );
    }

    // Verification exists - show status with messages
    final status = _verificationData!['status'];
    final rejectionReason = _verificationData!['rejection_reason'] as String?;
    final adminNotes = _verificationData!['admin_notes'] as String?;

    if (status == 'approved') {
      return ModernGlassCard(
        backgroundColor: AppTheme.successGreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.verified, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Approved! 🎉',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your farm is verified and ready for business!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (adminNotes != null && adminNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Message:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminNotes,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    } else if (status == 'rejected') {
      return ModernGlassCard(
        backgroundColor: AppTheme.errorRed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.cancel, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Rejected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please review feedback and resubmit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rejection Reason:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rejectionReason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (adminNotes != null && adminNotes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Notes:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminNotes,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ModernPrimaryButton(
              text: 'Resubmit Verification',
              icon: Icons.refresh,
              onPressed: () => context.push(RouteNames.uploadVerification),
              backgroundColor: Colors.white,
              textColor: AppTheme.errorRed,
              isFullWidth: true,
            ),
          ],
        ),
      );
    } else {
      // Pending status
      return ModernGlassCard(
        backgroundColor: AppTheme.warningOrange,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pending_actions,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Pending',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your documents are being reviewed...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (adminNotes != null && adminNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Message:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminNotes,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ModernPrimaryButton(
              text: 'View Status Details',
              icon: Icons.info_outline,
              onPressed: () => context.push(RouteNames.verificationStatus),
              backgroundColor: Colors.white,
              textColor: AppTheme.warningOrange,
              isFullWidth: true,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildModernStatsGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Overview Stats Row
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                '🌱 Products Listed',
                '${_dashboardStats['totalProducts'] ?? 0}',
                Icons.agriculture,
                AppTheme.primaryGreen,
                '+2 this week',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernStatCard(
                'Total Sales',
                '₱${(_dashboardStats['totalSales'] ?? 0.0).toStringAsFixed(0)}',
                Icons.trending_up,
                AppTheme.successGreen,
                '+12% this month',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Charts Section
        Column(
          children: [
            // Sales Chart
            _buildSalesChart(),
            const SizedBox(height: 24),
            
            // Orders and Products Charts
            Row(
              children: [
                Expanded(child: _buildOrdersChart()),
                const SizedBox(width: 16),
                Expanded(child: _buildProductsChart()),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 16) / 2;
            final cardHeight = cardWidth / 1.2;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: cardHeight,
                        child: ModernActionCard(
                          title: 'Add Product',
                          subtitle: 'List new items',
                          icon: Icons.add_box,
                          color: AppTheme.primaryGreen,
                          onTap: () => context.push(RouteNames.addProduct),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: cardHeight,
                        child: ModernActionCard(
                          title: 'Manage Products',
                          subtitle: 'Edit inventory',
                          icon: Icons.inventory_2,
                          color: AppTheme.accentGreen,
                          onTap: () {
                            setState(() {
                              _currentIndex = 1;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: cardHeight,
                        child: ModernActionCard(
                          title: 'View Orders',
                          subtitle: 'Process sales',
                          icon: Icons.receipt_long,
                          color: AppTheme.warningOrange,
                          showNotification: true,
                          onTap: () {
                            setState(() {
                              _currentIndex = 2;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: cardHeight,
                        child: ModernActionCard(
                          title: 'Store Settings',
                          subtitle: 'Manage store',
                          icon: Icons.store,
                          color: AppTheme.infoBlue,
                          onTap: () => context.push(RouteNames.storeSettings),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildModernRecentActivity() {
    return ModernGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) {
            final activities = [
              {
                'title': 'New order received',
                'subtitle': '2 minutes ago',
                'icon': Icons.shopping_bag,
                'color': AppTheme.successGreen,
              },
              {
                'title': 'Product updated',
                'subtitle': '1 hour ago',
                'icon': Icons.edit,
                'color': AppTheme.infoBlue,
              },
              {
                'title': 'Payment received',
                'subtitle': '3 hours ago',
                'icon': Icons.payment,
                'color': AppTheme.primaryGreen,
              },
            ];

            final activity = activities[index];

            return Padding(
              padding: EdgeInsets.only(bottom: index < 2 ? 16 : 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (activity['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      color: activity['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          activity['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildSalesChart() {
    return ModernGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales Trend (7 days)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+12%',
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        );
                        final keys = _weeklyStats.keys.toList();
                        if (value.toInt() < keys.length) {
                          return Text(keys[value.toInt()], style: style);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '₱${value.toInt()}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: _salesChartData.isNotEmpty 
                    ? _salesChartData.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2
                    : 2000,
                lineBarsData: [
                  LineChartBarData(
                    spots: _salesChartData,
                    isCurved: true,
                    color: AppTheme.successGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.successGreen.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersChart() {
    return ModernGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag, color: AppTheme.infoBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Orders',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_dashboardStats['activeOrders'] ?? 0} Active',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            '${_dashboardStats['pendingOrders'] ?? 0} Pending',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.warningOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _ordersChartData.isNotEmpty 
                    ? _ordersChartData.map((e) => e.barRods.first.toY).reduce((a, b) => a > b ? a : b) * 1.2
                    : 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _ordersChartData,
                gridData: const FlGridData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsChart() {
    return ModernGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Products',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_dashboardStats['totalProducts'] ?? 0} Items',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const Text(
            'By Category',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: PieChart(
              PieChartData(
                sections: _productsChartData,
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 20,
                startDegreeOffset: -90,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return ModernGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Products';
      case 2:
        return 'Orders';
      case 3:
        return 'Messages';
      default:
        return 'AgrLink';
    }
  }
}

// Screen wrapper to remove app bars from embedded screens
class _ScreenWrapper extends StatelessWidget {
  final Widget child;

  const _ScreenWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    // Extract the body from Scaffold widgets to avoid nested app bars
    if (child is Scaffold) {
      final scaffold = child as Scaffold;
      return scaffold.body ?? const SizedBox.shrink();
    }
    return child;
  }
}
