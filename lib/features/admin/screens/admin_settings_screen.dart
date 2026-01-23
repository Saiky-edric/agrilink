import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/admin_service.dart';
import '../../../shared/widgets/custom_button.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final AdminService _adminService = AdminService();
  
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  String? _error;

  // Setting controllers
  final _commissionRateController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _jtPer2kgController = TextEditingController();
  final _maxOrderValueController = TextEditingController();
  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  bool _requireVerification = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _commissionRateController.dispose();
    _deliveryFeeController.dispose();
    _jtPer2kgController.dispose();
    _maxOrderValueController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final settings = await _adminService.getPlatformSettings();
      
      setState(() {
        _settings = settings;
        _commissionRateController.text = (settings['commission_rate'] ?? '5.0').toString();
        _deliveryFeeController.text = (settings['delivery_fee'] ?? '50.0').toString();
        _jtPer2kgController.text = (settings['jt_per2kg_fee'] ?? '25.0').toString();
        _maxOrderValueController.text = (settings['max_order_value'] ?? '10000').toString();
        _maintenanceMode = settings['maintenance_mode'] ?? false;
        _allowNewRegistrations = settings['allow_new_registrations'] ?? true;
        _requireVerification = settings['require_verification'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await _adminService.updatePlatformSetting(key, value);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setting updated: $key'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating setting: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _saveAllSettings() async {
    final settingsToUpdate = {
      'commission_rate': 0.0, // Always 0 - subscription-based revenue model
      'delivery_fee': double.tryParse(_deliveryFeeController.text) ?? 50.0,
        'jt_per2kg_fee': double.tryParse(_jtPer2kgController.text) ?? 25.0,
      'max_order_value': double.tryParse(_maxOrderValueController.text) ?? 10000,
      'maintenance_mode': _maintenanceMode,
      'allow_new_registrations': _allowNewRegistrations,
      'require_verification': _requireVerification,
    };

    for (final entry in settingsToUpdate.entries) {
      await _updateSetting(entry.key, entry.value);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All settings saved successfully!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Platform Settings',
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
          TextButton(
            onPressed: _isLoading ? null : _saveAllSettings,
            child: const Text(
              'Save All',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildSettingsContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
          const SizedBox(height: AppSpacing.md),
          const Text('Error loading settings'),
          Text(_error!),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(text: 'Retry', onPressed: _loadSettings),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform Configuration
          _buildSettingsSection(
            'Platform Configuration',
            [
              _buildSwitchSetting(
                'Maintenance Mode',
                'Enable to put the platform in maintenance mode',
                _maintenanceMode,
                (value) {
                  setState(() => _maintenanceMode = value);
                  _updateSetting('maintenance_mode', value);
                },
                AppTheme.errorRed,
              ),
              _buildSwitchSetting(
                'Allow New Registrations',
                'Allow new users to register on the platform',
                _allowNewRegistrations,
                (value) {
                  setState(() => _allowNewRegistrations = value);
                  _updateSetting('allow_new_registrations', value);
                },
                AppTheme.primaryGreen,
              ),
              _buildSwitchSetting(
                'Require Farmer Verification',
                'Require farmers to complete verification before selling',
                _requireVerification,
                (value) {
                  setState(() => _requireVerification = value);
                  _updateSetting('require_verification', value);
                },
                AppTheme.warningOrange,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Business Settings
          _buildSettingsSection(
            'Business Settings',
            [
              // COMMISSION RATE REMOVED - Subscription-based revenue model only
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💰 Revenue Model: Subscription-Based',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'NO COMMISSION FEES! Platform revenue comes from premium farmer subscriptions only. '
                            'Farmers keep 100% of their product sales.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Deprecated: Default Delivery Fee is no longer used (weight-based J&T fees)
              _buildTextFieldSetting(
                'J&T Fee per 2kg above 8kg (₱)',
                'Increment used when total weight exceeds 8kg',
                _jtPer2kgController,
                'jt_per2kg_fee',
                prefix: '₱',
              ),
              _buildTextFieldSetting(
                'Maximum Order Value (₱)',
                'Maximum allowed order value',
                _maxOrderValueController,
                'max_order_value',
                prefix: '₱',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // System Information
          _buildSettingsSection(
            'System Information',
            [
              _buildInfoCard('App Version', 'v1.0.0'),
              _buildInfoCard('Database Status', 'Connected'),
              _buildInfoCard('Last Updated', _formatLastUpdate()),
              _buildInfoCard('Total Settings', '${_settings.length}'),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // Danger Zone
          _buildDangerSection(),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.lightGrey, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.settings, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldSetting(
    String title,
    String subtitle,
    TextEditingController controller,
    String settingKey, {
    String? prefix,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.lightGrey, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              prefixText: prefix,
              suffixText: suffix,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (value) {
              final numValue = double.tryParse(value);
              if (numValue != null) {
                _updateSetting(settingKey, numValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.lightGrey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danger Zone',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.errorRed,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reset Platform Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorRed,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'This will reset all platform settings to their default values. This action cannot be undone.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CustomButton(
                text: 'Reset All Settings',
                onPressed: _showResetConfirmation,
                backgroundColor: AppTheme.errorRed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all platform settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetAllSettings();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllSettings() async {
    // Reset to default values
    _commissionRateController.text = '0.0'; // Always 0 - no commission
    _deliveryFeeController.text = '50.0';
    _maxOrderValueController.text = '10000';
    setState(() {
      _maintenanceMode = false;
      _allowNewRegistrations = true;
      _requireVerification = true;
    });

    await _saveAllSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All settings have been reset to defaults'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
    }
  }

  String _formatLastUpdate() {
    return DateTime.now().toString().split('.')[0];
  }
}