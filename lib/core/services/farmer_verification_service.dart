import 'dart:io';
import '../models/farmer_verification_model.dart';
import 'supabase_service.dart';
import 'storage_service.dart';
import 'notification_helper.dart';

class FarmerVerificationService {
  final SupabaseService _supabase = SupabaseService.instance;
  final StorageService _storageService = StorageService.instance;
  final NotificationHelper _notificationHelper = NotificationHelper();

  // Submit farmer verification
  Future<FarmerVerificationModel> submitVerification({
    required String farmerId,
    required String farmName,
    required String farmAddress,
    required File farmerIdImage,
    required File barangayCertImage,
    required File selfieImage,
  }) async {
    try {
      // Validate authentication first
      final currentUser = _supabase.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in and try again.');
      }

      // Ensure the farmerId matches the current user
      if (currentUser.id != farmerId) {
        throw Exception('Authentication mismatch. Cannot submit verification for another user.');
      }

      // Validate user authentication and authorization

      // Check user role and status in database
      final userCheck = await _supabase.client
          .from('users')
          .select('role, is_active, full_name')
          .eq('id', farmerId)
          .maybeSingle();

      if (userCheck == null) {
        throw Exception('User not found in database. Please contact support.');
      }

      if (userCheck['role'] != 'farmer') {
        throw Exception('Only farmers can submit verification requests. Your role: ${userCheck['role']}');
      }

      if (userCheck['is_active'] != true) {
        throw Exception('User account is inactive. Please contact support.');
      }

      // User validation successful

      // Upload verification documents
      final uploadResults = await _storageService.uploadFarmerVerificationDocuments(
        farmerId: farmerId,
        farmerIdImage: farmerIdImage,
        barangayCertImage: barangayCertImage,
        selfieImage: selfieImage,
      );

      // Documents uploaded successfully to storage

      // Create verification record with additional validation data
      final verificationData = {
        'farmer_id': farmerId,
        'farm_name': farmName,
        'farm_address': farmAddress,
        'farmer_id_image_url': uploadResults['farmer_id_url']!,
        'barangay_cert_image_url': uploadResults['barangay_cert_url']!,
        'selfie_image_url': uploadResults['selfie_url']!,
        'status': VerificationStatus.pending.name,
        'user_name': userCheck['full_name'],
        'user_email': currentUser.email,
        'verification_type': 'farmer',
        'submitted_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      // Attempting to insert verification data into database
      
      // Try direct insert to farmer_verifications table with proper error handling
      final response = await _supabase.client
          .from('farmer_verifications')
          .insert(verificationData)
          .select()
          .single();
      final verification = FarmerVerificationModel.fromJson(response);
      
      // Send notification to admins about new verification
      try {
        await _notificationHelper.sendVerificationNotification(
          farmerId: farmerId,
          verificationId: verification.id,
          type: 'new_verification',
        );
      } catch (e) {
        // Log notification error but don't fail the verification process
        print('Warning: Failed to send notification: $e');
      }

      return verification;
    } catch (e) {
      print('ERROR: Failed to submit verification: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('row-level security policy')) {
        throw Exception(
          'Permission denied. Please ensure you are logged in as a farmer and try again. '
          'If the issue persists, contact support. Error: $e'
        );
      } else if (e.toString().contains('foreign key constraint')) {
        throw Exception(
          'Database constraint error. Please contact support. Error: $e'
        );
      } else {
        throw Exception('Failed to submit verification: $e');
      }
    }
  }

  // Get verification status for a farmer
  Future<FarmerVerificationModel?> getVerificationStatus(String farmerId) async {
    try {
      final response = await _supabase.client
          .from('farmer_verifications')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return FarmerVerificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get verification status: $e');
    }
  }

  // Check if farmer is verified
  Future<bool> isFarmerVerified(String farmerId) async {
    try {
      final verification = await getVerificationStatus(farmerId);
      return verification?.isApproved ?? false;
    } catch (e) {
      return false;
    }
  }

  // Resubmit verification (for rejected or needs resubmit status)
  Future<FarmerVerificationModel> resubmitVerification({
    required String farmerId,
    required String farmName,
    required String farmAddress,
    required File farmerIdImage,
    required File barangayCertImage,
    required File selfieImage,
  }) async {
    try {
      // Delete existing verification record if any
      await _supabase.client
          .from('farmer_verifications')
          .delete()
          .eq('farmer_id', farmerId);

      // Submit new verification
      return await submitVerification(
        farmerId: farmerId,
        farmName: farmName,
        farmAddress: farmAddress,
        farmerIdImage: farmerIdImage,
        barangayCertImage: barangayCertImage,
        selfieImage: selfieImage,
      );
    } catch (e) {
      throw Exception('Failed to resubmit verification: $e');
    }
  }

  // Get all verification records (for admin use)
  Future<List<FarmerVerificationModel>> getAllVerifications({
    VerificationStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.client
          .from('farmer_verifications')
          .select();

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((item) => FarmerVerificationModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to get verifications: $e');
    }
  }

  // Update verification status (admin function)
  Future<FarmerVerificationModel> updateVerificationStatus({
    required String verificationId,
    required VerificationStatus status,
    String? rejectionReason,
    String? adminNotes,
    required String adminId,
  }) async {
    try {
      final updateData = {
        'status': status.name,
        'reviewed_by_admin_id': adminId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (rejectionReason != null) {
        updateData['rejection_reason'] = rejectionReason;
      }

      if (adminNotes != null) {
        updateData['admin_notes'] = adminNotes;
      }

      final response = await _supabase.client
          .from('farmer_verifications')
          .update(updateData)
          .eq('id', verificationId)
          .select()
          .single();

      return FarmerVerificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update verification status: $e');
    }
  }

  // Get verification statistics
  Future<Map<String, int>> getVerificationStats() async {
    try {
      final stats = <String, int>{};

      for (final status in VerificationStatus.values) {
        final response = await _supabase.client
            .from('farmer_verifications')
            .select()
            .eq('status', status.name);
        
        stats[status.name] = response.length;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get verification stats: $e');
    }
  }
}