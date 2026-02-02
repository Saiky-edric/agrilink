# 📍 GPS Location Tracking Implementation Guide

## Overview
This guide shows farmers how to enable and use GPS location tracking for delivery orders, allowing buyers to see real-time delivery progress on a map.

---

## 🚀 Quick Start for Farmers

### Enable Location Tracking

When you start delivering an order:

1. **Open the Order Details** screen
2. **Tap "Start Delivery"** button
3. **Grant Location Permission** when prompted
4. **Location tracking starts automatically**

That's it! Your location will be updated every 30 seconds.

---

## 🎯 For Developers: Integration Steps

### Step 1: Add Location Tracking to Farmer Order Details

Open `lib/features/farmer/screens/farmer_order_details_screen.dart`:

```dart
import 'package:agrilink/core/services/location_tracking_service.dart';

class _FarmerOrderDetailsScreenState extends State<FarmerOrderDetailsScreen> {
  final LocationTrackingService _locationService = LocationTrackingService();
  
  @override
  void dispose() {
    // Stop tracking when leaving the screen
    _locationService.stopTracking();
    super.dispose();
  }
  
  // Add this method to start tracking
  Future<void> _startDelivery() async {
    try {
      // Update order status to 'toDeliver'
      await _orderService.updateOrderStatusWithTracking(
        orderId: widget.orderId,
        farmerStatus: FarmerOrderStatus.toDeliver,
        deliveryDate: _selectedDeliveryDate,
      );
      
      // Start GPS tracking
      final started = await _locationService.startTracking(widget.orderId);
      
      if (started) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ GPS tracking started! Buyer can now track your location.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Location permission denied
        _showLocationPermissionDialog();
      }
      
      setState(() {});
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to start delivery: $e')),
      );
    }
  }
  
  // Show dialog if location permission is denied
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'To enable real-time tracking for buyers, please grant location permission. '
          'Your location will only be shared while actively delivering orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Request permission again
              await _locationService.requestPermissions();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
  
  // Add tracking status indicator in UI
  Widget _buildTrackingStatus() {
    if (_locationService.isTracking) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.gps_fixed, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 GPS Tracking Active',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buyer can track your location in real-time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _locationService.forceUpdate(),
              child: const Text('Update Now'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
```

### Step 2: Add UI Button for Starting Delivery

Add a button in the action buttons section:

```dart
Widget _buildActionButtons() {
  return Column(
    children: [
      // Existing buttons...
      
      // Add "Start Delivery" button for 'toPack' status
      if (_order!.farmerStatus == FarmerOrderStatus.toPack &&
          _order!.deliveryMethod == 'delivery') ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startDelivery,
            icon: const Icon(Icons.local_shipping),
            label: const Text('Start Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
      
      // Show tracking status if active
      if (_order!.farmerStatus == FarmerOrderStatus.toDeliver) ...[
        const SizedBox(height: 12),
        _buildTrackingStatus(),
      ],
    ],
  );
}
```

### Step 3: Stop Tracking When Order Completes

```dart
Future<void> _completeDelivery() async {
  try {
    // Stop GPS tracking
    await _locationService.stopTracking();
    
    // Update order status
    await _orderService.updateOrderStatus(
      orderId: widget.orderId,
      farmerStatus: FarmerOrderStatus.completed,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Delivery completed! Tracking stopped.'),
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {});
  } catch (e) {
    // Handle error
  }
}
```

---

## 🔋 Battery & Performance Optimization

### Current Settings (Default)
- **Update Interval**: 30 seconds
- **Minimum Distance**: 10 meters
- **Accuracy**: High (GPS-level)

### To Adjust for Better Battery Life

Edit `lib/core/services/location_tracking_service.dart`:

```dart
class LocationTrackingService {
  // Increase update interval for better battery (e.g., 60 seconds)
  static const int _updateIntervalSeconds = 60;
  
  // Increase minimum distance (e.g., 50 meters)
  static const double _minimumDistanceMeters = 50.0;
  
  // Use balanced accuracy instead of high
  static const LocationAccuracy _accuracy = LocationAccuracy.balanced;
}
```

### Battery Impact

| Setting | Battery Usage | Update Frequency | Accuracy |
|---------|---------------|------------------|----------|
| **High** (default) | Medium | 30s / 10m | Best |
| **Balanced** | Low | 60s / 50m | Good |
| **Low Power** | Minimal | 120s / 100m | Fair |

---

## 📱 User Experience

### For Farmers
1. **Start Delivery** button appears when order is packed
2. Grant location permission once (saved for future orders)
3. Green "GPS Tracking Active" badge shows status
4. "Update Now" button for manual location refresh
5. Tracking stops automatically when delivery completes

### For Buyers
1. Timeline shows "Out for Delivery" status
2. "View Live Map" button appears
3. Map shows:
   - 🚚 Delivery vehicle (moving)
   - 🏠 Your location (destination)
   - 🏪 Farm location (origin)
   - Route line
   - Distance and ETA

---

## 🔒 Privacy & Security

### What's Tracked
- ✅ Location is only tracked during active delivery
- ✅ Location is only shared with the order's buyer
- ✅ Tracking stops automatically when delivery completes
- ✅ Historical location data is not stored

### What's NOT Tracked
- ❌ No tracking when not delivering
- ❌ No background tracking after app closes
- ❌ No location history saved
- ❌ No sharing with third parties

### Permissions Required
- **Android**: `ACCESS_FINE_LOCATION` (granted at runtime)
- **iOS**: `NSLocationWhenInUseUsageDescription` (granted at runtime)

---

## 🧪 Testing Location Tracking

### Test on Android Emulator

```bash
# Set a mock location
adb emu geo fix <longitude> <latitude>

# Example: Set location in Agusan del Sur
adb emu geo fix 125.6128 7.0731

# Simulate movement
adb emu geo fix 125.6200 7.0750
adb emu geo fix 125.6300 7.0800
```

### Test on iOS Simulator

1. Open Simulator
2. Debug → Location → Custom Location
3. Enter coordinates:
   - Latitude: 7.0731
   - Longitude: 125.6128
4. Move location to simulate travel

---

## 🐛 Troubleshooting

### Location Not Updating

**Check:**
1. ✅ Location permission granted?
2. ✅ GPS/Location services enabled on device?
3. ✅ Order status is 'toDeliver'?
4. ✅ Farmer has moved at least 10 meters?

**Fix:**
- Tap "Update Now" button to force refresh
- Check database: `SELECT delivery_latitude, delivery_last_updated_at FROM orders WHERE id = 'order-id';`

### Permission Denied Error

**Solution:**
```dart
// Check permission status
final hasPermission = await _locationService.checkPermissions();
if (!hasPermission) {
  await _locationService.requestPermissions();
}
```

### High Battery Drain

**Solution:**
- Increase update interval to 60 seconds
- Increase minimum distance to 50 meters
- Use `LocationAccuracy.balanced` instead of `high`

---

## 📊 Database Queries

### Check Location Updates
```sql
SELECT 
  id,
  farmer_status,
  delivery_latitude,
  delivery_longitude,
  delivery_last_updated_at,
  delivery_started_at
FROM orders
WHERE farmer_status = 'toDeliver'
ORDER BY delivery_last_updated_at DESC;
```

### Monitor Update Frequency
```sql
SELECT 
  id,
  EXTRACT(EPOCH FROM (NOW() - delivery_last_updated_at)) AS seconds_since_update
FROM orders
WHERE farmer_status = 'toDeliver'
  AND delivery_last_updated_at IS NOT NULL;
```

---

## 🎯 Next Steps

1. ✅ **Implement the UI changes** in farmer order details screen
2. 📱 **Test location tracking** with emulator/simulator
3. 🔋 **Optimize battery settings** based on user feedback
4. 📊 **Monitor location update frequency** in production
5. 🚀 **Consider background tracking** for better UX (optional)

---

## 🔮 Future Enhancements

### Planned Features
- 📱 **Background Tracking**: Continue tracking when app is minimized
- 🔔 **Smart Notifications**: Alert buyer when delivery is nearby
- 🗺️ **Route Optimization**: Suggest best routes to delivery location
- 📸 **Photo Proof**: Capture delivery photo at destination
- ✍️ **Digital Signature**: Buyer signs for order on delivery

### Advanced Options
- **Multi-stop Routes**: Deliver multiple orders in one trip
- **Delivery Partners**: Assign delivery to third-party drivers
- **Traffic Integration**: Adjust ETA based on traffic conditions
- **Offline Mode**: Queue updates when internet unavailable

---

**Implementation Status**: ✅ Complete - Ready to integrate  
**Location Service**: `lib/core/services/location_tracking_service.dart`  
**Documentation**: You are here! 📍
