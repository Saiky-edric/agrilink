import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DeliveryMethodSelector extends StatelessWidget {
  final String selectedMethod; // 'delivery' or 'pickup'
  final double deliveryFee;
  final Map<String, dynamic>? pickupInfo; // {address, instructions, hours}
  final Function(String) onMethodChanged;

  const DeliveryMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.deliveryFee,
    this.pickupInfo,
    required this.onMethodChanged,
  });

  String _getFormattedPickupAddress() {
    if (pickupInfo == null) return '';
    
    final addresses = pickupInfo!['pickup_addresses'];
    if (addresses == null || addresses is! List || addresses.isEmpty) {
      return '';
    }
    
    // Get the first (default) address
    final defaultAddress = addresses[0] as Map<String, dynamic>;
    final municipality = defaultAddress['municipality'] ?? '';
    final barangay = defaultAddress['barangay'] ?? '';
    final street = defaultAddress['street_address'] ?? '';
    final label = defaultAddress['label'] ?? '';
    
    // Format with label if available: "Label - Street, Barangay, Municipality"
    if (label.isNotEmpty) {
      return '$label\n$street, $barangay, $municipality';
    }
    
    // Format without label: "Street, Barangay, Municipality"
    return '$street, $barangay, $municipality';
  }

  @override
  Widget build(BuildContext context) {
    // Check if pickup is available
    final bool isPickupAvailable = pickupInfo != null && 
        pickupInfo!['pickup_enabled'] == true &&
        (pickupInfo!['pickup_addresses'] != null && 
         pickupInfo!['pickup_addresses'] is List && 
         (pickupInfo!['pickup_addresses'] as List).isNotEmpty);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Delivery Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Home Delivery Option
            _buildMethodOption(
              context: context,
              icon: Icons.local_shipping_rounded,
              title: 'Home Delivery',
              subtitle: 'Standard delivery to your address',
              value: 'delivery',
              isSelected: selectedMethod == 'delivery',
              price: '₱${deliveryFee.toStringAsFixed(2)}',
              iconColor: AppTheme.secondaryGreen,
              onTap: () => onMethodChanged('delivery'),
            ),

            const SizedBox(height: 12),

            // Pick-up Option
            if (isPickupAvailable)
              _buildMethodOption(
                context: context,
                icon: Icons.store_rounded,
                title: 'Pick-up',
                subtitle: 'Pick up from farmer\'s location',
                value: 'pickup',
                isSelected: selectedMethod == 'pickup',
                price: 'FREE',
                priceColor: AppTheme.successGreen,
                iconColor: AppTheme.primaryGreen,
                badge: '🎉 Save ₱${deliveryFee.toStringAsFixed(0)}',
                onTap: () => onMethodChanged('pickup'),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.accentOrange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pick-up option not available from this farmer',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Pickup Location Details (if pickup selected)
            if (selectedMethod == 'pickup' && isPickupAvailable) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pick-up Location:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getFormattedPickupAddress(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    
                    if (pickupInfo!['pickup_instructions'] != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              pickupInfo!['pickup_instructions'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatPickupHours(pickupInfo!['pickup_hours']),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMethodOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isSelected,
    required String price,
    Color? priceColor,
    Color? iconColor,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primaryGreen).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppTheme.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isSelected ? AppTheme.primaryGreen : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Price - always visible with strong contrast
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                price,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: priceColor ?? AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPickupHours(dynamic hours) {
    if (hours == null) return 'Contact farmer for hours';
    
    // If it's a JSON string, parse it
    if (hours is String) {
      try {
        // Simple parsing for common format
        if (hours.contains('monday') || hours.contains('Monday')) {
          return 'See details above';
        }
        return hours;
      } catch (e) {
        return 'Contact farmer for hours';
      }
    }
    
    // If it's already a map
    if (hours is Map) {
      final monday = hours['monday'] ?? hours['Monday'];
      if (monday != null && monday != 'CLOSED') {
        return 'Available: $monday';
      }
    }
    
    return 'Contact farmer for hours';
  }
}
