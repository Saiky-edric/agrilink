import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/payout_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/payout_request_model.dart';
import '../../../core/theme/app_theme.dart';

class RequestPayoutScreen extends StatefulWidget {
  final FarmerWalletSummary walletSummary;

  const RequestPayoutScreen({
    super.key,
    required this.walletSummary,
  });

  @override
  State<RequestPayoutScreen> createState() => _RequestPayoutScreenState();
}

class _RequestPayoutScreenState extends State<RequestPayoutScreen> {
  final PayoutService _payoutService = PayoutService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.gcash;
  Map<String, dynamic> _paymentDetails = {};
  bool _isLoadingPaymentDetails = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
    // Pre-fill with available balance
    _amountController.text = widget.walletSummary.availableBalance.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentDetails() async {
    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) return;

      final details = await _payoutService.getPaymentDetails(currentUser.id);
      
      setState(() {
        _paymentDetails = details;
        _isLoadingPaymentDetails = false;
        
        // Auto-select method based on available details
        if (details['gcash_number'] != null && details['gcash_number'].isNotEmpty) {
          _selectedMethod = PaymentMethod.gcash;
        } else if (details['bank_account_number'] != null && details['bank_account_number'].isNotEmpty) {
          _selectedMethod = PaymentMethod.bankTransfer;
        }
      });
    } catch (e) {
      setState(() => _isLoadingPaymentDetails = false);
    }
  }

  bool _hasGCashDetails() {
    return _paymentDetails['gcash_number'] != null && 
           _paymentDetails['gcash_number'].toString().isNotEmpty;
  }

  bool _hasBankDetails() {
    return _paymentDetails['bank_account_number'] != null && 
           _paymentDetails['bank_account_number'].toString().isNotEmpty;
  }

  Future<void> _submitPayoutRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate payment method has details
    if (_selectedMethod == PaymentMethod.gcash && !_hasGCashDetails()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your GCash details in Payment Settings'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_selectedMethod == PaymentMethod.bankTransfer && !_hasBankDetails()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add your bank details in Payment Settings'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) throw Exception('Not authenticated');

      final amount = double.parse(_amountController.text);

      // Prepare payment details based on method
      Map<String, dynamic> paymentDetailsToSend = {};
      
      if (_selectedMethod == PaymentMethod.gcash) {
        paymentDetailsToSend = {
          'gcash_number': _paymentDetails['gcash_number'],
          'gcash_name': _paymentDetails['gcash_name'],
        };
      } else {
        paymentDetailsToSend = {
          'bank_name': _paymentDetails['bank_name'],
          'bank_account_number': _paymentDetails['bank_account_number'],
          'bank_account_name': _paymentDetails['bank_account_name'],
        };
      }

      await _payoutService.requestPayout(
        farmerId: currentUser.id,
        amount: amount,
        paymentMethod: _selectedMethod,
        paymentDetails: paymentDetailsToSend,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout request submitted successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh wallet
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPaymentDetails) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Payout')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Request Payout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Available Balance Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.primaryGreen.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱${widget.walletSummary.availableBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Amount Input
            const Text(
              'Payout Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount (₱)',
                hintText: '100.00',
                prefixIcon: const Icon(Icons.payments),
                suffixIcon: TextButton(
                  onPressed: () {
                    _amountController.text = 
                        widget.walletSummary.availableBalance.toStringAsFixed(2);
                  },
                  child: const Text('MAX'),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid amount';
                }
                if (amount < 100) {
                  return 'Minimum payout is ₱100.00';
                }
                if (amount > widget.walletSummary.availableBalance) {
                  return 'Amount exceeds available balance';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Payment Method Selection
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // GCash Option
            _buildPaymentMethodTile(
              method: PaymentMethod.gcash,
              icon: Icons.phone_android,
              title: 'GCash',
              subtitle: _hasGCashDetails()
                  ? _paymentDetails['gcash_number']
                  : 'Not set up',
              enabled: _hasGCashDetails(),
            ),

            const SizedBox(height: 12),

            // Bank Transfer Option
            _buildPaymentMethodTile(
              method: PaymentMethod.bankTransfer,
              icon: Icons.account_balance,
              title: 'Bank Transfer',
              subtitle: _hasBankDetails()
                  ? '${_paymentDetails['bank_name']} - ${_paymentDetails['bank_account_number']}'
                  : 'Not set up',
              enabled: _hasBankDetails(),
            ),

            const SizedBox(height: 16),

            // Selected Payment Details Preview
            if ((_selectedMethod == PaymentMethod.gcash && _hasGCashDetails()) ||
                (_selectedMethod == PaymentMethod.bankTransfer && _hasBankDetails()))
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, 
                          color: Colors.blue.shade700, 
                          size: 20
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment will be sent to:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedMethod == PaymentMethod.gcash) ...[
                      _buildDetailRow('GCash Number', _paymentDetails['gcash_number']),
                      _buildDetailRow('Account Name', _paymentDetails['gcash_name']),
                    ] else ...[
                      _buildDetailRow('Bank', _paymentDetails['bank_name']),
                      _buildDetailRow('Account Number', _paymentDetails['bank_account_number']),
                      _buildDetailRow('Account Name', _paymentDetails['bank_account_name']),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Optional Notes
            const Text(
              'Notes (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'e.g., Please send before 5 PM',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              maxLength: 200,
            ),

            const SizedBox(height: 24),

            // Important Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Processing Time',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Payouts are processed manually within 24 hours\n'
                    '• You will be notified when payment is sent\n'
                    '• Make sure your payment details are correct',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPayoutRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Payout Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: enabled
          ? () => setState(() => _selectedMethod = method)
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected && enabled
                ? AppTheme.primaryGreen
                : Colors.grey.shade300,
            width: isSelected && enabled ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: enabled
                    ? AppTheme.primaryGreen.withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: enabled ? AppTheme.primaryGreen : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.black : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: enabled ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              Radio<PaymentMethod>(
                value: method,
                groupValue: _selectedMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMethod = value);
                  }
                },
                activeColor: AppTheme.primaryGreen,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
