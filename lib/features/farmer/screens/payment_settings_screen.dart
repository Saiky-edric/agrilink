import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/payout_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final PayoutService _payoutService = PayoutService();
  final _formKey = GlobalKey<FormState>();

  // GCash fields
  final _gcashNumberController = TextEditingController();
  final _gcashNameController = TextEditingController();

  // Bank fields
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountNameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  @override
  void dispose() {
    _gcashNumberController.dispose();
    _gcashNameController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountNameController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentDetails() async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) return;

      final details = await _payoutService.getPaymentDetails(currentUser.id);

      setState(() {
        _gcashNumberController.text = details['gcash_number'] ?? '';
        _gcashNameController.text = details['gcash_name'] ?? '';
        _bankNameController.text = details['bank_name'] ?? '';
        _bankAccountNumberController.text = details['bank_account_number'] ?? '';
        _bankAccountNameController.text = details['bank_account_name'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payment details: $e')),
        );
      }
    }
  }

  Future<void> _savePaymentDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      await _payoutService.updatePaymentDetails(currentUser.id, {
        'gcash_number': _gcashNumberController.text.trim(),
        'gcash_name': _gcashNameController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'bank_account_number': _bankAccountNumberController.text.trim(),
        'bank_account_name': _bankAccountNameController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment details saved successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving payment details: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePaymentDetails,
              child: const Text(
                'SAVE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add your payment details to receive payouts. You can add both GCash and bank account.',
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // GCash Section
            _buildSectionHeader('GCash', Icons.phone_android),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gcashNumberController,
              decoration: InputDecoration(
                labelText: 'GCash Number',
                hintText: '09171234567',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return null;
                if (!value.startsWith('09')) {
                  return 'Must start with 09';
                }
                if (value.length != 11) {
                  return 'Must be 11 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gcashNameController,
              decoration: InputDecoration(
                labelText: 'Account Name',
                hintText: 'Juan Dela Cruz',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (_gcashNumberController.text.isNotEmpty && 
                    (value == null || value.isEmpty)) {
                  return 'Account name is required when GCash number is provided';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Bank Section
            _buildSectionHeader('Bank Account', Icons.account_balance),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: InputDecoration(
                labelText: 'Bank Name',
                hintText: 'BDO, BPI, Metrobank, etc.',
                prefixIcon: const Icon(Icons.account_balance),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankAccountNumberController,
              decoration: InputDecoration(
                labelText: 'Account Number',
                hintText: '1234567890',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (_bankNameController.text.isNotEmpty &&
                    (value == null || value.isEmpty)) {
                  return 'Account number is required when bank name is provided';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankAccountNameController,
              decoration: InputDecoration(
                labelText: 'Account Name',
                hintText: 'Juan Dela Cruz',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (_bankAccountNumberController.text.isNotEmpty &&
                    (value == null || value.isEmpty)) {
                  return 'Account name is required when account number is provided';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Security note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment information is stored securely and only used for payouts.',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
