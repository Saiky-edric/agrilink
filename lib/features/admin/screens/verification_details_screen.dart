import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/farmer_verification_model.dart';
import '../../../core/services/farmer_verification_service.dart';
import '../../../core/services/admin_service.dart';
import '../../../shared/widgets/loading_widgets.dart';
import '../../../shared/widgets/error_widgets.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/document_viewer_widget.dart';

class VerificationDetailsScreen extends StatefulWidget {
  final String verificationId;

  const VerificationDetailsScreen({
    super.key,
    required this.verificationId,
  });

  @override
  State<VerificationDetailsScreen> createState() => _VerificationDetailsScreenState();
}

class _VerificationDetailsScreenState extends State<VerificationDetailsScreen> {
  final FarmerVerificationService _verificationService = FarmerVerificationService();
  final AdminService _adminService = AdminService();
  
  FarmerVerificationModel? _verification;
  bool _isLoading = true;
  String? _error;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadVerification();
  }

  Future<void> _loadVerification() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use AdminService to get verification by ID (not farmerId)
      final verificationData = await _adminService.getVerificationById(widget.verificationId);
      
      if (verificationData != null) {
        final verification = FarmerVerificationModel.fromJson(verificationData);
        setState(() {
          _verification = verification;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Verification not found';
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

  Future<void> _approveVerification() async {
    if (_verification == null) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('Approving verification: ${widget.verificationId}');
      
      // Use AdminService to approve verification
      await _adminService.approveVerification(
        widget.verificationId,
        adminNotes: 'Verification approved by admin',
      );
      
      debugPrint('Verification approval completed, reloading data...');
      await _loadVerification(); // Reload to get updated status
      
      // Also pop back to refresh the list
      if (mounted) {
        // Small delay to ensure database is updated
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification approved successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error approving verification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving verification: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectVerification() async {
    if (_verification == null) return;

    final reason = await _showRejectDialog();
    if (reason == null || reason.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      debugPrint('Rejecting verification: ${widget.verificationId} - $reason');
      
      // Use AdminService to reject verification
      await _adminService.rejectVerification(
        widget.verificationId,
        reason,
        adminNotes: 'Verification rejected by admin: $reason',
      );
      
      debugPrint('Verification rejection completed, reloading data...');
      await _loadVerification(); // Reload to get updated status
      
      // Also ensure database has time to update
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification rejected'),
            backgroundColor: AppTheme.warningOrange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting verification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting verification: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
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
          'Verification Details',
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorWidget(_error!)
              : _verification == null
                  ? const Center(child: Text('Verification not found'))
                  : _buildVerificationDetails(),
    );
  }

  Widget _buildVerificationDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _getStatusColor(_verification!.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(_verification!.status).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification #${_verification!.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(_verification!.status),
                      color: _getStatusColor(_verification!.status),
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _getStatusText(_verification!.status),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(_verification!.status),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Farmer information
          const Text(
            'Farmer Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.lightGrey),
            ),
            child: Column(
              children: [
                _buildInfoRow('Farm Name', _verification!.farmName),
                _buildInfoRow('Farm Address', _verification!.farmAddress),
                _buildInfoRow('Farmer ID', _verification!.farmerId),
                _buildInfoRow('Status', _getStatusText(_verification!.status)),
                _buildInfoRow('Submitted At', _formatDateTime(_verification!.createdAt)),
                if (_verification!.reviewedAt != null)
                  _buildInfoRow('Reviewed At', _formatDateTime(_verification!.reviewedAt!)),
                if (_verification!.rejectionReason != null)
                  _buildInfoRow('Rejection Reason', _verification!.rejectionReason!),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Documents
          const Text(
            'Supporting Documents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Placeholder document display
          if (false) ...[  // Always show placeholder text
            const Text(
              'No documents uploaded',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          if (_verification!.status == VerificationStatus.rejected && 
              _verification!.rejectionReason != null) ...[
            const SizedBox(height: AppSpacing.lg),
            
            const Text(
              'Rejection Reason',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
              ),
              child: Text(
                _verification!.rejectionReason!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],

          // Document section
          _buildDocumentSection(),

          const SizedBox(height: AppSpacing.xl),

          // Action buttons
          if (_verification!.status == VerificationStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Reject',
                    onPressed: _isProcessing ? null : _rejectVerification,
                    backgroundColor: AppTheme.errorRed,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CustomButton(
                    text: _isProcessing ? 'Processing...' : 'Approve',
                    onPressed: _isProcessing ? null : _approveVerification,
                    isLoading: _isProcessing,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
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
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return AppTheme.warningOrange;
      case VerificationStatus.approved:
        return AppTheme.successGreen;
      case VerificationStatus.rejected:
        return AppTheme.errorRed;
      case VerificationStatus.needsResubmit:
        return AppTheme.warningOrange;
    }
  }

  IconData _getStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return Icons.pending;
      case VerificationStatus.approved:
        return Icons.check_circle;
      case VerificationStatus.rejected:
        return Icons.cancel;
      case VerificationStatus.needsResubmit:
        return Icons.refresh;
    }
  }

  String _getStatusText(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return 'Pending Review';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.needsResubmit:
        return 'Needs Resubmit';
    }
  }

  Widget _buildDocumentSection() {
    if (_verification == null) return const SizedBox.shrink();
    
    final documents = <Map<String, String>>[];
    
    if (_verification!.farmerIdImageUrl.isNotEmpty) {
      documents.add({
        'title': 'Farmer ID / Government ID',
        'subtitle': 'Official government identification document',
        'url': _verification!.farmerIdImageUrl,
        'icon': 'id_card',
      });
    }
    
    if (_verification!.barangayCertImageUrl.isNotEmpty) {
      documents.add({
        'title': 'Barangay Certificate',
        'subtitle': 'Certificate of residency from local barangay',
        'url': _verification!.barangayCertImageUrl,
        'icon': 'certificate',
      });
    }
    
    if (_verification!.selfieImageUrl.isNotEmpty) {
      documents.add({
        'title': 'Verification Selfie',
        'subtitle': 'Photo holding identification for verification',
        'url': _verification!.selfieImageUrl,
        'icon': 'selfie',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Verification Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (documents.isEmpty)
          Card(
            child: Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Documents Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No verification documents were uploaded',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...documents.map((doc) => _buildDocumentCard(doc)),
      ],
    );
  }

  Widget _buildDocumentCard(Map<String, String> document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDocumentIcon(document['icon']!),
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document['title']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document['subtitle']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _viewDocument(document),
                  icon: const Icon(Icons.fullscreen),
                  tooltip: 'View full screen',
                ),
              ],
            ),
            const SizedBox(height: 12),
            DocumentViewerWidget(
              imageUrl: document['url']!,
              title: document['title']!,
              subtitle: document['subtitle'],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String iconType) {
    switch (iconType) {
      case 'id_card':
        return Icons.badge;
      case 'certificate':
        return Icons.verified;
      case 'selfie':
        return Icons.photo_camera;
      default:
        return Icons.document_scanner;
    }
  }

  void _viewDocument(Map<String, String> document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrl: document['url']!,
          title: document['title']!,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}