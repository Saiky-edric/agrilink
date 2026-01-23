import 'dart:convert';
import 'package:http/http.dart' as http;

class GCashService {
  // GCash API endpoints (use sandbox for testing)
  static const String baseUrl = 'https://api.gcash.com'; // Replace with actual API URL
  static const String apiKey = 'YOUR_GCASH_API_KEY'; // Replace with your API key
  static const String merchantId = 'YOUR_MERCHANT_ID'; // Replace with your merchant ID
  
  // Create payment link for GCash
  Future<Map<String, dynamic>> createPaymentLink({
    required double amount,
    required String orderId,
    required String description,
    String currency = 'PHP',
  }) async {
    try {
      final requestBody = {
        'data': {
          'attributes': {
            'amount': (amount * 100).toInt(), // Convert to cents
            'currency': currency,
            'description': description,
            'statement_descriptor': 'AGRILINK',
            'redirect': {
              'success': 'https://yourapp.com/payment/success',
              'failed': 'https://yourapp.com/payment/failed',
            },
            'billing': {
              'name': 'Customer',
              'email': 'customer@email.com',
            },
            'metadata': {
              'order_id': orderId,
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse('$baseUrl/v1/links'),
        headers: {
          'accept': 'application/json',
          'authorization': 'Basic ${base64Encode(utf8.encode('$apiKey:'))}',
          'content-type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create payment link: ${response.body}');
      }
    } catch (e) {
      throw Exception('GCash payment error: $e');
    }
  }

  // Check payment status
  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/links/$paymentId'),
        headers: {
          'accept': 'application/json',
          'authorization': 'Basic ${base64Encode(utf8.encode('$apiKey:'))}',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get payment status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment status check error: $e');
    }
  }

  // Simplified mock payment for testing (remove in production)
  Future<Map<String, dynamic>> mockPayment({
    required double amount,
    required String orderId,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock successful payment response
    return {
      'id': 'mock_payment_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'paid',
      'amount': amount,
      'order_id': orderId,
      'payment_url': 'https://mock-gcash-payment.com',
    };
  }
}