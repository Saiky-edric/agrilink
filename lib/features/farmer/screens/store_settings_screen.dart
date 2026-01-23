import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/store_management_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_widgets.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final StoreManagementService _storeService = StoreManagementService();
  final AuthService _authService = AuthService();

  StoreSettings? _storeSettings;
  bool _isLoading = true;
  bool _isSaving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadStoreSettings();
  }

  Future<void> _loadStoreSettings() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final settings = await _storeService.getStoreSettings(currentUser.id);
      
      setState(() {
        _storeSettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_storeSettings == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _storeService.updateStoreSettings(
        farmerId: currentUser.id,
        shippingMethods: _storeSettings!.shippingMethods,
        paymentMethods: _storeSettings!.paymentMethods,
        autoAcceptOrders: _storeSettings!.autoAcceptOrders,
        vacationMode: _storeSettings!.vacationMode,
        vacationMessage: _storeSettings!.vacationMessage,
        minOrderAmount: _storeSettings!.minOrderAmount,
        freeShippingThreshold: _storeSettings!.freeShippingThreshold,
        processingTimeDays: _storeSettings!.processingTimeDays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else if (_storeSettings != null)
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadStoreSettings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildSettingsContent(),
    );
  }

  Widget _buildSettingsContent() {
    if (_storeSettings == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info: Delivery & Transactions (Farmer)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.lightGrey),
            ),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Delivery & Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text(
                  'Delivery fees shown to buyers are computed by weight. '
                  'Ensure each product has a correct weight per unit (kg) for accurate fees. ',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                SizedBox(height: 8),
                Text(
                  'NO COMMISSION FEES! You keep 100% of your product sales. '
                  'Platform revenue comes from premium subscriptions only. Delivery fees are separate and paid by customers.',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          _buildPaymentMethodsCard(),
          const SizedBox(height: 16),
          _buildPickupSettingsCard(),
          const SizedBox(height: 16),
          _buildShippingMethodsCard(),
          const SizedBox(height: 16),
          _buildOrderSettingsCard(),
          const SizedBox(height: 16),
          _buildVacationModeCard(),
        ],
      ),
    );
  }

  Widget _buildPickupSettingsCard() {
    return Card(
      child: InkWell(
        onTap: () => context.push('/farmer/pickup-settings'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Pick-up Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Allow buyers to pick up orders from your location',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Payment Methods',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._storeSettings!.paymentMethods.entries.map((entry) {
              return CheckboxListTile(
                title: Text(entry.key),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    final updatedMethods = Map<String, bool>.from(_storeSettings!.paymentMethods);
                    updatedMethods[entry.key] = value ?? false;
                    _storeSettings = StoreSettings(
                      sellerId: _storeSettings!.sellerId,
                      shippingMethods: _storeSettings!.shippingMethods,
                      paymentMethods: updatedMethods,
                      autoAcceptOrders: _storeSettings!.autoAcceptOrders,
                      vacationMode: _storeSettings!.vacationMode,
                      vacationMessage: _storeSettings!.vacationMessage,
                      minOrderAmount: _storeSettings!.minOrderAmount,
                      freeShippingThreshold: _storeSettings!.freeShippingThreshold,
                      processingTimeDays: _storeSettings!.processingTimeDays,
                      createdAt: _storeSettings!.createdAt,
                      updatedAt: _storeSettings!.updatedAt,
                    );
                  });
                },
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingMethodsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Shipping Methods',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._storeSettings!.shippingMethods.asMap().entries.map((entry) {
              final index = entry.key;
              final method = entry.value;
              return ListTile(
                title: Text(method),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      final updatedMethods = List<String>.from(_storeSettings!.shippingMethods);
                      updatedMethods.removeAt(index);
                      _updateShippingMethods(updatedMethods);
                    });
                  },
                ),
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addShippingMethod,
              icon: const Icon(Icons.add),
              label: const Text('Add Shipping Method'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Order Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-accept Orders'),
              subtitle: const Text('Automatically accept incoming orders'),
              value: _storeSettings!.autoAcceptOrders,
              onChanged: (value) {
                setState(() {
                  _updateAutoAcceptOrders(value);
                });
              },
              activeThumbColor: AppTheme.primaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Minimum Order Amount'),
              subtitle: Text('₱${_storeSettings!.minOrderAmount.toStringAsFixed(2)}'),
              trailing: const Icon(Icons.edit),
              onTap: () => _editMinOrderAmount(),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              title: const Text('Free Shipping Threshold'),
              subtitle: Text('₱${_storeSettings!.freeShippingThreshold.toStringAsFixed(2)}'),
              trailing: const Icon(Icons.edit),
              onTap: () => _editFreeShippingThreshold(),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              title: const Text('Processing Time'),
              subtitle: Text('${_storeSettings!.processingTimeDays} day${_storeSettings!.processingTimeDays != 1 ? 's' : ''}'),
              trailing: const Icon(Icons.edit),
              onTap: () => _editProcessingTime(),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacationModeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _storeSettings!.vacationMode ? Icons.beach_access : Icons.business,
                  color: _storeSettings!.vacationMode ? Colors.orange : AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Vacation Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Vacation Mode'),
              subtitle: Text(
                _storeSettings!.vacationMode 
                    ? 'Store is temporarily closed'
                    : 'Store is accepting orders',
              ),
              value: _storeSettings!.vacationMode,
              onChanged: (value) {
                setState(() {
                  _updateVacationMode(value);
                });
              },
              activeThumbColor: Colors.orange,
              contentPadding: EdgeInsets.zero,
            ),
            if (_storeSettings!.vacationMode) ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _storeSettings!.vacationMessage ?? '',
                decoration: const InputDecoration(
                  labelText: 'Vacation Message',
                  hintText: 'Let customers know when you\'ll be back...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (value) {
                  _updateVacationMessage(value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateShippingMethods(List<String> methods) {
    _storeSettings = StoreSettings(
      sellerId: _storeSettings!.sellerId,
      shippingMethods: methods,
      paymentMethods: _storeSettings!.paymentMethods,
      autoAcceptOrders: _storeSettings!.autoAcceptOrders,
      vacationMode: _storeSettings!.vacationMode,
      vacationMessage: _storeSettings!.vacationMessage,
      minOrderAmount: _storeSettings!.minOrderAmount,
      freeShippingThreshold: _storeSettings!.freeShippingThreshold,
      processingTimeDays: _storeSettings!.processingTimeDays,
      createdAt: _storeSettings!.createdAt,
      updatedAt: _storeSettings!.updatedAt,
    );
  }

  void _updateAutoAcceptOrders(bool value) {
    _storeSettings = StoreSettings(
      sellerId: _storeSettings!.sellerId,
      shippingMethods: _storeSettings!.shippingMethods,
      paymentMethods: _storeSettings!.paymentMethods,
      autoAcceptOrders: value,
      vacationMode: _storeSettings!.vacationMode,
      vacationMessage: _storeSettings!.vacationMessage,
      minOrderAmount: _storeSettings!.minOrderAmount,
      freeShippingThreshold: _storeSettings!.freeShippingThreshold,
      processingTimeDays: _storeSettings!.processingTimeDays,
      createdAt: _storeSettings!.createdAt,
      updatedAt: _storeSettings!.updatedAt,
    );
  }

  void _updateVacationMode(bool value) {
    _storeSettings = StoreSettings(
      sellerId: _storeSettings!.sellerId,
      shippingMethods: _storeSettings!.shippingMethods,
      paymentMethods: _storeSettings!.paymentMethods,
      autoAcceptOrders: _storeSettings!.autoAcceptOrders,
      vacationMode: value,
      vacationMessage: value ? _storeSettings!.vacationMessage : null,
      minOrderAmount: _storeSettings!.minOrderAmount,
      freeShippingThreshold: _storeSettings!.freeShippingThreshold,
      processingTimeDays: _storeSettings!.processingTimeDays,
      createdAt: _storeSettings!.createdAt,
      updatedAt: _storeSettings!.updatedAt,
    );
  }

  void _updateVacationMessage(String message) {
    _storeSettings = StoreSettings(
      sellerId: _storeSettings!.sellerId,
      shippingMethods: _storeSettings!.shippingMethods,
      paymentMethods: _storeSettings!.paymentMethods,
      autoAcceptOrders: _storeSettings!.autoAcceptOrders,
      vacationMode: _storeSettings!.vacationMode,
      vacationMessage: message.isEmpty ? null : message,
      minOrderAmount: _storeSettings!.minOrderAmount,
      freeShippingThreshold: _storeSettings!.freeShippingThreshold,
      processingTimeDays: _storeSettings!.processingTimeDays,
      createdAt: _storeSettings!.createdAt,
      updatedAt: _storeSettings!.updatedAt,
    );
  }

  void _addShippingMethod() {
    showDialog(
      context: context,
      builder: (context) {
        String newMethod = '';
        return AlertDialog(
          title: const Text('Add Shipping Method'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Shipping Method',
              hintText: 'e.g., Same Day Delivery',
            ),
            onChanged: (value) => newMethod = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newMethod.trim().isNotEmpty) {
                  setState(() {
                    final updatedMethods = List<String>.from(_storeSettings!.shippingMethods);
                    updatedMethods.add(newMethod.trim());
                    _updateShippingMethods(updatedMethods);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editMinOrderAmount() {
    final controller = TextEditingController(
      text: _storeSettings!.minOrderAmount.toStringAsFixed(2),
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Minimum Order Amount'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (₱)',
              prefixText: '₱ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final amount = double.tryParse(controller.text) ?? 0.0;
                setState(() {
                  _storeSettings = StoreSettings(
                    sellerId: _storeSettings!.sellerId,
                    shippingMethods: _storeSettings!.shippingMethods,
                    paymentMethods: _storeSettings!.paymentMethods,
                    autoAcceptOrders: _storeSettings!.autoAcceptOrders,
                    vacationMode: _storeSettings!.vacationMode,
                    vacationMessage: _storeSettings!.vacationMessage,
                    minOrderAmount: amount,
                    freeShippingThreshold: _storeSettings!.freeShippingThreshold,
                    processingTimeDays: _storeSettings!.processingTimeDays,
                    createdAt: _storeSettings!.createdAt,
                    updatedAt: _storeSettings!.updatedAt,
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _editFreeShippingThreshold() {
    final controller = TextEditingController(
      text: _storeSettings!.freeShippingThreshold.toStringAsFixed(2),
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Free Shipping Threshold'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (₱)',
              prefixText: '₱ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final amount = double.tryParse(controller.text) ?? 500.0;
                setState(() {
                  _storeSettings = StoreSettings(
                    sellerId: _storeSettings!.sellerId,
                    shippingMethods: _storeSettings!.shippingMethods,
                    paymentMethods: _storeSettings!.paymentMethods,
                    autoAcceptOrders: _storeSettings!.autoAcceptOrders,
                    vacationMode: _storeSettings!.vacationMode,
                    vacationMessage: _storeSettings!.vacationMessage,
                    minOrderAmount: _storeSettings!.minOrderAmount,
                    freeShippingThreshold: amount,
                    processingTimeDays: _storeSettings!.processingTimeDays,
                    createdAt: _storeSettings!.createdAt,
                    updatedAt: _storeSettings!.updatedAt,
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _editProcessingTime() {
    final controller = TextEditingController(
      text: _storeSettings!.processingTimeDays.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Processing Time'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Days',
              suffix: Text('day(s)'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final days = int.tryParse(controller.text) ?? 1;
                setState(() {
                  _storeSettings = StoreSettings(
                    sellerId: _storeSettings!.sellerId,
                    shippingMethods: _storeSettings!.shippingMethods,
                    paymentMethods: _storeSettings!.paymentMethods,
                    autoAcceptOrders: _storeSettings!.autoAcceptOrders,
                    vacationMode: _storeSettings!.vacationMode,
                    vacationMessage: _storeSettings!.vacationMessage,
                    minOrderAmount: _storeSettings!.minOrderAmount,
                    freeShippingThreshold: _storeSettings!.freeShippingThreshold,
                    processingTimeDays: days,
                    createdAt: _storeSettings!.createdAt,
                    updatedAt: _storeSettings!.updatedAt,
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}