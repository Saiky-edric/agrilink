import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for tracking farmer GPS location during delivery
/// Automatically updates location in real-time for map tracking
class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  StreamSubscription<Position>? _positionStream;
  Timer? _updateTimer;
  bool _isTracking = false;
  String? _currentOrderId;
  Position? _lastPosition;
  DateTime? _lastUpdateTime;

  // Configuration
  static const int _updateIntervalSeconds = 30; // Update every 30 seconds
  static const double _minimumDistanceMeters = 10.0; // Only update if moved 10+ meters
  static const LocationAccuracy _accuracy = LocationAccuracy.high;

  /// Check if location permissions are granted
  Future<bool> checkPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return false;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permissions are permanently denied');
        return false;
      }

      debugPrint('✅ Location permissions granted');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking location permissions: $e');
      return false;
    }
  }

  /// Request location permissions from user
  Future<bool> requestPermissions() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('❌ Error requesting location permissions: $e');
      return false;
    }
  }

  /// Start tracking location for a specific order
  Future<bool> startTracking(String orderId) async {
    try {
      debugPrint('🚀 Starting location tracking for order: $orderId');

      // Check if already tracking
      if (_isTracking && _currentOrderId == orderId) {
        debugPrint('⚠️ Already tracking this order');
        return true;
      }

      // Stop any existing tracking
      await stopTracking();

      // Check permissions
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        debugPrint('❌ Cannot start tracking - no location permission');
        return false;
      }

      // Get initial position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _accuracy,
      );

      // Update order with initial location
      await _updateOrderLocation(orderId, position);

      // Set up periodic location updates
      _currentOrderId = orderId;
      _isTracking = true;
      _lastPosition = position;
      _lastUpdateTime = DateTime.now();

      // Start position stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: _accuracy,
          distanceFilter: _minimumDistanceMeters.toInt(),
        ),
      ).listen(
        (Position position) {
          _handlePositionUpdate(position);
        },
        onError: (error) {
          debugPrint('❌ Error in position stream: $error');
        },
      );

      // Set up periodic updates (backup in case position stream doesn't trigger)
      _updateTimer = Timer.periodic(
        Duration(seconds: _updateIntervalSeconds),
        (_) => _periodicUpdate(),
      );

      debugPrint('✅ Location tracking started successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop tracking location
  Future<void> stopTracking() async {
    try {
      debugPrint('🛑 Stopping location tracking');

      _isTracking = false;
      _currentOrderId = null;
      _lastPosition = null;
      _lastUpdateTime = null;

      await _positionStream?.cancel();
      _positionStream = null;

      _updateTimer?.cancel();
      _updateTimer = null;

      debugPrint('✅ Location tracking stopped');
    } catch (e) {
      debugPrint('❌ Error stopping location tracking: $e');
    }
  }

  /// Handle position update from stream
  void _handlePositionUpdate(Position position) {
    if (!_isTracking || _currentOrderId == null) return;

    // Check if we should update (time-based)
    final now = DateTime.now();
    if (_lastUpdateTime != null) {
      final secondsSinceLastUpdate = now.difference(_lastUpdateTime!).inSeconds;
      if (secondsSinceLastUpdate < _updateIntervalSeconds) {
        return; // Too soon to update
      }
    }

    // Check if we should update (distance-based)
    if (_lastPosition != null) {
      final distanceMoved = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      if (distanceMoved < _minimumDistanceMeters) {
        return; // Haven't moved enough
      }
    }

    // Update location
    _updateOrderLocation(_currentOrderId!, position);
    _lastPosition = position;
    _lastUpdateTime = now;
  }

  /// Periodic update (backup mechanism)
  Future<void> _periodicUpdate() async {
    if (!_isTracking || _currentOrderId == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _accuracy,
      );

      // Only update if moved significantly
      if (_lastPosition != null) {
        final distanceMoved = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        
        if (distanceMoved < _minimumDistanceMeters) {
          return; // Haven't moved enough
        }
      }

      await _updateOrderLocation(_currentOrderId!, position);
      _lastPosition = position;
      _lastUpdateTime = DateTime.now();
    } catch (e) {
      debugPrint('⚠️ Error in periodic update: $e');
    }
  }

  /// Update order location in database
  Future<void> _updateOrderLocation(String orderId, Position position) async {
    try {
      debugPrint('📍 Updating location: ${position.latitude}, ${position.longitude}');

      // Use the database function for location updates
      await _supabase.rpc('update_delivery_location', params: {
        'p_order_id': orderId,
        'p_latitude': position.latitude,
        'p_longitude': position.longitude,
      });

      debugPrint('✅ Location updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
      
      // Fallback: direct update if RPC fails
      try {
        await _supabase
            .from('orders')
            .update({
              'delivery_latitude': position.latitude,
              'delivery_longitude': position.longitude,
              'delivery_last_updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', orderId);
        debugPrint('✅ Location updated via fallback method');
      } catch (fallbackError) {
        debugPrint('❌ Fallback location update also failed: $fallbackError');
      }
    }
  }

  /// Get current tracking status
  bool get isTracking => _isTracking;

  /// Get current order being tracked
  String? get currentOrderId => _currentOrderId;

  /// Get last known position
  Position? get lastPosition => _lastPosition;

  /// Get time since last update
  Duration? get timeSinceLastUpdate {
    if (_lastUpdateTime == null) return null;
    return DateTime.now().difference(_lastUpdateTime!);
  }

  /// Manually trigger a location update
  Future<void> forceUpdate() async {
    if (!_isTracking || _currentOrderId == null) {
      debugPrint('⚠️ Cannot force update - not currently tracking');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _accuracy,
      );

      await _updateOrderLocation(_currentOrderId!, position);
      _lastPosition = position;
      _lastUpdateTime = DateTime.now();
      
      debugPrint('✅ Forced location update successful');
    } catch (e) {
      debugPrint('❌ Error forcing location update: $e');
    }
  }

  /// Get current location (one-time, not tracking)
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: _accuracy,
      );
    } catch (e) {
      debugPrint('❌ Error getting current location: $e');
      return null;
    }
  }

  /// Calculate distance between two points (in kilometers)
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}
