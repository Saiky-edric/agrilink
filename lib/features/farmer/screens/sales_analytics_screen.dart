import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/farmer_profile_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../core/services/premium_service.dart';
import '../../../shared/widgets/premium_badge.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  final FarmerProfileService _profileService = FarmerProfileService();
  final AuthService _authService = AuthService();
  final PremiumService _premiumService = PremiumService();

  bool _isLoading = true;
  SalesAnalytics? _analytics;
  String? _error;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final analytics = await _profileService.getSalesAnalytics(currentUser.id);
        final userProfile = await _authService.getCurrentUserProfile();
        
        setState(() {
          _analytics = analytics;
          _isPremium = userProfile?.isPremium ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Sales Analytics',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            if (_isPremium) ...[
              const SizedBox(width: 8),
              PremiumBadge(isPremium: true, size: 14, showLabel: false),
            ],
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () {
            // Smart navigation - check if we can pop back
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              // If accessed directly, go to farmer dashboard
              context.go(RouteNames.farmerDashboard);
            }
          },
        ),
        actions: [
          if (_isPremium)
            IconButton(
              icon: const Icon(Icons.file_download, color: AppTheme.primaryGreen),
              tooltip: 'Export to CSV',
              onPressed: _exportToCSV,
            )
          else
            IconButton(
              icon: const Icon(Icons.lock, color: Colors.grey),
              tooltip: 'Export (Premium Only)',
              onPressed: () => _premiumService.showUpgradeDialog(
                context,
                title: 'Export Analytics',
                message: 'Upgrade to Premium to export your analytics data to CSV!',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _analytics != null
                  ? _buildAnalyticsContent()
                  : _buildNoDataWidget(),
    );
  }
  
  Future<void> _exportToCSV() async {
    // TODO: Implement CSV export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV export feature coming soon!'),
        backgroundColor: AppTheme.infoBlue,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorRed,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load analytics',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: const TextStyle(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'No Analytics Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Start selling products to see your analytics',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          _buildOverviewCards(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Premium Upsell Banner for Free Users
          if (!_isPremium) _buildPremiumUpsellBanner(),
          if (!_isPremium) const SizedBox(height: AppSpacing.xl),
          
          // Product Category Analytics
          _buildProductCategoryAnalytics(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Revenue Chart (Sales Trend)
          _buildRevenueChart(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Top Products
          _buildTopProducts(),
          
          const SizedBox(height: AppSpacing.xl),
          
          // Advanced Analytics Teaser for Free Users
          if (!_isPremium) _buildAdvancedAnalyticsTeaser(),
        ],
      ),
    );
  }
  
  Widget _buildPremiumUpsellBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unlock Advanced Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Get detailed insights, date range filters, and export to CSV',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _premiumService.showUpgradeDialog(
              context,
              title: 'Advanced Analytics',
              message: 'Upgrade to Premium and unlock powerful analytics features!',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFFA500),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdvancedAnalyticsTeaser() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, color: Colors.grey.shade400, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Premium Analytics Features',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildLockedFeature('📊 30, 60, 90-day historical data'),
          _buildLockedFeature('📈 Advanced revenue forecasting'),
          _buildLockedFeature('👥 Customer insights & behavior'),
          _buildLockedFeature('💾 Export analytics to CSV'),
          _buildLockedFeature('📅 Custom date range filtering'),
          _buildLockedFeature('🎯 Product performance tracking'),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: ElevatedButton(
              onPressed: () => _premiumService.showUpgradeDialog(
                context,
                title: 'Unlock All Features',
                message: 'Upgrade to Premium and get access to advanced analytics, unlimited products, and more!',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Upgrade to Premium',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLockedFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.1, // Lower ratio = TALLER cards
          children: [
            _buildMetricCard(
              'Total Revenue',
              '₱${_analytics!.totalRevenue.toStringAsFixed(2)}',
              Icons.monetization_on,
              AppTheme.primaryGreen,
            ),
            _buildMetricCard(
              'Total Orders',
              _analytics!.totalOrders.toString(),
              Icons.shopping_cart,
              AppTheme.secondaryGreen,
            ),
            _buildMetricCard(
              'Products',
              _analytics!.totalProducts.toString(),
              Icons.inventory,
              AppTheme.warningOrange,
            ),
            _buildMetricCard(
              'Avg. Order',
              '₱${_analytics!.averageOrderValue.toStringAsFixed(2)}',
              Icons.trending_up,
              AppTheme.infoBlue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevents overflow
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24), // Restored for visibility
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.trending_up, color: color, size: 14), // Reduced from 16
              ),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 22, // Increased back for readability
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12, // Restored original size
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCategoryAnalytics() {
    if (_analytics!.topProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate category distribution from top products
    final Map<String, int> categoryCount = {};
    final Map<String, double> categoryRevenue = {};
    
    for (var product in _analytics!.topProducts) {
      // For demo purposes, derive category from product name
      String category = 'Others';
      final name = product.name.toLowerCase();
      if (name.contains('rice') || name.contains('corn')) {
        category = 'Grains';
      } else if (name.contains('tomato') || name.contains('lettuce') || name.contains('cabbage')) {
        category = 'Vegetables';
      } else if (name.contains('mango') || name.contains('banana')) {
        category = 'Fruits';
      }
      
      categoryCount[category] = (categoryCount[category] ?? 0) + product.sales;
      categoryRevenue[category] = (categoryRevenue[category] ?? 0) + product.revenue;
    }

    final colors = [
      AppTheme.primaryGreen,
      AppTheme.secondaryGreen,
      AppTheme.warningOrange,
      AppTheme.infoBlue,
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                    colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pie_chart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Product Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Category List
          ...categoryCount.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final categoryEntry = entry.value;
            final category = categoryEntry.key;
            final count = categoryEntry.value;
            final revenue = categoryRevenue[category] ?? 0;
            final color = colors[index % colors.length];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '$count sales',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '₱${revenue.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 14,
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

  Widget _buildRevenueChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.successGreen, AppTheme.primaryGreen],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Sales Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        
        Container(
          height: 200,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGrey),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _analytics!.monthlyRevenue.map((month) {
                    final maxRevenue = _analytics!.monthlyRevenue
                        .map((m) => m.revenue)
                        .reduce((a, b) => a > b ? a : b);
                    final height = (month.revenue / maxRevenue) * 120;
                    
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '₱${month.revenue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 24,
                          height: height,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          month.month,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performing Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGrey),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _analytics!.topProducts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = _analytics!.topProducts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text('${product.sales} sales'),
                trailing: Text(
                  '₱${product.revenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}