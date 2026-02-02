import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// Service to manage device identification and trusted devices
class DeviceService {
  static const String _deviceIdKey = 'device_id';
  static const String _trustedDevicesKey = 'trusted_devices';

  /// Get or create a unique device ID
  Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if device ID already exists
      String? deviceId = prefs.getString(_deviceIdKey);

      if (deviceId == null || deviceId.isEmpty) {
        // Generate new device ID
        deviceId = const Uuid().v4();
        await prefs.setString(_deviceIdKey, deviceId);
        debugPrint('🆔 New device ID created: $deviceId');
      } else {
        debugPrint('🆔 Existing device ID found: $deviceId');
      }

      return deviceId;
    } catch (e) {
      debugPrint('❌ Error getting device ID: $e');
      // Return a temporary ID if there's an error
      return const Uuid().v4();
    }
  }

  /// Check if this device is trusted for a specific user
  Future<bool> isDeviceTrusted(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await getDeviceId();

      // Get trusted devices map
      final trustedDevicesJson = prefs.getString(_trustedDevicesKey);

      if (trustedDevicesJson == null) {
        debugPrint('🔒 No trusted devices found');
        return false;
      }

      final Map<String, dynamic> trustedDevices =
          json.decode(trustedDevicesJson);

      // Check if this user has trusted this device
      final userDevices = trustedDevices[userId];

      if (userDevices == null) {
        debugPrint('🔒 User $userId has no trusted devices');
        return false;
      }

      final bool isTrusted = userDevices[deviceId] == true;

      if (isTrusted) {
        debugPrint('✅ Device is trusted for user $userId');
      } else {
        debugPrint('🔒 Device is NOT trusted for user $userId');
      }

      return isTrusted;
    } catch (e) {
      debugPrint('❌ Error checking device trust: $e');
      return false;
    }
  }

  /// Mark this device as trusted for a specific user
  Future<void> trustDevice(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await getDeviceId();

      // Get existing trusted devices
      final trustedDevicesJson = prefs.getString(_trustedDevicesKey);
      Map<String, dynamic> trustedDevices = {};

      if (trustedDevicesJson != null) {
        trustedDevices = json.decode(trustedDevicesJson);
      }

      // Add this device for this user
      if (!trustedDevices.containsKey(userId)) {
        trustedDevices[userId] = {};
      }

      trustedDevices[userId][deviceId] = true;

      // Save updated trusted devices
      await prefs.setString(_trustedDevicesKey, json.encode(trustedDevices));

      debugPrint('✅ Device trusted for user $userId');
    } catch (e) {
      debugPrint('❌ Error trusting device: $e');
    }
  }

  /// Remove trust for this device for a specific user
  Future<void> untrustDevice(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await getDeviceId();

      // Get existing trusted devices
      final trustedDevicesJson = prefs.getString(_trustedDevicesKey);

      if (trustedDevicesJson == null) return;

      Map<String, dynamic> trustedDevices = json.decode(trustedDevicesJson);

      // Remove this device for this user
      if (trustedDevices.containsKey(userId)) {
        trustedDevices[userId].remove(deviceId);

        // Remove user entry if no devices left
        if (trustedDevices[userId].isEmpty) {
          trustedDevices.remove(userId);
        }
      }

      // Save updated trusted devices
      await prefs.setString(_trustedDevicesKey, json.encode(trustedDevices));

      debugPrint('🔓 Device untrusted for user $userId');
    } catch (e) {
      debugPrint('❌ Error untrusting device: $e');
    }
  }

  /// Clear all trusted devices (useful for logout)
  Future<void> clearAllTrustedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_trustedDevicesKey);
      debugPrint('🗑️ All trusted devices cleared');
    } catch (e) {
      debugPrint('❌ Error clearing trusted devices: $e');
    }
  }

  /// Clear trusted devices for a specific user
  Future<void> clearUserTrustedDevices(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trustedDevicesJson = prefs.getString(_trustedDevicesKey);

      if (trustedDevicesJson == null) return;

      Map<String, dynamic> trustedDevices = json.decode(trustedDevicesJson);
      trustedDevices.remove(userId);

      await prefs.setString(_trustedDevicesKey, json.encode(trustedDevices));

      debugPrint('🗑️ Trusted devices cleared for user $userId');
    } catch (e) {
      debugPrint('❌ Error clearing user trusted devices: $e');
    }
  }

  /// Get count of trusted devices for a user
  Future<int> getTrustedDeviceCount(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trustedDevicesJson = prefs.getString(_trustedDevicesKey);

      if (trustedDevicesJson == null) return 0;

      final Map<String, dynamic> trustedDevices =
          json.decode(trustedDevicesJson);
      final userDevices = trustedDevices[userId];

      if (userDevices == null) return 0;

      return (userDevices as Map).length;
    } catch (e) {
      debugPrint('❌ Error getting trusted device count: $e');
      return 0;
    }
  }

  /// Check if current device ID matches
  Future<bool> isCurrentDevice(String deviceIdToCheck) async {
    final currentDeviceId = await getDeviceId();
    return currentDeviceId == deviceIdToCheck;
  }
}
