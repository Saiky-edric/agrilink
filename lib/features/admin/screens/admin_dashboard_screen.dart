import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/payout_service.dart';
import '../../../core/models/admin_analytics_model.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/admin_chart_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ScrollController _scrollController = ScrollController();
  
  // Global keys for scroll targets
  final GlobalKey _verificationsKey = GlobalKey();
  final GlobalKey _reportsKey = GlobalKey();
  final GlobalKey _paymentsKey = GlobalKey();
  final GlobalKey _payoutsKey = GlobalKey();
  final GlobalKey _subscriptionsKey = GlobalKey();
  
  AdminAnalytics? _analytics;
  List<AdminActivity> _recentActivities = [];
  int _pendingSubscriptionsCount = 0;
  int _pendingVerificationsCount = 0;
  int _unresolvedReportsCount = 0;
  int _pendingPaymentsCount = 0;
  int _pendingPayoutsCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3, // Position at eye level (center of screen)
      );
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final analytics = await _adminService.getDashboardAnalytics();
      final activities = await _adminService.getRecentActivities(limit: 10);
      final pendingSubscriptions = await _subscriptionService.getPendingRequests();
      
      // Get pending verifications
      final pendingVerifications = await _adminService.getAllVerifications(
        statusFilter: 'pending',
      );
      
      // Get unresolved reports (pending reports that need attention)
      final allReports = await _adminService.getAllReports();
      final unresolvedReports = allReports.where((report) => 
        report.status != 'resolved' && report.status != 'dismissed'
      ).toList();

      // Get pending payment verifications
      final orderService = OrderService();
      final pendingPayments = await orderService.getPendingPaymentVerifications();

      // Get pending payout requests
      final payoutService = PayoutService();
      final pendingPayouts = await payoutService.getAllPayoutRequests(status: 'pending');

      setState(() {
        _analytics = analytics;
        _recentActivities = activities;
        _pendingSubscriptionsCount = pendingSubscriptions.length;
        _pendingVerificationsCount = pendingVerifications.length;
        _unresolvedReportsCount = unresolvedReports.length;
        _pendingPaymentsCount = pendingPayments.length;
        _pendingPayoutsCount = pendingPayouts.length;
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
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimary),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: AppTheme.primaryGreen),
            onPressed: _showExportOptions,
            tooltip: 'Export Data',
          ),
          PopupMenuButton<String>(
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppTheme.errorRed),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: AppTheme.errorRed)),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              if (value == 'logout') {
                _handleLogout();
              } else if (value == 'settings') {
                context.push('/admin/settings');
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ModernLoadingWidget();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Error loading dashboard',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Overview
            const Text(
              'Platform Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Stats Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.2,
              children: [
                _buildClickableStatCard(
                  'Total Users',
                  _analytics?.totalUsers.toString() ?? '0',
                  Icons.people,
                  AppTheme.primaryGreen,
                  null, // No scroll target
                ),
                _buildClickableStatCard(
                  'Premium Users',
                  _analytics?.premiumUsers.toString() ?? '0',
                  Icons.star,
                  Colors.amber.shade700,
                  null, // No scroll target
                ),
                _buildClickableStatCard(
                  'Total Revenue',
                  '₱${_analytics?.totalRevenue.toStringAsFixed(2) ?? '0.00'}',
                  Icons.monetization_on,
                  AppTheme.secondaryGreen,
                  null, // No scroll target
                ),
                _buildClickableStatCard(
                  'Farmer Verifications',
                  _analytics?.pendingVerifications.toString() ?? '0',
                  Icons.verified_user,
                  AppTheme.primaryGreen,
                  _verificationsKey,
                ),
                _buildClickableStatCard(
                  'Content Moderation',
                  _unresolvedReportsCount.toString(),
                  Icons.flag,
                  AppTheme.errorRed,
                  _reportsKey,
                ),
                _buildClickableStatCard(
                  'Payment Verification',
                  _pendingPaymentsCount.toString(),
                  Icons.account_balance_wallet,
                  Colors.blue.shade600,
                  _paymentsKey,
                ),
                _buildClickableStatCard(
                  'Payout Requests',
                  _pendingPayoutsCount.toString(),
                  Icons.payments,
                  Colors.green.shade600,
                  _payoutsKey,
                ),
                _buildClickableStatCard(
                  'Subscriptions',
                  _pendingSubscriptionsCount.toString(),
                  Icons.star,
                  Colors.amber.shade700,
                  _subscriptionsKey,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Action Cards
            Container(
              key: _verificationsKey,
              child: _buildActionCardWithBadge(
                context,
                'Farmer Verifications',
                'Review and approve farmer applications',
                Icons.verified_user,
                AppTheme.primaryGreen,
                () => context.push('/admin/verifications'),
                badgeCount: _pendingVerificationsCount,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            _buildActionCard(
              context,
              'User Management',
              'Manage users and their permissions',
              Icons.manage_accounts,
              AppTheme.secondaryGreen,
              () => context.push('/admin/users'),
            ),

            const SizedBox(height: AppSpacing.md),

            _buildActionCard(
              context,
              'Reports & Analytics',
              'View platform statistics and reports',
              Icons.analytics,
              AppTheme.warningOrange,
              () => context.push('/admin/analytics'),
            ),

            const SizedBox(height: AppSpacing.md),

            Container(
              key: _reportsKey,
              child: _buildActionCardWithBadge(
                context,
                'Content Moderation',
                'Review flagged content and reports',
                Icons.flag,
                AppTheme.errorRed,
                () => context.push('/admin/reports'),
                badgeCount: _unresolvedReportsCount,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Container(
              key: _subscriptionsKey,
              child: _buildActionCardWithBadge(
                context,
                'Subscription Management',
                'Manage premium subscriptions and requests',
                Icons.star,
                Colors.amber.shade700,
                () => context.push('/admin/subscriptions'),
                badgeCount: _pendingSubscriptionsCount,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Container(
              key: _paymentsKey,
              child: _buildActionCardWithBadge(
                context,
                'Payment Verification',
                'Verify GCash payment proofs from buyers',
                Icons.account_balance_wallet,
                Colors.blue.shade600,
                () => context.push('/admin/payment-verification'),
                badgeCount: _pendingPaymentsCount,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Container(
              key: _payoutsKey,
              child: _buildActionCardWithBadge(
                context,
                'Payout Management',
                'Process farmer payout requests',
                Icons.payments,
                Colors.green.shade600,
                () => context.push('/admin/payouts'),
                badgeCount: _pendingPayoutsCount,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Analytics Charts Section
            const Text(
              'Analytics & Charts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_analytics != null) ...[
              // Revenue Chart
              AdminChartWidget(
                title: 'Revenue Trend (Last 7 Days)',
                data: _analytics!.revenueChart,
                chartType: 'revenue',
                height: 250,
              ),

              const SizedBox(height: AppSpacing.md),

              // Order Status Chart
              AdminChartWidget(
                title: 'Order Status Distribution',
                data: _analytics!.orderStatusChart,
                chartType: 'orderStatus',
                height: 200,
              ),

              const SizedBox(height: AppSpacing.md),

              // Category Sales Chart
              AdminChartWidget(
                title: 'Category Sales',
                data: _analytics!.categorySalesChart,
                chartType: 'categorySales',
                height: 250,
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Recent Activities Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/admin/activities'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (_recentActivities.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'No recent activities',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivities.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final activity = _recentActivities[index];
                  return _buildActivityTile(activity);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClickableStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    GlobalKey? scrollTarget,
  ) {
    return InkWell(
      onTap: scrollTarget != null ? () => _scrollToSection(scrollTarget) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: scrollTarget != null ? Border.all(color: color.withOpacity(0.3), width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightGrey),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCardWithBadge(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightGrey),
          boxShadow: badgeCount > 0
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.cardWhite,
                          width: 2,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeCount > 0) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: badgeCount > 0
                  ? color
                  : AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(AdminActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActivityColor(
            activity.type,
          ).withValues(alpha: 0.1),
          child: Icon(
            _getActivityIcon(activity.type),
            color: _getActivityColor(activity.type),
            size: 20,
          ),
        ),
        title: Text(
          activity.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity.description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatActivityTime(activity.timestamp),
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 16,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'verification':
        return AppTheme.primaryGreen;
      case 'user':
        return AppTheme.secondaryGreen;
      case 'order':
        return AppTheme.warningOrange;
      case 'system':
        return AppTheme.textSecondary;
      default:
        return AppTheme.primaryGreen;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'verification':
        return Icons.verified_user;
      case 'user':
        return Icons.person;
      case 'order':
        return Icons.shopping_cart;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }

  String _formatActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _handleLogout() async {
    // Prevent multiple dialogs if already in progress
    if (!mounted) return;
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );

    // Only proceed if user confirmed and widget is still mounted
    if (shouldLogout == true && mounted) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Logging out...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );

        // Sign out from auth service
        await _authService.signOut();
        
        // Clear any remaining state and navigate
        if (mounted) {
          // Use pushReplacement to clear navigation stack
          context.go('/login');
          
          // Show success message after a delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Logged out successfully'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Logout failed: ${e.toString()}'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Data',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Choose data type to export',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Export options
            _buildModernExportOption(
              'Users',
              'Export all users data',
              Icons.people_rounded,
              AppTheme.primaryGreen,
              () => _exportUsers(),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildModernExportOption(
              'Orders',
              'Export all orders data',
              Icons.shopping_cart_rounded,
              AppTheme.secondaryGreen,
              () => _exportOrders(),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildModernExportOption(
              'Verifications',
              'Export farmer verifications',
              Icons.verified_user_rounded,
              AppTheme.infoBlue,
              () => _exportVerifications(),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildModernExportOption(
              'Reports',
              'Export all reports',
              Icons.flag_rounded,
              AppTheme.warningOrange,
              () => _exportReports(),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildModernExportOption(
              'Analytics Summary',
              'Export platform analytics',
              Icons.analytics_rounded,
              AppTheme.successGreen,
              () => _exportAnalytics(),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.lightGrey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.download, color: AppTheme.primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildModernExportOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.15),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.file_download_outlined,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportUsers() async {
    try {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fetching users data...')));

      final users = await _adminService.getAllUsers();
      _downloadCSV('users', _convertUsersToCSV(users));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting users: $e')));
    }
  }

  Future<void> _exportOrders() async {
    try {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fetching orders data...')));
      // TODO: Implement orders export from admin service
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orders export coming soon')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting orders: $e')));
    }
  }

  Future<void> _exportVerifications() async {
    try {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetching verifications data...')),
      );

      final verifications = await _adminService.getAllVerifications();
      _downloadCSV('verifications', _convertVerificationsToCSV(verifications));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting verifications: $e')),
      );
    }
  }

  Future<void> _exportReports() async {
    try {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fetching reports data...')));

      final reports = await _adminService.getAllReports();
      _downloadCSV('reports', _convertReportsToCSV(reports));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting reports: $e')));
    }
  }

  Future<void> _exportAnalytics() async {
    try {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Exporting analytics...')));

      if (_analytics != null) {
        final csv = _convertAnalyticsToCSV(_analytics!);
        _downloadCSV('analytics', csv);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting analytics: $e')));
    }
  }

  String _convertUsersToCSV(List<AdminUserData> users) {
    final StringBuffer csv = StringBuffer();
    csv.writeln('ID,Name,Email,Type,Active,Phone,Address,Created At');

    for (final user in users) {
      csv.writeln(
        '"${user.id}","${user.name}","${user.email}","${user.userType}","${user.isActive}","${user.phoneNumber ?? ''}","${user.address ?? ''}","${user.createdAt.toIso8601String()}"',
      );
    }

    return csv.toString();
  }

  String _convertVerificationsToCSV(List<AdminVerificationData> verifications) {
    final StringBuffer csv = StringBuffer();
    csv.writeln('ID,Farmer Name,Email,Status,Submitted At,Reviewed At');

    for (final v in verifications) {
      csv.writeln(
        '"${v.id}","${v.userName}","${v.userEmail}","${v.status}","${v.submittedAt.toIso8601String()}","${v.reviewedAt?.toIso8601String() ?? ''}"',
      );
    }

    return csv.toString();
  }

  String _convertReportsToCSV(List<AdminReportData> reports) {
    final StringBuffer csv = StringBuffer();
    csv.writeln('ID,Reporter,Report Type,Status,Created At,Resolved At');

    for (final report in reports) {
      csv.writeln(
        '"${report.id}","${report.reporterName}","${report.reportType}","${report.status}","${report.createdAt.toIso8601String()}","${report.resolvedAt?.toIso8601String() ?? ''}"',
      );
    }

    return csv.toString();
  }

  String _convertAnalyticsToCSV(AdminAnalytics analytics) {
    final StringBuffer csv = StringBuffer();
    csv.writeln('Metric,Value');
    csv.writeln('Total Users,${analytics.totalUsers}');
    csv.writeln('Total Revenue,${analytics.totalRevenue}');
    csv.writeln('Active Orders,${analytics.activeOrders}');
    csv.writeln('Pending Verifications,${analytics.pendingVerifications}');
    csv.writeln('Total Products,${analytics.totalProducts}');
    csv.writeln('Export Date,${DateTime.now().toIso8601String()}');

    return csv.toString();
  }

  Future<void> _downloadCSV(String filename, String content) async {
    try {
      if (kIsWeb) {
        // Web implementation - would use html download
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Web export coming soon'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Android/iOS implementation
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), we don't need storage permission for app-specific directories
        // Request permission only if needed for older Android versions
        if (Platform.isAndroid) {
          // Try manageExternalStorage for Android 11+ or use app-specific directory
          var status = await Permission.manageExternalStorage.status;
          if (!status.isGranted) {
            // Don't request if denied, just use app-specific directory
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Using app storage. File will be saved in app directory.'),
                  backgroundColor: AppTheme.warningOrange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        }

        // For Android 13+ (API 33+), use manageExternalStorage or Documents directory
        Directory? directory;
        
        if (Platform.isAndroid) {
          // Try to get Downloads directory, fallback to Documents
          try {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              directory = await getExternalStorageDirectory();
            }
          } catch (e) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory == null) {
          throw Exception('Could not access storage directory');
        }

        // Create file with timestamp
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
        final filePath = '${directory.path}/agrilink_${filename}_$timestamp.csv';
        final file = File(filePath);

        // Write CSV content
        await file.writeAsString(content);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Exported to: $filePath'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        // iOS implementation
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
        final filePath = '${directory.path}/agrilink_${filename}_$timestamp.csv';
        final file = File(filePath);

        await file.writeAsString(content);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Exported to: $filePath'),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Export failed: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
