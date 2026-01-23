import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/report_service.dart';
import 'custom_button.dart';

class ReportDialog extends StatefulWidget {
  final String targetId;
  final String targetType; // 'product', 'user', 'order'
  final String targetName;

  const ReportDialog({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ReportService _reportService = ReportService();
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _selectedReason;
  bool _isSubmitting = false;

  final Map<String, List<String>> _reportReasons = {
    'product': [
      'Misleading information',
      'Fake or counterfeit product',
      'Inappropriate content',
      'Prohibited item',
      'Price manipulation',
      'Other',
    ],
    'user': [
      'Spam or scam',
      'Harassment or bullying',
      'Impersonation',
      'Inappropriate behavior',
      'Fraudulent activity',
      'Other',
    ],
    'order': [
      'Payment issue',
      'Delivery problem',
      'Product quality mismatch',
      'Seller unresponsive',
      'Fraudulent transaction',
      'Other',
    ],
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a description'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reportService.submitReport(
        targetId: widget.targetId,
        type: widget.targetType,
        reason: _selectedReason!,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully. We will review it soon.'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reasons = _reportReasons[widget.targetType] ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    color: AppTheme.errorRed,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Report ${_formatType(widget.targetType)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Target info
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIconForType(widget.targetType),
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.targetName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Reason selection
              const Text(
                'Reason for reporting',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              
              ...reasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: _isSubmitting ? null : (value) {
                  setState(() => _selectedReason = value);
                },
                activeColor: AppTheme.primaryGreen,
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),

              const SizedBox(height: AppSpacing.lg),

              // Description
              const Text(
                'Additional details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 500,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Please provide more details about your report...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundWhite,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Info message
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.infoBlue.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.infoBlue,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Your report will be reviewed by our team. False reports may result in account restrictions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.infoBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      backgroundColor: AppTheme.lightGrey,
                      textColor: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomButton(
                      text: _isSubmitting ? 'Submitting...' : 'Submit Report',
                      onPressed: _isSubmitting ? null : _submitReport,
                      backgroundColor: AppTheme.errorRed,
                      isLoading: _isSubmitting,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'product':
        return Icons.inventory_2_outlined;
      case 'user':
        return Icons.person_outline;
      case 'order':
        return Icons.receipt_long_outlined;
      default:
        return Icons.flag_outlined;
    }
  }
}

/// Helper function to show report dialog
Future<bool?> showReportDialog(
  BuildContext context, {
  required String targetId,
  required String targetType,
  required String targetName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ReportDialog(
      targetId: targetId,
      targetType: targetType,
      targetName: targetName,
    ),
  );
}
