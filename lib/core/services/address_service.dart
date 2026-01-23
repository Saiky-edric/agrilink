import '../models/address_model.dart';
import 'supabase_service.dart';

class AddressService {
  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

  final SupabaseService _supabase = SupabaseService.instance;

  /// Get all addresses for a user
  Future<List<AddressModel>> getUserAddresses(String userId) async {
    try {
      final response = await _supabase.client
          .from('user_addresses')
          .select('*')
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return response
          .map<AddressModel>((json) => AddressModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching user addresses: $e');
      rethrow;
    }
  }

  /// Get user's default address
  Future<AddressModel?> getDefaultAddress(String userId) async {
    try {
      final response = await _supabase.client
          .from('user_addresses')
          .select('*')
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response != null) {
        return AddressModel.fromJson(response);
      }

      // If no default address, get the first one
      final addresses = await getUserAddresses(userId);
      return addresses.isNotEmpty ? addresses.first : null;
    } catch (e) {
      print('Error fetching default address: $e');
      rethrow;
    }
  }

  /// Create a new address
  Future<AddressModel> createAddress({
    required String userId,
    required String name,
    required String streetAddress,
    required String barangay,
    required String municipality,
    String province = 'Agusan del Sur',
    String postalCode = '',
    bool isDefault = false,
  }) async {
    try {
      // If this is set as default, remove default from other addresses
      if (isDefault) {
        await _removeDefaultFromAllAddresses(userId);
      }

      final addressData = {
        'user_id': userId,
        'name': name,
        'street_address': streetAddress,
        'barangay': barangay,
        'municipality': municipality,
        'postal_code': postalCode,
        'is_default': isDefault,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase.client
          .from('user_addresses')
          .insert(addressData)
          .select()
          .single();

      return AddressModel.fromJson(response);
    } catch (e) {
      print('Error creating address: $e');
      rethrow;
    }
  }

  /// Update an existing address
  Future<AddressModel> updateAddress({
    required String addressId,
    required String userId,
    String? name,
    String? streetAddress,
    String? barangay,
    String? municipality,
    String? province,
    String? postalCode,
    bool? isDefault,
  }) async {
    try {
      // If setting as default, remove default from other addresses
      if (isDefault == true) {
        await _removeDefaultFromAllAddresses(userId);
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (streetAddress != null) updateData['street_address'] = streetAddress;
      if (barangay != null) updateData['barangay'] = barangay;
      if (municipality != null) updateData['municipality'] = municipality;
      if (postalCode != null) updateData['postal_code'] = postalCode;
      if (isDefault != null) updateData['is_default'] = isDefault;
      
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase.client
          .from('user_addresses')
          .update(updateData)
          .eq('id', addressId)
          .eq('user_id', userId)
          .select()
          .single();

      return AddressModel.fromJson(response);
    } catch (e) {
      print('Error updating address: $e');
      rethrow;
    }
  }

  /// Delete an address
  Future<void> deleteAddress(String addressId, String userId) async {
    try {
      await _supabase.client
          .from('user_addresses')
          .delete()
          .eq('id', addressId)
          .eq('user_id', userId);

      // If we deleted the default address, make the first remaining address default
      final remainingAddresses = await getUserAddresses(userId);
      if (remainingAddresses.isNotEmpty && !remainingAddresses.any((a) => a.isDefault)) {
        await setDefaultAddress(userId, remainingAddresses.first.id);
      }
    } catch (e) {
      print('Error deleting address: $e');
      rethrow;
    }
  }

  /// Set an address as default
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      // First remove default from all user addresses
      await _removeDefaultFromAllAddresses(userId);
      
      // Then set the selected address as default
      await _supabase.client
          .from('user_addresses')
          .update({'is_default': true})
          .eq('id', addressId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error setting default address: $e');
      rethrow;
    }
  }

  /// Remove default status from all user addresses
  Future<void> _removeDefaultFromAllAddresses(String userId) async {
    try {
      await _supabase.client
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId);
    } catch (e) {
      print('Error removing default status: $e');
      rethrow;
    }
  }

  /// Migrate profile address to user_addresses table if needed
  Future<void> migrateProfileAddress({
    required String userId,
    required String municipality,
    required String barangay,
    String? street,
  }) async {
    try {
      // Check if user already has addresses
      final existingAddresses = await getUserAddresses(userId);
      if (existingAddresses.isNotEmpty) {
        return; // User already has addresses, no need to migrate
      }

      // Create a "Home" address from profile data
      await createAddress(
        userId: userId,
        name: 'Home',
        streetAddress: street ?? 'Street not specified',
        barangay: barangay,
        municipality: municipality,
        isDefault: true,
      );
    } catch (e) {
      print('Error migrating profile address: $e');
      rethrow;
    }
  }

  /// Check if user has any addresses
  Future<bool> hasAddresses(String userId) async {
    try {
      final addresses = await getUserAddresses(userId);
      return addresses.isNotEmpty;
    } catch (e) {
      print('Error checking user addresses: $e');
      return false;
    }
  }
}