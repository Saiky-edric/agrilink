import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import 'supabase_service.dart';
import 'notification_helper.dart';

class OrderService {
 // J&T incremental single-parcel fee calculator used by checkout and order creation
 static double jtFeeForKgWithStep(double totalKg, double per2kg) {
   if (totalKg <= 3) return 70.0;
   if (totalKg <= 5) return 120.0;
   if (totalKg <= 8) return 160.0;
   final extra = totalKg - 8.0;
   final steps = (extra / 2.0).ceil();
   return 160.0 + steps * per2kg;
 }

 static double jtFeeForKg(double totalKg) => jtFeeForKgWithStep(totalKg, 25.0);

 static double? _cachedPer2kg;
 static Future<double> jtPer2kgStep() async {
   if (_cachedPer2kg != null) return _cachedPer2kg!;
   try {
     final client = Supabase.instance.client;
     final settings = await client.from('platform_settings').select().maybeSingle();
     final d = settings != null ? settings['jt_per2kg_fee'] : null;
     if (d != null) {
       final asNum = (d is num) ? d.toDouble() : double.tryParse(d.toString());
       if (asNum != null && asNum >= 0) {
         _cachedPer2kg = asNum;
         return _cachedPer2kg!;
       }
     }
   } catch (e) {
     debugPrint('⚠️ Failed to load jt_per2kg_fee from platform_settings: $e');
   }
   _cachedPer2kg = 25.0;
   return _cachedPer2kg!;
 }
  final SupabaseService _supabase = SupabaseService.instance;
  final NotificationHelper _notificationHelper = NotificationHelper();

  // Get orders for a specific farmer
  Future<List<OrderModel>> getFarmerOrders({
    required String farmerId,
    FarmerOrderStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.client
          .from('orders')
          .select('''
            *,
            buyer:buyer_id (
              id,
              full_name,
              phone_number,
              municipality,
              barangay,
              street
            ),
            items:order_items (
              *,
              product:product_id (
                id,
                name,
                price,
                unit,
                cover_image_url,
                weight_per_unit
              )
            )
          ''')
          .eq('farmer_id', farmerId);

      if (status != null) {
        query = query.eq('farmer_status', status.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((item) => OrderModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get farmer orders: $e');
    }
  }

  // Get a specific order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final response = await _supabase.client
          .from('orders')
          .select('''
            *,
            buyer:buyer_id (
              id,
              full_name,
              phone_number,
              municipality,
              barangay,
              street
            ),
            farmer:farmer_id (
              id,
              full_name,
              phone_number,
              municipality,
              barangay
            ),
            items:order_items (
              *,
              product:product_id (
                id,
                name,
                price,
                unit,
                cover_image_url,
                weight_per_unit,
                farmer_id
              )
            )
          ''')
          .eq('id', orderId)
          .maybeSingle();

      if (response == null) return null;

      return OrderModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

 Future<void> _deductStockForOrder(String orderId) async {
   // Deduct product stocks according to order_items quantities for this order
   // Safe guard: don't let stock go negative
   final items = await _supabase.client
       .from('order_items')
       .select('product_id, quantity')
       .eq('order_id', orderId);

   for (final item in items) {
     final String productId = item['product_id'] as String;
     final int qty = (item['quantity'] as num).toInt();

     // Read-modify-write with guard (simple, reliable)
     final current = await _supabase.client
         .from('products')
         .select('stock')
         .eq('id', productId)
         .single();
     final int currentStock = (current['stock'] as num?)?.toInt() ?? 0;
     final int newStock = (currentStock - qty) < 0 ? 0 : (currentStock - qty);
     await _supabase.client
         .from('products')
         .update({'stock': newStock})
         .eq('id', productId);
   }
 }

 // Update order status
 Future<OrderModel> updateOrderStatus({
    required String orderId,
    FarmerOrderStatus? farmerStatus,
    BuyerOrderStatus? buyerStatus,
  }) async {
    try {
      debugPrint('🔍 DEBUG: === ORDER STATUS UPDATE START ===');
      debugPrint('🔍 DEBUG: Order ID: $orderId');
      debugPrint('🔍 DEBUG: Farmer Status: $farmerStatus');
      debugPrint('🔍 DEBUG: Buyer Status: $buyerStatus');
      // Pre-check for stock deduction
      final current = await _supabase.client
          .from('orders')
          .select('farmer_status, buyer_status')
          .eq('id', orderId)
          .maybeSingle();
      final String? curFs = current?['farmer_status'] as String?;
      final String? curBs = current?['buyer_status'] as String?;
      final bool alreadyCompleted = (curFs == FarmerOrderStatus.completed.name) || (curBs == BuyerOrderStatus.completed.name);
      final bool willComplete = (farmerStatus == FarmerOrderStatus.completed) || (buyerStatus == BuyerOrderStatus.completed);
      
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (farmerStatus != null) {
        final statusString = farmerStatus.name;
        debugPrint('🔍 DEBUG: Converting farmer status enum to string: "$statusString"');
        debugPrint('🔍 DEBUG: Enum toString: ${farmerStatus.toString()}');
        
        // Validation check
        final validStatuses = ['newOrder', 'accepted', 'toPack', 'toDeliver', 'completed', 'cancelled'];
        if (!validStatuses.contains(statusString)) {
          debugPrint('❌ DEBUG: INVALID STATUS DETECTED: "$statusString"');
          throw Exception('Invalid farmer status: "$statusString". Valid: $validStatuses');
        }
        
        updateData['farmer_status'] = statusString;
        debugPrint('✅ DEBUG: Farmer status added to update data: "$statusString"');
        
        // If farmer completes the order, update buyer status too
        if (farmerStatus == FarmerOrderStatus.completed) {
          updateData['buyer_status'] = BuyerOrderStatus.completed.name;
          updateData['completed_at'] = DateTime.now().toIso8601String();
        }
      }

      if (buyerStatus != null) {
        final buyerStatusString = buyerStatus.name;
        debugPrint('🔍 DEBUG: Adding buyer status: "$buyerStatusString"');
        updateData['buyer_status'] = buyerStatusString;
        
        // If buyer completes/receives the order, update farmer status too
        if (buyerStatus == BuyerOrderStatus.completed) {
          updateData['farmer_status'] = FarmerOrderStatus.completed.name;
          updateData['completed_at'] = DateTime.now().toIso8601String();
        }
      }

      debugPrint('🔍 DEBUG: === FINAL UPDATE DATA ===');
      debugPrint('🔍 DEBUG: Update data being sent to database: $updateData');
      debugPrint('🔍 DEBUG: Order ID: $orderId');
      // Use RPC to atomically update status and deduct stock
      await _supabase.client.rpc('complete_order_and_deduct', params: {
        'p_order_id': orderId,
        'p_buyer_status': buyerStatus?.name,
        'p_farmer_status': farmerStatus?.name,
      });
      // Refresh order after RPC
      final response = await _supabase.client
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();
      debugPrint('✅ DEBUG: RPC + refresh successful!');
      debugPrint('🔍 DEBUG: Database response: $response');
      return OrderModel.fromJson(response);
      // Legacy direct update block removed; RPC above returns fresh order
     // (No-op)
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Cancel order (only allowed before farmer starts packing)
  Future<void> cancelOrder({
    required String orderId,
    String? cancelReason,
  }) async {
    try {
      debugPrint('🔍 DEBUG: === CANCEL ORDER START ===');
      debugPrint('🔍 DEBUG: Order ID: $orderId');
      debugPrint('🔍 DEBUG: Cancel reason: $cancelReason');

      // First, get the current order to check status
      final currentOrder = await _supabase.client
          .from('orders')
          .select('farmer_status, buyer_id, farmer_id')
          .eq('id', orderId)
          .single();

      final currentStatus = currentOrder['farmer_status'] as String;
      debugPrint('🔍 DEBUG: Current farmer status: $currentStatus');

      // Check if cancellation is allowed
      if (currentStatus != 'newOrder' && currentStatus != 'accepted') {
        throw Exception('Cannot cancel order. Farmer has already started preparing your order.');
      }

      // Update order to cancelled status
      final updateData = {
        'farmer_status': FarmerOrderStatus.cancelled.name,
        'buyer_status': BuyerOrderStatus.cancelled.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (cancelReason != null && cancelReason.isNotEmpty) {
        updateData['special_instructions'] = 'CANCELLED: $cancelReason';
      }

      debugPrint('🔍 DEBUG: Updating order with: $updateData');

      await _supabase.client
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      // Send notification to farmer with cancellation reason
      try {
        final notificationMessage = cancelReason != null && cancelReason.isNotEmpty
            ? 'A buyer has cancelled their order. Reason: $cancelReason'
            : 'A buyer has cancelled their order.';
            
        await _supabase.client.from('notifications').insert({
          'user_id': currentOrder['farmer_id'],
          'title': 'Order Cancelled',
          'message': notificationMessage,
          'type': 'orderUpdate',
          'related_id': orderId,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Failed to send notification: $e');
        // Don't fail the cancellation if notification fails
      }

      debugPrint('✅ DEBUG: Order cancelled successfully');
    } catch (e) {
      debugPrint('❌ DEBUG: Cancel failed with error: $e');
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Generate tracking number
  String _generateTrackingNumber() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    return 'AGR${timestamp.substring(timestamp.length - 6)}$randomNum';
  }

  // Update order with tracking information
  Future<void> updateOrderTracking({
    required String orderId,
    String? trackingNumber,
    DateTime? deliveryDate,
    String? deliveryNotes,
  }) async {
    try {
      debugPrint('🔍 DEBUG: Updating order tracking for $orderId');
      
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (trackingNumber != null) {
        updateData['tracking_number'] = trackingNumber;
        debugPrint('📦 DEBUG: Setting tracking number: $trackingNumber');
      }

      if (deliveryDate != null) {
        updateData['delivery_date'] = deliveryDate.toIso8601String().split('T')[0]; // Date only
        debugPrint('📅 DEBUG: Setting delivery date: ${deliveryDate.toIso8601String().split('T')[0]}');
      }

      if (deliveryNotes != null && deliveryNotes.isNotEmpty) {
        updateData['delivery_notes'] = deliveryNotes;
        debugPrint('📝 DEBUG: Setting delivery notes: $deliveryNotes');
      }

      await _supabase.client
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      debugPrint('✅ DEBUG: Order tracking updated successfully');
    } catch (e) {
      debugPrint('❌ DEBUG: Failed to update tracking: $e');
      throw Exception('Failed to update order tracking: $e');
    }
  }

  // Update order status with optional tracking info
  Future<OrderModel> updateOrderStatusWithTracking({
    required String orderId,
    FarmerOrderStatus? farmerStatus,
    BuyerOrderStatus? buyerStatus,
    DateTime? deliveryDate,
    String? deliveryNotes,
    String? trackingNumber,
  }) async {
    try {
      debugPrint('🔍 DEBUG: === ORDER STATUS UPDATE WITH TRACKING START ===');
      debugPrint('🔍 DEBUG: Order ID: $orderId');
      debugPrint('🔍 DEBUG: Farmer Status: $farmerStatus');
      debugPrint('🔍 DEBUG: Tracking Number: $trackingNumber');
      debugPrint('🔍 DEBUG: Delivery Date: $deliveryDate');
      
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (farmerStatus != null) {
        final statusString = farmerStatus.name;
        debugPrint('🔍 DEBUG: Converting farmer status enum to string: "$statusString"');
        
        // Validation check
        final validStatuses = ['newOrder', 'accepted', 'toPack', 'toDeliver', 'completed', 'cancelled'];
        if (!validStatuses.contains(statusString)) {
          debugPrint('❌ DEBUG: INVALID STATUS DETECTED: "$statusString"');
          throw Exception('Invalid farmer status: "$statusString". Valid: $validStatuses');
        }
        
        updateData['farmer_status'] = statusString;
        debugPrint('✅ DEBUG: Farmer status added to update data: "$statusString"');

        // Auto-generate tracking number when marking as toDeliver
        if (farmerStatus == FarmerOrderStatus.toDeliver && trackingNumber == null) {
          final autoTrackingNumber = _generateTrackingNumber();
          updateData['tracking_number'] = autoTrackingNumber;
          debugPrint('📦 DEBUG: Auto-generated tracking number: $autoTrackingNumber');
        }

        // If farmer completes the order, update buyer status too
        if (farmerStatus == FarmerOrderStatus.completed) {
          updateData['buyer_status'] = BuyerOrderStatus.completed.name;
          updateData['completed_at'] = DateTime.now().toIso8601String();
        }
      }

      if (buyerStatus != null) {
        final buyerStatusString = buyerStatus.name;
        debugPrint('🔍 DEBUG: Adding buyer status: "$buyerStatusString"');
        updateData['buyer_status'] = buyerStatusString;
        
        // If buyer completes/receives the order, update farmer status too
        if (buyerStatus == BuyerOrderStatus.completed) {
          updateData['farmer_status'] = FarmerOrderStatus.completed.name;
          updateData['completed_at'] = DateTime.now().toIso8601String();
        }
      }

      // Add tracking information
      if (trackingNumber != null) {
        updateData['tracking_number'] = trackingNumber;
      }

      if (deliveryDate != null) {
        updateData['delivery_date'] = deliveryDate.toIso8601String().split('T')[0];
      }

      if (deliveryNotes != null && deliveryNotes.isNotEmpty) {
        updateData['delivery_notes'] = deliveryNotes;
      }

      debugPrint('🔍 DEBUG: === FINAL UPDATE DATA ===');
      debugPrint('🔍 DEBUG: Update data being sent to database: $updateData');

      // 1) Atomically update statuses and deduct stock if completing
      await _supabase.client.rpc('complete_order_and_deduct', params: {
        'p_order_id': orderId,
        'p_buyer_status': buyerStatus?.name,
        'p_farmer_status': farmerStatus?.name,
      });

      // 2) Apply tracking fields if provided
      if (trackingNumber != null || deliveryDate != null || (deliveryNotes != null && deliveryNotes.isNotEmpty)) {
        final trackingUpdate = <String, dynamic>{
          'updated_at': DateTime.now().toIso8601String(),
        };
        if (trackingNumber != null) trackingUpdate['tracking_number'] = trackingNumber;
        if (deliveryDate != null) trackingUpdate['delivery_date'] = deliveryDate.toIso8601String().split('T')[0];
        if (deliveryNotes != null && deliveryNotes.isNotEmpty) trackingUpdate['delivery_notes'] = deliveryNotes;

        await _supabase.client
            .from('orders')
            .update(trackingUpdate)
            .eq('id', orderId);
      }

      // 3) Refresh and log
      final response = await _supabase.client
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .single();
      debugPrint('✅ DEBUG: RPC + tracking update successful!');
      debugPrint('🔍 DEBUG: Database response: $response');

      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ DEBUG: Update failed with error: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get order statistics for farmer
  Future<Map<String, dynamic>> getFarmerOrderStats(String farmerId) async {
    try {
      final orders = await getFarmerOrders(farmerId: farmerId);

      final totalOrders = orders.length;
      final newOrders = orders.where((o) => o.farmerStatus == FarmerOrderStatus.newOrder).length;
      final toPackOrders = orders.where((o) => o.farmerStatus == FarmerOrderStatus.toPack).length;
      final toDeliverOrders = orders.where((o) => o.farmerStatus == FarmerOrderStatus.toDeliver).length;
      final completedOrders = orders.where((o) => o.farmerStatus == FarmerOrderStatus.completed).length;
      final cancelledOrders = orders.where((o) => o.farmerStatus == FarmerOrderStatus.cancelled).length;

      final totalRevenue = orders
          .where((o) => o.farmerStatus == FarmerOrderStatus.completed)
          .fold(0.0, (sum, order) => sum + order.totalAmount);

      final averageOrderValue = totalOrders > 0 
          ? orders.fold(0.0, (sum, order) => sum + order.totalAmount) / totalOrders 
          : 0.0;

      return {
        'totalOrders': totalOrders,
        'newOrders': newOrders,
        'toPackOrders': toPackOrders,
        'toDeliverOrders': toDeliverOrders,
        'completedOrders': completedOrders,
        'cancelledOrders': cancelledOrders,
        'totalRevenue': totalRevenue,
        'averageOrderValue': averageOrderValue,
        'pendingOrders': newOrders + toPackOrders + toDeliverOrders,
      };
    } catch (e) {
      throw Exception('Failed to get order stats: $e');
    }
  }

  // Get recent orders
  Future<List<OrderModel>> getRecentOrders(String farmerId, {int limit = 5}) async {
    try {
      return await getFarmerOrders(
        farmerId: farmerId,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get recent orders: $e');
    }
  }

  // Get orders by status
  Future<List<OrderModel>> getOrdersByStatus({
    required String farmerId,
    required FarmerOrderStatus status,
    int limit = 50,
  }) async {
    try {
      return await getFarmerOrders(
        farmerId: farmerId,
        status: status,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get orders by status: $e');
    }
  }

  // Cancel order (farmer side) - DEPRECATED, use cancelOrder with named parameters instead
  Future<OrderModel> cancelOrderOld(String orderId, String reason) async {
    try {
      final updateData = {
        'farmer_status': FarmerOrderStatus.cancelled.name,
        'buyer_status': BuyerOrderStatus.cancelled.name,
        'cancellation_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.client
          .from('orders')
          .update(updateData)
          .eq('id', orderId)
          .select()
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  // Get orders that need attention (new orders, etc.)
  Future<List<OrderModel>> getOrdersNeedingAttention(String farmerId) async {
    try {
      return await getFarmerOrders(
        farmerId: farmerId,
        status: FarmerOrderStatus.newOrder,
        limit: 10,
      );
    } catch (e) {
      throw Exception('Failed to get orders needing attention: $e');
    }
  }

  // Create a new order
  Future<String> createOrder({
    required String buyerId,
    required String farmerId,
    required List<CartItemModel> items,
    required String deliveryAddress,
    required String paymentMethod,
    String? specialInstructions,
    String deliveryMethod = 'delivery', // NEW: 'delivery' or 'pickup'
    String? pickupAddress, // NEW: Pickup location if delivery_method is 'pickup'
    String? pickupInstructions, // NEW: Pickup instructions
  }) async {
    try {
      // Generate order ID
      const uuid = Uuid();
      final orderId = uuid.v4();
      final now = DateTime.now().toIso8601String();
      
      // Calculate totals
      final subtotal = items.fold(0.0, (sum, item) => sum + item.subtotal);

      // NO COMMISSION MODEL - Revenue from subscriptions only
      // Farmers keep 100% of their product sales
      const double commissionRatePercent = 0.0; // Always 0 - subscription-based revenue
      double per2kgStep = 25.0;
      try {
        final settings = await _supabase.client.from('platform_settings').select().maybeSingle();
        if (settings != null) {
          // Commission rate setting ignored - kept for backward compatibility only
          // Platform earns through premium subscriptions, not order commissions
          final s = settings['jt_per2kg_fee'];
          if (s != null) {
            final asNum = (s is num) ? s.toDouble() : double.tryParse(s.toString());
            if (asNum != null && asNum >= 0) per2kgStep = asNum;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Failed to load platform settings for order creation: $e');
      }

      final commissionFee = 0.0; // NO COMMISSION - Subscription-based revenue model
      // Compute delivery fee per store using J&T incremental policy (single parcel)
      // Set to 0 for pickup orders
      double deliveryFee = 0.0;
      if (deliveryMethod == 'delivery') {
        double totalKg = 0.0;
        for (final it in items) {
          double unitKg = 0.0;
          final p = it.product;
          if (p != null) {
            try {
              final m = p.toJson();
              unitKg = (m['weight_per_unit'] as num?)?.toDouble() ?? 0.0;
            } catch (_) {
              unitKg = 0.0;
            }
          }
          totalKg += unitKg * it.quantity;
        }
        deliveryFee = OrderService.jtFeeForKgWithStep(totalKg, per2kgStep);
      }
      // For pickup orders, deliveryFee remains 0.0
      final totalAmount = subtotal + deliveryFee;

      // Create order record
      final orderData = {
        'id': orderId,
        'buyer_id': buyerId,
        'farmer_id': farmerId,
        'total_amount': totalAmount,
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'service_fee': 0.0, // NO COMMISSION - Revenue from subscriptions only
        'delivery_address': deliveryAddress,
        'special_instructions': specialInstructions,
        'delivery_method': deliveryMethod, // NEW: 'delivery' or 'pickup'
        'payment_method': paymentMethod, // Payment method: 'cod', 'cop', 'gcash'
        'buyer_status': BuyerOrderStatus.pending.name,
        'farmer_status': FarmerOrderStatus.newOrder.name,
        'created_at': now,
        'updated_at': now,
      };
      
      // Add pickup-specific fields if it's a pickup order
      if (deliveryMethod == 'pickup') {
        if (pickupAddress != null) {
          orderData['pickup_address'] = pickupAddress;
        }
        if (pickupInstructions != null) {
          orderData['pickup_instructions'] = pickupInstructions;
        }
      }

      await _supabase.client.from('orders').insert(orderData);

      // Create order items
      final orderItemsData = items.map((item) => {
        'order_id': orderId,
        'product_id': item.productId,
        'product_name': item.product?.name ?? 'Unknown Product',
        'unit_price': item.product?.price ?? 0.0,
        'quantity': item.quantity,
        'unit': item.product?.unit ?? 'unit',
        'subtotal': item.subtotal,
      }).toList();

      await _supabase.client.from('order_items').insert(orderItemsData);

      // TODO: Send notification to farmer when notification system is fully implemented
      debugPrint('Order created successfully: $orderId for farmer: $farmerId');

      return orderId;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }


  // Get buyer orders
  Future<List<OrderModel>> getBuyerOrders({
    required String buyerId,
    BuyerOrderStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.client
          .from('orders')
          .select('''
            *,
            farmer:farmer_id (
              id,
              full_name,
              phone_number,
              municipality,
              barangay,
              store_name
            ),
            items:order_items (
              *,
              product:product_id (
                id,
                name,
                price,
                unit,
                cover_image_url,
                weight_per_unit
              )
            )
          ''')
          .eq('buyer_id', buyerId);

      if (status != null) {
        query = query.eq('buyer_status', status.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((item) => OrderModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get buyer orders: $e');
    }
  }

  // Search orders
  Future<List<OrderModel>> searchOrders({
    required String farmerId,
    String? buyerName,
    String? orderId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.client
          .from('orders')
          .select('''
            *,
            buyer:buyer_id (
              id,
              full_name,
              phone_number
            ),
            items:order_items (
              *,
              product:product_id (
                id,
                name,
                price,
                unit,
                weight_per_unit
              )
            )
          ''')
          .eq('farmer_id', farmerId);

      if (orderId != null && orderId.isNotEmpty) {
        query = query.ilike('id', '%$orderId%');
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(50);

      var orders = response.map((item) => OrderModel.fromJson(item)).toList();

      // Filter by buyer name if provided (client-side filtering since we can't easily join filter)
      if (buyerName != null && buyerName.isNotEmpty) {
        orders = orders.where((order) {
          // This would need the buyer info to be loaded in the order model
          return order.id.contains(buyerName); // Simplified for now
        }).toList();
      }

      return orders;
    } catch (e) {
      throw Exception('Failed to search orders: $e');
    }
  }
}