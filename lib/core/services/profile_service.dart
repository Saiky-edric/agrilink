import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/environment.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final SupabaseClient _supabase = SupabaseService.instance.client;
  
  // Cache for user profile
  UserModel? _cachedProfile;
  DateTime? _cacheTime;
  
  // Cache duration: 5 minutes
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  /// Get current user profile with caching
  Future<UserModel?> getCurrentUserProfile({bool forceRefresh = false}) async {
    try {
      // Check cache first
      if (!forceRefresh && 
          _cachedProfile != null && 
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheValidDuration) {
        EnvironmentConfig.log('ProfileService: Returning cached profile');
        return _cachedProfile;
      }

      // Get current auth user
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        EnvironmentConfig.log('ProfileService: No authenticated user');
        return null;
      }

      EnvironmentConfig.log('ProfileService: Loading profile for user ${authUser.id}');

      // Query user profile from database
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (response == null) {
        EnvironmentConfig.logError('ProfileService: No profile found for user', authUser.id);
        return null;
      }

      // Create user model
      final userProfile = UserModel.fromJson(response);
      
      // Cache the result
      _cachedProfile = userProfile;
      _cacheTime = DateTime.now();
      
      EnvironmentConfig.log('ProfileService: Successfully loaded profile for ${userProfile.fullName}');
      return userProfile;

    } catch (e) {
      EnvironmentConfig.logError('ProfileService: Error loading user profile', e);
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(UserModel updatedUser) async {
    try {
      EnvironmentConfig.log('ProfileService: Updating profile for ${updatedUser.id}');

      await _supabase
          .from('users')
          .update({
            'full_name': updatedUser.fullName,
            'phone_number': updatedUser.phoneNumber,
            'municipality': updatedUser.municipality,
            'barangay': updatedUser.barangay,
            'street': updatedUser.street,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', updatedUser.id);

      // Invalidate cache
      _cachedProfile = null;
      _cacheTime = null;

      EnvironmentConfig.log('ProfileService: Profile updated successfully');
      return true;

    } catch (e) {
      EnvironmentConfig.logError('ProfileService: Error updating profile', e);
      return false;
    }
  }

  /// Update avatar URL
  Future<bool> updateAvatar(String avatarUrl) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return false;
      await _supabase
          .from('users')
          .update({
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', authUser.id);
      // Invalidate cache
      _cachedProfile = null;
      _cacheTime = null;
      return true;
    } catch (e) {
      EnvironmentConfig.logError('ProfileService: Error updating avatar', e);
      return false;
    }
  }

  /// Clear avatar URL
  Future<bool> clearAvatar() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return false;
      await _supabase
          .from('users')
          .update({
            'avatar_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', authUser.id);
      _cachedProfile = null;
      _cacheTime = null;
      return true;
    } catch (e) {
      EnvironmentConfig.logError('ProfileService: Error clearing avatar', e);
      return false;
    }
  }

  /// Get user stats for profile display
  Future<Map<String, dynamic>> getUserStats(String userId, UserRole role) async {
    try {
      Map<String, dynamic> stats = {};

      if (role == UserRole.farmer) {
        // Get farmer stats
        final products = await _supabase
            .from('products')
            .select('id, is_hidden')
            .eq('farmer_id', userId);

        final orders = await _supabase
            .from('orders')
            .select('id, farmer_status')
            .eq('farmer_id', userId);

        stats = {
          'total_products': products.length,
          'active_products': products.where((p) => p['is_hidden'] == false).length,
          'total_orders': orders.length,
          'completed_orders': orders.where((o) => o['farmer_status'] == 'completed').length,
        };

      } else if (role == UserRole.buyer) {
        // Get buyer stats
        final orders = await _supabase
            .from('orders')
            .select('id, buyer_status, total_amount')
            .eq('buyer_id', userId);

        final totalSpent = orders.fold<double>(
          0.0, 
          (sum, order) => sum + (order['total_amount'] as num).toDouble()
        );

        stats = {
          'total_orders': orders.length,
          'completed_orders': orders.where((o) => o['buyer_status'] == 'delivered').length,
          'total_spent': totalSpent,
          'favorite_products': 0, // Favorites feature to be implemented
        };
      }

      return stats;

    } catch (e) {
      EnvironmentConfig.logError('ProfileService: Error loading user stats', e);
      return {};
    }
  }

  /// Get farmer verification status
  Future<Map<String, dynamic>> getFarmerVerificationStatus(String farmerId) async {
    try {
      final verification = await _supabase
          .from('farmer_verifications')
          .select('status, rejection_reason, reviewed_at')
          .eq('farmer_id', farmerId)
          .maybeSingle();

      if (verification == null) {
        return {
          'status': 'not_submitted',
          'message': 'Verification not yet submitted',
          'isVerified': false,
        };
      }

      final status = verification['status'];
      bool isVerified = status == 'approved';

      String message;
      switch (status) {
        case 'pending':
          message = 'Verification under review';
          break;
        case 'approved':
          message = 'Verified farmer';
          break;
        case 'rejected':
          message = verification['rejection_reason'] ?? 'Verification rejected';
          break;
        default:
          message = 'Unknown verification status';
      }

      return {
        'status': status,
        'message': message,
        'isVerified': isVerified,
        'reviewed_at': verification['reviewed_at'],
      };

    } catch (e) {
      EnvironmentConfig.logError('ProfileService: Error loading verification status', e);
      return {
        'status': 'error',
        'message': 'Could not load verification status',
        'isVerified': false,
      };
    }
  }

  /// Clear profile cache (useful for logout)
  void clearCache() {
    _cachedProfile = null;
    _cacheTime = null;
    EnvironmentConfig.log('ProfileService: Cache cleared');
  }

  /// Check if user has complete profile
  bool hasCompleteProfile(UserModel? user) {
    if (user == null) return false;
    
    return user.fullName.isNotEmpty &&
           user.phoneNumber.isNotEmpty &&
           user.municipality != null &&
           user.barangay != null &&
           user.street != null;
  }

  /// Get profile completion percentage
  int getProfileCompletionPercentage(UserModel? user) {
    if (user == null) return 0;
    
    int completedFields = 0;
    const int totalFields = 6;
    
    if (user.fullName.isNotEmpty) completedFields++;
    if (user.email.isNotEmpty) completedFields++;
    if (user.phoneNumber.isNotEmpty) completedFields++;
    if (user.municipality?.isNotEmpty == true) completedFields++;
    if (user.barangay?.isNotEmpty == true) completedFields++;
    if (user.street?.isNotEmpty == true) completedFields++;
    
    return ((completedFields / totalFields) * 100).round();
  }
}