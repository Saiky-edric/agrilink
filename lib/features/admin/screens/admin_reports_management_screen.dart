import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/admin_analytics_model.dart';
import '../../../core/services/admin_service.dart';
import '../../../shared/widgets/custom_button.dart';

class AdminReportsManagementScreen extends StatefulWidget {
  const AdminReportsManagementScreen({super.key});

  @override
  State<AdminReportsManagementScreen> createState() =>
      _AdminReportsManagementScreenState();
}

class _AdminReportsManagementScreenState
    extends State<AdminReportsManagementScreen> {
  final AdminService _adminService = AdminService();

  List<AdminReportData> _reports = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final reports = await _adminService.getAllReports(
        statusFilter: _selectedStatus,
      );

      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _resolveReport(AdminReportData report, String resolution) async {
    final notes = await _showResolutionDialog(resolution);
    if (notes == null) return;

    try {
      await _adminService.resolveReport(report.id, resolution, notes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report ${resolution.toLowerCase()} successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<String?> _showResolutionDialog(String action) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide notes for this $action:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter notes...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(
                controller.text.trim().isEmpty
                    ? 'No notes provided'
                    : controller.text.trim(),
              );
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Reports Management',
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
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorWidget()
                : _buildReportsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
          const SizedBox(height: AppSpacing.md),
          const Text('Error loading reports'),
          Text(_error!),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(text: 'Retry', onPressed: _loadReports),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('pending', 'Pending', AppTheme.warningOrange),
            _buildFilterChip('resolved', 'Resolved', AppTheme.successGreen),
            _buildFilterChip('dismissed', 'Dismissed', AppTheme.textSecondary),
            _buildFilterChip('all', 'All', AppTheme.infoBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _selectedStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedStatus = value);
          _loadReports();
        },
        selectedColor: color.withValues(alpha: 0.2),
        checkmarkColor: color,
      ),
    );
  }

  Widget _buildReportsList() {
    if (_reports.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: AppTheme.textSecondary),
            SizedBox(height: AppSpacing.md),
            Text('No reports found'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _reports.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _buildReportCard(_reports[index]),
    );
  }

  Widget _buildReportCard(AdminReportData report) {
    final statusColor = _getStatusColor(report.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: statusColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  report.reason,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            report.description,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text('Reporter: ${report.reporterName}')),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                Icons.category,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text('Type: ${report.reportType}'),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Target Information with Investigation Link
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForTargetType(report.targetType),
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reported ${report.targetType}: ${report.targetName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _investigateTarget(report),
                  icon: const Icon(Icons.search, size: 16),
                  label: Text('Investigate ${_getTargetTypeLabel(report.targetType)}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                    side: BorderSide(color: AppTheme.primaryGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ),

          if (report.resolution != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resolution:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(report.resolution!),
                ],
              ),
            ),
          ],

          if (report.status == 'pending') ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Dismiss',
                    onPressed: () => _resolveReport(report, 'dismissed'),
                    backgroundColor: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CustomButton(
                    text: 'Resolve',
                    onPressed: () => _resolveReport(report, 'resolved'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.sm),
          Text(
            'Reported ${_formatDate(report.createdAt)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return AppTheme.successGreen;
      case 'dismissed':
        return AppTheme.textSecondary;
      case 'pending':
      default:
        return AppTheme.warningOrange;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  IconData _getIconForTargetType(String type) {
    switch (type.toLowerCase()) {
      case 'product':
        return Icons.inventory_2;
      case 'user':
        return Icons.person;
      case 'order':
        return Icons.receipt_long;
      default:
        return Icons.help_outline;
    }
  }

  String _getTargetTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'product':
        return 'Product';
      case 'user':
        return 'User Profile';
      case 'order':
        return 'Order';
      default:
        return 'Item';
    }
  }

  void _investigateTarget(AdminReportData report) {
    final targetType = report.targetType.toLowerCase();
    final targetId = report.targetId;

    try {
      switch (targetType) {
        case 'product':
          // Navigate to product details
          context.push('/buyer/product/$targetId');
          break;
        case 'user':
          // Navigate to public farmer profile
          context.push('/farmer/profile/$targetId');
          break;
        case 'order':
          // Navigate to order details - you can choose buyer or farmer view
          // For admin investigation, buyer view is typically better
          context.push('/buyer/orders/$targetId');
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot investigate this type of report'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}
