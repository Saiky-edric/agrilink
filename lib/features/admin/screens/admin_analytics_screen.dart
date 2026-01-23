import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/admin_analytics_model.dart';
import '../../../core/services/admin_service.dart';
import '../../../shared/widgets/admin_chart_widget.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final AdminService _adminService = AdminService();

  PlatformAnalytics? _analytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final analytics = await _adminService.getPlatformAnalytics();

      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
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
        title: const Text(
          'Platform Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
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
          : const Center(child: Text('No data available')),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Failed to load analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(onPressed: _loadAnalytics, child: const Text('Retry')),
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
          // Platform Overview
          _buildPlatformOverview(),

          const SizedBox(height: AppSpacing.xl),

          // User Analytics
          _buildUserAnalytics(),

          const SizedBox(height: AppSpacing.xl),

          // Business Metrics
          _buildBusinessMetrics(),

          const SizedBox(height: AppSpacing.xl),

          // Monthly Trends
          _buildMonthlyTrends(),
        ],
      ),
    );
  }

  Widget _buildPlatformOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Platform Overview',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
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
          childAspectRatio: 1.0, // Increased height to prevent overflow (was 1.2)
          children: [
            _buildMetricCard(
              'Total Users',
              _analytics!.userStats.totalUsers.toString(),
              Icons.people,
              AppTheme.primaryGreen,
              '+${_analytics!.userStats.newUsersThisMonth} this month',
            ),
            _buildMetricCard(
              'Total Products',
              _analytics!.overview.totalProducts.toString(),
              Icons.inventory,
              AppTheme.secondaryGreen,
              'Listed products',
            ),
            _buildMetricCard(
              'Total Orders',
              _analytics!.overview.totalOrders.toString(),
              Icons.shopping_cart,
              AppTheme.infoBlue,
              'Completed orders',
            ),
            _buildMetricCard(
              'Total Revenue',
              '₱${_analytics!.overview.totalRevenue.toStringAsFixed(0)}',
              Icons.monetization_on,
              AppTheme.warningOrange,
              'Platform revenue',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Analytics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightGrey),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildUserTypeCard(
                    'Buyers',
                    _analytics!.userStats.buyerCount,
                    Icons.shopping_bag,
                    AppTheme.infoBlue,
                  ),
                  _buildUserTypeCard(
                    'Farmers',
                    _analytics!.userStats.farmerCount,
                    Icons.agriculture,
                    AppTheme.primaryGreen,
                  ),
                  _buildUserTypeCard(
                    'Admins',
                    _analytics!.userStats.adminCount,
                    Icons.admin_panel_settings,
                    AppTheme.errorRed,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // User Growth Chart
              _buildUserGrowthChart(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessMetrics() {
    final avgOrderValue = _analytics!.overview.totalOrders > 0
        ? _analytics!.overview.totalRevenue / _analytics!.overview.totalOrders
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Metrics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Row(
          children: [
            Expanded(
              child: _buildBusinessCard(
                'Avg Order Value',
                '₱${avgOrderValue.toStringAsFixed(2)}',
                Icons.trending_up,
                AppTheme.successGreen,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildBusinessCard(
                'Pending Verifications',
                _analytics!.userStats.pendingVerifications.toString(),
                Icons.pending_actions,
                AppTheme.warningOrange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyTrends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reports & Analytics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Revenue Trend Chart
        AdminChartWidget(
          title: 'Revenue Trend (Last 7 Days)',
          data: _analytics!.overview.revenueChart,
          chartType: 'revenue',
          height: 250,
        ),

        const SizedBox(height: AppSpacing.lg),

        // User Growth Chart
        AdminChartWidget(
          title: 'User Growth (Last 6 Months)',
          data: _analytics!.overview.userGrowthChart,
          chartType: 'userGrowth',
          height: 250,
        ),

        const SizedBox(height: AppSpacing.lg),

        // Order Status Distribution
        AdminChartWidget(
          title: 'Order Status Distribution',
          data: _analytics!.overview.orderStatusChart,
          chartType: 'orderStatus',
          height: 220,
        ),

        const SizedBox(height: AppSpacing.lg),

        // Top Categories Chart
        AdminChartWidget(
          title: 'Top Product Categories',
          data: _analytics!.overview.categorySalesChart,
          chartType: 'categorySales',
          height: 250,
        ),

        const SizedBox(height: AppSpacing.lg),

        // Additional Analytics Cards
        _buildAdditionalAnalytics(),
      ],
    );
  }

  Widget _buildAdditionalAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Product Analytics Row
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'Active Products',
                _analytics!.productStats.activeProducts.toString(),
                Icons.inventory_2,
                AppTheme.successGreen,
                'Currently listed',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildInsightCard(
                'Low Stock',
                _analytics!.productStats.lowStockProducts.toString(),
                Icons.warning_amber,
                AppTheme.warningOrange,
                'Need restock',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Order Analytics Row
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'Pending Orders',
                _analytics!.orderStats.pendingOrders.toString(),
                Icons.pending,
                AppTheme.infoBlue,
                'Awaiting action',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildInsightCard(
                'Delivered',
                _analytics!.orderStats.deliveredOrders.toString(),
                Icons.check_circle,
                AppTheme.successGreen,
                'Completed',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Revenue Growth Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen,
                AppTheme.secondaryGreen,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monthly Revenue Growth',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_analytics!.revenueStats.growth >= 0 ? '+' : ''}${_analytics!.revenueStats.growth.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'vs last month (₱${_analytics!.revenueStats.monthlyRevenue.toStringAsFixed(0)} this month)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Better spacing distribution
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.trending_up, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8), // Reduced spacing
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeCard(
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildBusinessCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGrey),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return Column(
      children: [
        const Text(
          'User Growth (Last 6 Months)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'Revenue Trend: ₱${_analytics!.revenueStats.monthlyRevenue.toStringAsFixed(0)} this month',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
