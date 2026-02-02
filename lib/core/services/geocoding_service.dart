import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

/// Service for geocoding (address ↔ coordinates conversion)
class GeocodingService {
  /// Convert coordinates to address (Reverse Geocoding)
  /// Returns human-readable address from GPS coordinates
  Future<AddressComponents?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) {
        debugPrint('No address found for coordinates: $latitude, $longitude');
        return null;
      }

      final place = placemarks.first;
      
      return AddressComponents(
        street: place.street ?? place.thoroughfare ?? '',
        subLocality: place.subLocality ?? '',
        locality: place.locality ?? '',
        subAdministrativeArea: place.subAdministrativeArea ?? '',
        administrativeArea: place.administrativeArea ?? '',
        country: place.country ?? '',
        postalCode: place.postalCode ?? '',
        fullAddress: _formatFullAddress(place),
      );
    } catch (e) {
      debugPrint('Error in reverse geocoding: $e');
      return null;
    }
  }

  /// Convert address to coordinates (Forward Geocoding)
  /// Returns GPS coordinates from address string
  Future<List<LocationResult>> searchAddress(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final locations = await locationFromAddress(query);
      
      if (locations.isEmpty) {
        return [];
      }

      // Get placemarks for each location to provide full details
      final results = <LocationResult>[];
      
      for (final location in locations) {
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            results.add(LocationResult(
              latitude: location.latitude,
              longitude: location.longitude,
              displayName: _formatFullAddress(place),
              street: place.street ?? place.thoroughfare ?? '',
              locality: place.locality ?? '',
              subAdministrativeArea: place.subAdministrativeArea ?? '',
              administrativeArea: place.administrativeArea ?? '',
            ));
          }
        } catch (e) {
          debugPrint('Error getting placemark details: $e');
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error in forward geocoding: $e');
      return [];
    }
  }

  /// Search for locations within Philippines/Agusan del Sur
  Future<List<LocationResult>> searchAddressInPhilippines(String query) async {
    try {
      // Append Philippines to improve accuracy
      final searchQuery = query.contains('Philippines') 
          ? query 
          : '$query, Agusan del Sur, Philippines';
      
      return await searchAddress(searchQuery);
    } catch (e) {
      debugPrint('Error searching address in Philippines: $e');
      return [];
    }
  }

  /// Get municipality/city name from coordinates
  Future<String?> getMunicipalityFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final address = await getAddressFromCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
      
      // Try to get municipality/city name
      return address?.locality ?? 
             address?.subAdministrativeArea ?? 
             address?.administrativeArea;
    } catch (e) {
      debugPrint('Error getting municipality: $e');
      return null;
    }
  }

  /// Get barangay/suburb name from coordinates
  Future<String?> getBarangayFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final address = await getAddressFromCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
      
      // Try to get barangay/suburb name
      return address?.subLocality;
    } catch (e) {
      debugPrint('Error getting barangay: $e');
      return null;
    }
  }

  /// Format placemark into readable address string
  String _formatFullAddress(Placemark place) {
    final parts = <String>[];
    
    if (place.street?.isNotEmpty == true) parts.add(place.street!);
    if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
    if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
    if (place.subAdministrativeArea?.isNotEmpty == true && 
        place.subAdministrativeArea != place.locality) {
      parts.add(place.subAdministrativeArea!);
    }
    if (place.administrativeArea?.isNotEmpty == true) {
      parts.add(place.administrativeArea!);
    }
    
    return parts.join(', ');
  }

  /// Validate if coordinates are within Agusan del Sur (approximate bounds)
  bool isWithinAgusanDelSur(double latitude, double longitude) {
    // Approximate bounds of Agusan del Sur
    const double minLat = 8.0;
    const double maxLat = 9.0;
    const double minLon = 125.0;
    const double maxLon = 126.5;

    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLon &&
        longitude <= maxLon;
  }
}

/// Model for address components from geocoding
class AddressComponents {
  final String street;
  final String subLocality; // Often maps to barangay
  final String locality; // Often maps to municipality/city
  final String subAdministrativeArea; // District/municipality
  final String administrativeArea; // Province/state
  final String country;
  final String postalCode;
  final String fullAddress;

  AddressComponents({
    required this.street,
    required this.subLocality,
    required this.locality,
    required this.subAdministrativeArea,
    required this.administrativeArea,
    required this.country,
    required this.postalCode,
    required this.fullAddress,
  });

  /// Get best guess for municipality
  String get municipality {
    return locality.isNotEmpty 
        ? locality 
        : (subAdministrativeArea.isNotEmpty 
            ? subAdministrativeArea 
            : administrativeArea);
  }

  /// Get best guess for barangay
  String get barangay {
    return subLocality.isNotEmpty ? subLocality : '';
  }

  @override
  String toString() {
    return fullAddress;
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'subLocality': subLocality,
      'locality': locality,
      'subAdministrativeArea': subAdministrativeArea,
      'administrativeArea': administrativeArea,
      'country': country,
      'postalCode': postalCode,
      'fullAddress': fullAddress,
    };
  }
}

/// Model for search results from forward geocoding
class LocationResult {
  final double latitude;
  final double longitude;
  final String displayName;
  final String street;
  final String locality;
  final String subAdministrativeArea;
  final String administrativeArea;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.street,
    required this.locality,
    required this.subAdministrativeArea,
    required this.administrativeArea,
  });

  /// Get municipality/city name
  String get municipality {
    return locality.isNotEmpty 
        ? locality 
        : (subAdministrativeArea.isNotEmpty 
            ? subAdministrativeArea 
            : administrativeArea);
  }

  @override
  String toString() {
    return displayName;
  }
}
