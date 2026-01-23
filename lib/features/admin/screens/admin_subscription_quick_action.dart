import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/models/user_model.dart';
import 'package:intl/intl.dart';

/// Quick action dialog for admin to manage user subscriptions
class AdminSubscriptionQuickAction {
  static final SubscriptionService _subscriptionService = SubscriptionService();

  /// Show quick action dialog for subscription management
  static Future<void> show(BuildContext context, UserModel user) async {
    return showDialog(
      context: context,
      builder: (context) => _SubscriptionQuickActionDialog(user: user),
    );
  }
}

class _SubscriptionQuickActionDialog extends StatefulWidget {
  final UserModel user;

  const _SubscriptionQuickActionDialog({required this.user});

  @override
  State<_SubscriptionQuickActionDialog> createState() => _SubscriptionQuickActionDialogState();
}

class _SubscriptionQuickActionDialogState extends State<_SubscriptionQuickActionDialog> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _daysController = TextEditingController(text: '30');
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  bool _isProcessing = false;
  String _selectedAction = 'activate'; // activate, extend, downgrade

  @override
  void dispose() {
    _daysController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = widget.user.isPremium;
    final expiresAt = widget.user.subscriptionExpiresAt;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Manage Subscription',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isPremium
                              ? AppTheme.primaryGreen.withOpacity(0.1)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPremium ? Icons.star : Icons.person,
                              size: 14,
                              color: isPremium
                                  ? AppTheme.primaryGreen
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPremium ? 'Premium' : 'Free',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPremium
                                    ? AppTheme.primaryGreen
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (isPremium && expiresAt != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expires: ${DateFormat('MMM dd, yyyy').format(expiresAt)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${expiresAt.difference(DateTime.now()).inDays} days left)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: expiresAt.difference(DateTime.now()).inDays < 7
                                ? Colors.orange
                                : AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action Selection
            const Text(
              'Select Action',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            
            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  label: 'Activate Premium',
                  icon: Icons.star,
                  value: 'activate',
                  enabled: !isPremium,
                ),
                _buildActionChip(
                  label: 'Extend Subscription',
                  icon: Icons.update,
                  value: 'extend',
                  enabled: isPremium,
                ),
                _buildActionChip(
                  label: 'Downgrade to Free',
                  icon: Icons.arrow_downward,
                  value: 'downgrade',
                  enabled: isPremium,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Action-specific inputs
            if (_selectedAction == 'activate' || _selectedAction == 'extend') ...[
              TextField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: _selectedAction == 'activate'
                      ? 'Duration (days)'
                      : 'Additional Days',
                  prefixIcon: const Icon(Icons.calendar_month),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hintText: '30',
                  helperText: '1 month = 30 days, 3 months = 90 days, 1 year = 365 days',
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Payment Reference (Optional)',
                prefixIcon: const Icon(Icons.receipt_long),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'e.g., GCash-REF123',
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Admin Notes (Optional)',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Internal notes about this action',
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Warning for downgrade
            if (_selectedAction == 'downgrade')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This will immediately downgrade the user to Free tier (max 5 products)',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedAction == 'downgrade'
                ? Colors.orange
                : AppTheme.primaryGreen,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _selectedAction == 'activate'
                      ? 'Activate Premium'
                      : _selectedAction == 'extend'
                          ? 'Extend Subscription'
                          : 'Downgrade Now',
                ),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required String value,
    bool enabled = true,
  }) {
    final isSelected = _selectedAction == value;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: !enabled
                ? Colors.grey.shade400
                : isSelected
                    ? Colors.white
                    : AppTheme.primaryGreen,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: enabled
          ? (selected) {
              setState(() => _selectedAction = value);
            }
          : null,
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: enabled ? Colors.white : Colors.grey.shade100,
      labelStyle: TextStyle(
        color: !enabled
            ? Colors.grey.shade400
            : isSelected
                ? Colors.white
                : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: !enabled
            ? Colors.grey.shade300
            : isSelected
                ? AppTheme.primaryGreen
                : Colors.grey.shade300,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _isProcessing = true);

    try {
      bool success = false;
      
      switch (_selectedAction) {
        case 'activate':
          final days = int.tryParse(_daysController.text) ?? 30;
          success = await _subscriptionService.activatePremiumSubscription(
            userId: widget.user.id,
            durationDays: days,
            paymentReference: _referenceController.text.trim().isEmpty
                ? null
                : _referenceController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
          break;
          
        case 'extend':
          final days = int.tryParse(_daysController.text) ?? 30;
          success = await _subscriptionService.extendSubscription(
            userId: widget.user.id,
            additionalDays: days,
          );
          break;
          
        case 'downgrade':
          success = await _subscriptionService.downgradeToFree(
            userId: widget.user.id,
            reason: _notesController.text.trim().isEmpty
                ? 'Downgraded by admin'
                : _notesController.text.trim(),
          );
          break;
      }

      if (mounted) {
        Navigator.pop(context, success);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedAction == 'activate'
                          ? 'Premium subscription activated successfully!'
                          : _selectedAction == 'extend'
                              ? 'Subscription extended successfully!'
                              : 'User downgraded to Free tier',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
