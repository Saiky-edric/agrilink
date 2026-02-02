import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/farmer_profile_service.dart';
import '../../../core/services/farmer_verification_service.dart';
import '../../../core/services/badge_service.dart';
import '../../../core/models/farmer_verification_model.dart';
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
import 'subscription_offer_popup.dart';
import 'verification_success_popup.dart';
import '../../../shared/widgets/premium_welcome_popup.dart';

class FarmerDashboardScreen extends StatefulWidget {
  final int initialIndex;
  const FarmerDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final SupabaseService _supabase = SupabaseService.instance;

  bool _isLoading = true;
  bool _isFarmerVerified = false;
  Map<String, dynamic>? _verificationData;
  Map<String, dynamic> _dashboardStats = {
    'totalProducts': 0,
    'activeOrders': 0,
    'totalSales': 0.0,
    'pendingOrders': 0,
  };

  // Chart data
  List<FlSpot> _salesChartData = [];
  List<BarChartGroupData> _ordersChartData = [];
  List<PieChartSectionData> _productsChartData = [];
  final Map<String, double> _weeklyStats = {};

  // Real-time update components
  Timer? _refreshTimer;
  Timer? _carouselTimer;
  final PageController _carouselController = PageController();
  int _currentCarouselPage = 0;
  final StreamController<Map<String, dynamic>> _chartDataController =
      StreamController.broadcast();
  final FarmerProfileService _farmerProfileService = FarmerProfileService();
  final FarmerVerificationService _verificationService =
      FarmerVerificationService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadDashboardData();
    _startRealTimeUpdates();
    _checkAndShowSubscriptionOffer();
    _initializeBadges();
    _checkVerificationStatusOverlay();
    _checkAndShowPremiumWelcome();
  }

  /// Check and show premium welcome popup (one-time only)
  Future<void> _checkAndShowPremiumWelcome() async {
    // Wait for dashboard to load first
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      // Get current user profile to check premium status
      final userProfile = await _authService.getCurrentUserProfile();
      if (userProfile == null) return;

      // Only show if user is premium and has valid expiry date
      if (userProfile.isPremium && userProfile.subscriptionExpiresAt != null) {
        if (!mounted) return;
        
        await PremiumWelcomePopup.showIfNeeded(
          context: context,
          userId: userId,
          farmerName: userProfile.fullName,
          expiresAt: userProfile.subscriptionExpiresAt!,
        );
      }
    } catch (e) {
      print('Error checking premium welcome: $e');
    }
  }

  Future<void> _checkVerificationStatusOverlay() async {
    // Wait for dashboard to load first
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final verification =
          await _verificationService.getVerificationStatus(userId);
      if (verification == null) return;

      final prefs = await SharedPreferences.getInstance();

      // For approved status, the new VerificationSuccessPopup system is used (see _showPopupsForVerifiedFarmer)
      // We no longer show the old overlay here

      // Check for rejected (rejection overlay)
      if (verification.status == VerificationStatus.rejected) {
        final hasSeenRejection = prefs.getBool(
                'verification_rejection_overlay_seen_${verification.id}') ??
            false;
        if (!hasSeenRejection && mounted) {
          await prefs.setBool(
              'verification_rejection_overlay_seen_${verification.id}', true);
          _showVerificationRejectedOverlay(verification.rejectionReason ??
              'Please check your documents and try again.');
        }
      }
    } catch (e) {
      debugPrint('Error checking verification overlay: $e');
    }
  }

  // OLD VERIFICATION SUCCESS OVERLAY - NO LONGER USED
  // Replaced by VerificationSuccessPopup class which provides better UX
  // (has close button, proper navigation, and sequencing with subscription popup)

  void _showVerificationRejectedOverlay(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/verification_rejected.json',
                width: 250,
                height: 250,
                repeat: false,
                onLoaded: (composition) {
                  // Auto-close after 3 seconds
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) Navigator.of(context).pop();
                  });
                },
              ),
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Verification Not Approved',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        reason,
                        style:
                            TextStyle(fontSize: 14, color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go(RouteNames.uploadVerification);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                      ),
                      child: const Text('Resubmit Documents',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    _carouselTimer?.cancel();
    _carouselController.dispose();
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

      // Fetch ALL orders EXCEPT cancelled for total sales
      final allOrdersResponse = await _supabase.orders
          .select('total_amount, farmer_status')
          .eq('farmer_id', currentUser.id);

      // Calculate all-time total sales from all orders except cancelled
      double totalSales = 0.0;
      for (var order in allOrdersResponse) {
        final status = order['farmer_status']?.toString().toLowerCase() ?? '';
        if (status != 'cancelled') {
          totalSales += (order['total_amount'] ?? 0.0).toDouble();
        }
      }

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
          'totalSales': totalSales, // Use all-time total sales
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

    // Start carousel auto-rotation every 5 seconds
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_carouselController.hasClients) {
        _currentCarouselPage = (_currentCarouselPage + 1) % 4; // 4 cards total
        _carouselController.animateToPage(
          _currentCarouselPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _checkAndShowSubscriptionOffer() async {
    // Wait a bit for the dashboard to load
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Get current user's verification status
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final verification =
          await _verificationService.getVerificationStatus(userId);

      // Only show if verified (approved status)
      final isVerified = verification?.status == VerificationStatus.approved;

      if (isVerified && mounted) {
        // Check if this is a newly verified farmer (first time seeing success)
        final hasSeenSuccess = await VerificationSuccessPopup.hasBeenShown();

        if (!hasSeenSuccess) {
          // Show verification success popup first (one time only)
          // Wait for it to close completely before showing subscription offer
          await VerificationSuccessPopup.showIfNeeded(context,
              isNewlyVerified: true);

          // Wait for dialog to fully close and user to be ready for next popup
          await Future.delayed(const Duration(milliseconds: 800));
        }

        // Then show subscription offer (daily) - only if context is still mounted
        if (mounted) {
          await SubscriptionOfferPopup.showIfNeeded(context, isVerified: true);
        }
      }
    } catch (e) {
      debugPrint('Error checking subscription offer: $e');
    }
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

      // Calculate all-time total sales from all orders except cancelled
      double allTimeSales = 0.0;
      if (chartData['allSales'] != null) {
        final allSales = chartData['allSales'] as List;
        for (var sale in allSales) {
          final status = sale['farmer_status']?.toString().toLowerCase() ?? '';
          if (status != 'cancelled') {
            allTimeSales += (sale['total_amount'] ?? 0.0).toDouble();
          }
        }
      }

      if (mounted) {
        setState(() {
          // Update verification data in real-time
          _verificationData = verification;
          _isFarmerVerified =
              verification != null && verification['status'] == 'approved';

          // Also update dashboard stats
          if (chartData['products'] != null) {
            _dashboardStats['totalProducts'] =
                (chartData['products'] as List).length;
          }
          if (chartData['orders'] != null) {
            final orders = chartData['orders'] as List;
            _dashboardStats['activeOrders'] =
                orders.where((o) => o['farmer_status'] != 'completed').length;
            _dashboardStats['pendingOrders'] =
                orders.where((o) => o['farmer_status'] == 'newOrder').length;
          }
          // Use all-time total sales instead of just weekly
          _dashboardStats['totalSales'] = allTimeSales;
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
      // Fetch real sales data for last 7 days (for chart)
      final salesResponse = await client
          .from('orders')
          .select('created_at, total_amount')
          .eq('farmer_id', farmerId)
          .eq('farmer_status', 'completed')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at');

      // Fetch ALL orders EXCEPT cancelled for total sales calculation
      final allSalesResponse = await client
          .from('orders')
          .select('total_amount, farmer_status')
          .eq('farmer_id', farmerId);

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
        'allSales': allSalesResponse, // All-time sales for dashboard stat
        'orders': ordersResponse,
        'products': productsResponse,
      };
    } catch (e) {
      print('Error fetching real-time data: $e');
      return {};
    }
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

    final categories = [
      'vegetables',
      'fruits',
      'grains',
      'herbs',
      'dairy',
      'livestock'
    ];
    final colors = [
      AppTheme.primaryGreen,
      AppTheme.accentGreen,
      AppTheme.warningOrange,
      AppTheme.infoBlue,
      Colors.purple,
      Colors.brown
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
        _buildDashboardContent(), // Index 0 - Dashboard
        const _ScreenWrapper(child: FarmerOrdersScreen()), // Index 1 - Orders
        const _ScreenWrapper(child: ProductListScreen()), // Index 2 - Products
        const SizedBox.shrink(), // Index 3 - Messages (handled via nav)
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
                padding: const EdgeInsets.fromLTRB(
                    20, 20, 20, 100), // Extra bottom padding
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modern Welcome Header
                    _buildModernWelcomeHeader(),

                    const SizedBox(height: 24),

                    // Info Carousel (replaces verification card)
                    _buildInfoCarousel(),

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
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () async {
              // Manual refresh for verification status and badges
              await _loadDashboardData();
              final badgeService =
                  Provider.of<BadgeService>(context, listen: false);
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
              if (index == 3) {
                context.go(RouteNames.chatInbox, extra: {'origin': 'farmer'});
                return;
              }
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

  Widget _buildModernAnalyticsCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCategoryAnalytics() {
    return ModernGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.pie_chart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Product Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_productsChartData.isNotEmpty &&
              _dashboardStats['totalProducts'] > 0)
            _buildCategoryPieChart()
          else
            _buildEmptyCategoryState(),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pie Chart Section
        SizedBox(
          height: 320,
          child: PieChart(
            PieChartData(
              sections: _productsChartData,
              sectionsSpace: 4,
              centerSpaceRadius: 60,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Category Breakdown Section (Below Chart)
        const Text(
          'Category Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._buildCategoryLegend(),
      ],
    );
  }

  List<Widget> _buildCategoryLegend() {
    final categories = [
      'vegetables',
      'fruits',
      'grains',
      'herbs',
      'dairy',
      'livestock'
    ];
    final categoryLabels = [
      '🥬 Vegetables',
      '🍎 Fruits',
      '🌾 Grains',
      '🌿 Herbs',
      '🥛 Dairy',
      '🐄 Livestock'
    ];
    final categoryDescriptions = [
      'Fresh greens & veggies',
      'Seasonal fruits',
      'Rice, wheat & more',
      'Aromatic herbs',
      'Fresh dairy products',
      'Farm animals'
    ];
    final colors = [
      AppTheme.primaryGreen,
      AppTheme.accentGreen,
      AppTheme.warningOrange,
      AppTheme.infoBlue,
      Colors.purple,
      Colors.brown,
    ];

    List<Widget> legend = [];

    // Build legend ONLY for categories that have actual products
    for (int i = 0; i < _productsChartData.length; i++) {
      final section = _productsChartData[i];
      if (section.value > 0) {
        // Find which category this section represents by matching the color
        int categoryIndex = -1;
        for (int j = 0; j < colors.length; j++) {
          if (section.color == colors[j]) {
            categoryIndex = j;
            break;
          }
        }

        // Only show legend item if we found a matching category
        if (categoryIndex >= 0 && categoryIndex < categories.length) {
          final sectionColor = section.color;

          legend.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sectionColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sectionColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: sectionColor,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: sectionColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryLabels[categoryIndex],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          categoryDescriptions[categoryIndex],
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: sectionColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${section.value.toInt()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sectionColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return legend.isEmpty
        ? [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No products yet',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          ]
        : legend;
  }

  Widget _buildEmptyCategoryState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.textSecondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textSecondary.withOpacity(0.1),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 48,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Add products to see category breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first product',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push(RouteNames.addProduct),
            icon: Icon(Icons.add, size: 16),
            label: Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTrendAnalytics() {
    return ModernGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.successGreen, AppTheme.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.trending_up, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sales Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSalesChart(),
        ],
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
        SizedBox(
          height: 160,
          child: Row(
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
                () => context
                    .push(RouteNames.chatInbox, extra: {'origin': 'farmer'}),
              ),
            ],
          ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 14),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * 0.6,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: color,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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

  Widget _buildInfoCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView(
            controller: _carouselController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselPage = index;
              });
            },
            children: [
              // Verification Status Card
              _buildModernVerificationCard(),

              // Subscription Info Card
              _buildSubscriptionInfoCard(),

              // Tips Card
              _buildTipsCard(),

              // Stats Summary Card
              _buildQuickStatsCard(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentCarouselPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentCarouselPage == index
                    ? AppTheme.primaryGreen
                    : AppTheme.primaryGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionInfoCard() {
    return GestureDetector(
      onTap: () => context.push(RouteNames.subscription),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade600, Colors.amber.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 14),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                '✓ Unlimited Products\n✓ Priority Placement\n✓ Featured on Homepage',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Only ₱149/month',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    final tips = [
      {'icon': Icons.camera_alt, 'text': 'Use clear product photos'},
      {'icon': Icons.price_check, 'text': 'Set competitive prices'},
      {'icon': Icons.update, 'text': 'Update stock regularly'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.infoBlue, AppTheme.infoBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.infoBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.lightbulb, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quick Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(tip['icon'] as IconData,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip['text'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.95),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.analytics, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Quick Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Products', '${_dashboardStats['totalProducts']}'),
              _buildMiniStat('Orders', '${_dashboardStats['activeOrders']}'),
              Flexible(
                child: _buildMiniStat('Sales',
                    '₱${(_dashboardStats['totalSales'] as double).toStringAsFixed(0)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
        _buildModernAnalyticsCard(
          '🌱 Total Products',
          '${_dashboardStats['totalProducts'] ?? 0}',
          'items in store',
          Icons.agriculture,
          AppTheme.primaryGreen,
          _dashboardStats['totalProducts'] > 0
              ? '+2 this week'
              : 'Add your first product',
        ),
        const SizedBox(height: 16),
        _buildModernAnalyticsCard(
          '💰 Total Sales',
          '₱${(_dashboardStats['totalSales'] ?? 0.0).toStringAsFixed(0)}',
          'all-time revenue',
          Icons.account_balance_wallet,
          AppTheme.successGreen,
          _dashboardStats['totalSales'] > 0 ? 'All orders' : 'No sales yet',
        ),
        const SizedBox(height: 16),
        _buildModernAnalyticsCard(
          '⏰ Pending Orders',
          '${_dashboardStats['pendingOrders'] ?? 0}',
          'awaiting response',
          Icons.access_time,
          AppTheme.infoBlue,
          _dashboardStats['pendingOrders'] > 0
              ? 'Review and respond'
              : 'All caught up!',
        ),
        const SizedBox(height: 20),

        // Modern Product Category Analytics
        _buildProductCategoryAnalytics(),

        const SizedBox(height: 32),

        // Sales Trend Analytics
        _buildSalesTrendAnalytics(),
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
                              _currentIndex =
                                  2; // Fixed: Products tab is index 2
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
                              _currentIndex = 1; // Fixed: Orders tab is index 1
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: cardHeight,
                        child: ModernActionCard(
                          title: 'Subscription',
                          subtitle: 'Upgrade to Premium',
                          icon: Icons.star,
                          color: Colors.amber.shade700,
                          onTap: () => context.push(RouteNames.subscription),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: cardHeight,
                        child: Container(), // Empty placeholder for symmetry
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
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: _salesChartData.isNotEmpty
                    ? _salesChartData
                            .map((e) => e.y)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2
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
                    ? _ordersChartData
                            .map((e) => e.barRods.first.toY)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2
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

  Widget _buildModernStatCard(
      String title, String value, IconData icon, Color color, String subtitle) {
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
