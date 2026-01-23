import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../../../core/models/farmer_verification_model.dart';
import '../../../core/services/farmer_verification_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/router/route_names.dart';
import '../../../shared/widgets/custom_button.dart';

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  final _verificationService = FarmerVerificationService();
  final _authService = AuthService();
  FarmerVerificationModel? _verification;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = _authService.currentUser!.id;
      final verification = await _verificationService.getVerificationStatus(userId);

      _verification = verification;
    } catch (e) {
      _error = 'Failed to load verification status: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.approved:
        return Colors.green;
      case VerificationStatus.rejected:
        return Colors.red;
      case VerificationStatus.needsResubmit:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return Icons.access_time;
      case VerificationStatus.approved:
        return Icons.check_circle;
      case VerificationStatus.rejected:
        return Icons.cancel;
      case VerificationStatus.needsResubmit:
        return Icons.refresh;
    }
  }

  Widget _buildStatusCard() {
    if (_verification == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.upload_file,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'No Verification Submitted',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You haven\'t submitted your farmer verification yet. Complete the verification process to start selling your products.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: () => context.push(RouteNames.uploadVerification),
                text: 'Start Verification',
                icon: Icons.upload,
              ),
            ],
          ),
        ),
      );
    }

    final status = _verification!.status;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Use Lottie for pending and rejected, Icon for approved
            if (status == VerificationStatus.pending)
              Lottie.asset(
                'assets/lottie/pending_verification.json',
                width: 200,
                height: 200,
              )
            else if (status == VerificationStatus.rejected)
              Lottie.asset(
                'assets/lottie/verification_rejected.json',
                width: 200,
                height: 200,
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  size: 48,
                  color: statusColor,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              _verification!.statusDisplayName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getStatusMessage(status),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            if (_verification!.rejectionReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rejection Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_verification!.rejectionReason!),
                  ],
                ),
              ),
            ],
            if (_verification!.adminNotes != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_verification!.adminNotes!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusMessage(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.pending:
        return 'Your verification is being reviewed by our team. You\'ll be notified once it\'s processed.';
      case VerificationStatus.approved:
        return 'Congratulations! Your farmer verification has been approved. You can now start selling products.';
      case VerificationStatus.rejected:
        return 'Your verification was rejected. Please review the feedback and submit a new verification.';
      case VerificationStatus.needsResubmit:
        return 'Please resubmit your verification with the requested changes.';
    }
  }

  Widget _buildDetailsCard() {
    if (_verification == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Farm Name', _verification!.farmName),
            _buildDetailRow('Farm Address', _verification!.farmAddress),
            _buildDetailRow('Submitted', 
              '${_verification!.createdAt.day}/${_verification!.createdAt.month}/${_verification!.createdAt.year}'),
            if (_verification!.reviewedAt != null)
              _buildDetailRow('Reviewed', 
                '${_verification!.reviewedAt!.day}/${_verification!.reviewedAt!.month}/${_verification!.reviewedAt!.year}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Status'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadVerificationStatus,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadVerificationStatus,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildDetailsCard(),
                        if (_verification != null && 
                            (_verification!.isRejected || _verification!.needsResubmit)) ...[
                          const SizedBox(height: 24),
                          CustomButton(
                            onPressed: () => context.push(RouteNames.uploadVerification),
                            text: 'Resubmit Verification',
                            icon: Icons.refresh,
                            isFullWidth: true,
                          ),
                        ],
                        if (_verification != null && _verification!.isApproved) ...[
                          const SizedBox(height: 24),
                          CustomButton(
                            onPressed: () => context.push(RouteNames.productList),
                            text: 'Manage Products',
                            icon: Icons.inventory,
                            isFullWidth: true,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            // Smart navigation - check if we can pop back
                            if (Navigator.of(context).canPop()) {
                              context.pop();
                            } else {
                              // If accessed directly, go to farmer dashboard
                              context.go(RouteNames.farmerDashboard);
                            }
                          },
                          child: const Text('Back to Dashboard'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}