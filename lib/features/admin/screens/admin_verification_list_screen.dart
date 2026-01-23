import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/models/admin_analytics_model.dart';
import '../../../shared/widgets/custom_button.dart';
import 'verification_details_screen.dart';

class AdminVerificationListScreen extends StatefulWidget {
  const AdminVerificationListScreen({super.key});

  @override
  State<AdminVerificationListScreen> createState() =>
      _AdminVerificationListScreenState();
}

class _AdminVerificationListScreenState
    extends State<AdminVerificationListScreen> {
  final AdminService _adminService = AdminService();

  List<AdminVerificationData> _verifications = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  Future<void> _loadVerifications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<AdminVerificationData> verifications;
      
      // Use the correct method from AdminService
      verifications = await _adminService.getAllVerifications(statusFilter: _selectedStatus);

      setState(() {
        _verifications = verifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading verifications: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveVerification(AdminVerificationData verification) async {
    try {
      await _adminService.approveVerification(
        verification.id,
        adminNotes: 'Approved by admin',
      );

      // Force refresh with delay to ensure database is updated
      await Future.delayed(const Duration(milliseconds: 1000));
      await _loadVerifications();
      
      // Auto-switch to approved tab to show the result
      setState(() {
        _selectedStatus = 'approved';
      });
      await _loadVerifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification approved! Switched to Approved tab to show result.'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error approving verification: $e');
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

  Future<void> _rejectVerification(AdminVerificationData verification) async {
    final reason = await _showRejectDialog();
    if (reason == null || reason.isEmpty) return;

    try {
      await _adminService.rejectVerification(
        verification.id,
        reason,
        adminNotes: 'Rejected by admin: $reason',
      );

      // Force refresh with delay to ensure database is updated
      await Future.delayed(const Duration(milliseconds: 1000));
      await _loadVerifications();
      
      // Auto-switch to rejected tab to show the result
      setState(() {
        _selectedStatus = 'rejected';
      });
      await _loadVerifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification rejected! Switched to Rejected tab to show result.'),
            backgroundColor: AppTheme.warningOrange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error rejecting verification: $e');
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

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter rejection reason...',
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
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Reject'),
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
          'Farmer Verifications',
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
            onPressed: _loadVerifications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter
          _buildStatusFilter(),

          // Verifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorWidget()
                : _buildVerificationsList(),
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
          const Text(
            'Error loading verifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(text: 'Retry', onPressed: _loadVerifications),
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
            _buildFilterChip('approved', 'Approved', AppTheme.successGreen),
            _buildFilterChip('rejected', 'Rejected', AppTheme.errorRed),
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
          _loadVerifications();
        },
        selectedColor: color.withValues(alpha: 0.2),
        checkmarkColor: color,
      ),
    );
  }

  Widget _buildVerificationsList() {
    if (_verifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No verifications found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'No ${_selectedStatus == 'all' ? '' : _selectedStatus} verifications at the moment',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _verifications.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) =>
          _buildVerificationCard(_verifications[index]),
    );
  }

  Widget _buildVerificationCard(AdminVerificationData verification) {
    final status = verification.status;
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onTap: () => _navigateToDetails(verification.id),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with farmer info and status
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verification.userName.isNotEmpty ? verification.userName : 'Unknown Farmer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        verification.userEmail.isNotEmpty ? verification.userEmail : 'No email',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
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

            // Farm details
            _buildDetailRow('Farm Name', verification.farmName ?? 'Not specified'),
            _buildDetailRow('Farm Address', verification.farmAddress ?? 'Not specified'),

            const SizedBox(height: AppSpacing.md),

            // Documents indicator
            Row(
              children: [
                const Icon(Icons.document_scanner, size: 16, color: AppTheme.primaryGreen),
                const SizedBox(width: 4),
                Text(
                  'Verification Documents (${verification.documents.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Review notes if rejected/approved
            if (status != 'pending' && verification.reviewNotes != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: status == 'rejected'
                      ? AppTheme.errorRed.withOpacity(0.1)
                      : AppTheme.successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${status.toUpperCase()} - Review Notes:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: status == 'rejected'
                            ? AppTheme.errorRed
                            : AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      verification.reviewNotes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Action buttons for pending verifications
            if (status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      onPressed: () => _rejectVerification(verification),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      onPressed: () => _approveVerification(verification),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Submitted ${_formatDate(verification.submittedAt)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                TextButton.icon(
                  onPressed: () => _navigateToDetails(verification.id),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(String verificationId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VerificationDetailsScreen(
          verificationId: verificationId,
        ),
      ),
    ).then((_) {
      // Reload verifications when returning from details
      _loadVerifications();
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.successGreen;
      case 'rejected':
        return AppTheme.errorRed;
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
}
