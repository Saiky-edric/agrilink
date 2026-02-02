import 'package:location/location.dart' as loc;
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../constants/location_data.dart';

class LocationService {
  final loc.Location _location = loc.Location();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permissions
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    // Check if service is enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    // Check permission
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  /// Get current location coordinates
  Future<LocationCoordinates?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        return null;
      }

      final locationData = await _location.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        return LocationCoordinates(
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
          accuracy: locationData.accuracy,
        );
      }
      
      return null;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates in kilometers using Haversine formula
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371; // Radius of Earth in kilometers

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c;

    return distance;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Format distance for display
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  /// Get approximate municipality from coordinates
  /// This is a simple implementation - for production, consider using a geocoding service
  Future<String?> getMunicipalityFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    // Agusan del Sur approximate coordinates
    // This is a simplified version - you may want to use a proper geocoding API
    final municipalities = LocationData.municipalities;
    
    // For now, we'll return null and let users select manually
    // In production, integrate with a geocoding service like Google Maps API
    return null;
  }

  /// Check if coordinates are within Agusan del Sur bounds (approximate)
  bool isWithinAgusanDelSur(double latitude, double longitude) {
    // Approximate bounds of Agusan del Sur
    // North: ~9.0°, South: ~8.0°, East: ~126.0°, West: ~125.0°
    const double minLat = 8.0;
    const double maxLat = 9.0;
    const double minLon = 125.0;
    const double maxLon = 126.5;

    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLon &&
        longitude <= maxLon;
  }

  /// Get distance between current location and a target location
  Future<double?> getDistanceFromCurrentLocation({
    required double targetLat,
    required double targetLon,
  }) async {
    final currentLocation = await getCurrentLocation();
    if (currentLocation == null) return null;

    return calculateDistance(
      lat1: currentLocation.latitude,
      lon1: currentLocation.longitude,
      lat2: targetLat,
      lon2: targetLon,
    );
  }

  /// Sort items by distance from current location
  Future<List<T>> sortByDistanceFromCurrent<T>({
    required List<T> items,
    required double? Function(T) getLatitude,
    required double? Function(T) getLongitude,
  }) async {
    final currentLocation = await getCurrentLocation();
    if (currentLocation == null) return items;

    final itemsWithDistance = items.map((item) {
      final lat = getLatitude(item);
      final lon = getLongitude(item);
      
      double? distance;
      if (lat != null && lon != null) {
        distance = calculateDistance(
          lat1: currentLocation.latitude,
          lon1: currentLocation.longitude,
          lat2: lat,
          lon2: lon,
        );
      }
      
      return {'item': item, 'distance': distance};
    }).toList();

    // Sort: items with distance first (by distance), then items without distance
    itemsWithDistance.sort((a, b) {
      final distA = a['distance'] as double?;
      final distB = b['distance'] as double?;
      
      if (distA == null && distB == null) return 0;
      if (distA == null) return 1;
      if (distB == null) return -1;
      
      return distA.compareTo(distB);
    });

    return itemsWithDistance.map((e) => e['item'] as T).toList();
  }

  /// Filter items within a certain radius (in kilometers)
  List<T> filterByRadius<T>({
    required List<T> items,
    required double? Function(T) getLatitude,
    required double? Function(T) getLongitude,
    required double userLat,
    required double userLon,
    required double radiusKm,
  }) {
    return items.where((item) {
      final lat = getLatitude(item);
      final lon = getLongitude(item);
      
      if (lat == null || lon == null) return false;
      
      final distance = calculateDistance(
        lat1: userLat,
        lon1: userLon,
        lat2: lat,
        lon2: lon,
      );
      
      return distance <= radiusKm;
    }).toList();
  }
}

/// Model for location coordinates
class LocationCoordinates {
  final double latitude;
  final double longitude;
  final double? accuracy;

  LocationCoordinates({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    };
  }

  factory LocationCoordinates.fromJson(Map<String, dynamic> json) {
    return LocationCoordinates(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      accuracy: json['accuracy'] as double?,
    );
  }

  @override
  String toString() {
    return 'LocationCoordinates(lat: $latitude, lon: $longitude, accuracy: $accuracy)';
  }
}
