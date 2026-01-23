import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();
  
  final SupabaseService _supabase = SupabaseService.instance;

  // Upload image to storage bucket
  Future<String> uploadImage({
    required String bucket,
    required String fileName,
    required File file,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      
      await _supabase.storage.from(bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );
      
      return _supabase.getPublicUrl(bucket, fileName);
    } catch (e) {
      rethrow;
    }
  }

  // Upload farmer verification image
  Future<String> uploadVerificationImage(File image, String fileName) async {
    try {
      return await uploadImage(
        bucket: StorageBuckets.verificationDocuments,
        fileName: fileName,
        file: image,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Upload farmer verification documents
  Future<Map<String, String>> uploadFarmerVerificationDocuments({
    required String farmerId,
    required File farmerIdImage,
    required File barangayCertImage,
    required File selfieImage,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final farmerIdFileName = 'farmer-id/$farmerId-$timestamp-farmer-id.jpg';
      final barangayCertFileName = 'barangay-cert/$farmerId-$timestamp-barangay-cert.jpg';
      final selfieFileName = 'selfie/$farmerId-$timestamp-selfie.jpg';
      
      // Upload all three images
      final List<Future<String>> uploads = [
        uploadImage(
          bucket: StorageBuckets.verificationDocuments,
          fileName: farmerIdFileName,
          file: farmerIdImage,
        ),
        uploadImage(
          bucket: StorageBuckets.verificationDocuments,
          fileName: barangayCertFileName,
          file: barangayCertImage,
        ),
        uploadImage(
          bucket: StorageBuckets.verificationDocuments,
          fileName: selfieFileName,
          file: selfieImage,
        ),
      ];
      
      final List<String> urls = await Future.wait(uploads);
      
      return {
        'farmer_id_url': urls[0],
        'barangay_cert_url': urls[1],
        'selfie_url': urls[2],
      };
    } catch (e) {
      rethrow;
    }
  }

  // Upload product images
  Future<List<String>> uploadProductImages({
    required String farmerId,
    required String productId,
    required List<File> images,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final List<Future<String>> uploads = [];
      
      for (int i = 0; i < images.length; i++) {
        final fileName = 'products/$farmerId/$productId-$timestamp-$i.jpg';
        uploads.add(
          uploadImage(
            bucket: StorageBuckets.productImages,
            fileName: fileName,
            file: images[i],
          ),
        );
      }
      
      return await Future.wait(uploads);
    } catch (e) {
      rethrow;
    }
  }

  // Upload single product image
  Future<String> uploadProductImage({
    required String farmerId,
    required String productId,
    required File image,
    bool isCover = false,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final suffix = isCover ? 'cover' : 'additional';
      final fileName = 'products/$farmerId/$productId-$timestamp-$suffix.jpg';
      
      return await uploadImage(
        bucket: StorageBuckets.productImages,
        fileName: fileName,
        file: image,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Upload user avatar
  Future<String> uploadUserAvatar({
    required String userId,
    required File image,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'avatars/$userId-$timestamp.jpg';
    return await uploadImage(
      bucket: StorageBuckets.userAvatars,
      fileName: fileName,
      file: image,
    );
  }

  // Upload review images with compression
  Future<List<String>> uploadReviewImages({
    required String userId,
    required String productId,
    required List<File> images,
    int quality = 85,
    int maxWidth = 1200,
    int maxHeight = 1200,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final List<Future<String>> uploads = [];
      
      for (int i = 0; i < images.length; i++) {
        final fileName = 'reviews/$userId/$productId-$timestamp-$i.jpg';
        uploads.add(
          uploadImage(
            bucket: StorageBuckets.productImages,
            fileName: fileName,
            file: images[i],
          ),
        );
      }
      
      return await Future.wait(uploads);
    } catch (e) {
      rethrow;
    }
  }

  // Upload payment proof for subscription
  Future<String> uploadPaymentProof(
    File image, {
    required String userId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'payment-proofs/$userId-$timestamp.jpg';
      
      return await uploadImage(
        bucket: StorageBuckets.verificationDocuments,
        fileName: fileName,
        file: image,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Upload image with custom compression settings
  Future<String> uploadCompressedImage({
    required String bucket,
    required String fileName,
    required File file,
    int quality = 85,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      
      await _supabase.storage.from(bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );
      
      return _supabase.getPublicUrl(bucket, fileName);
    } catch (e) {
      rethrow;
    }
  }

  // Delete file from storage
  Future<void> deleteFile({
    required String bucket,
    required String fileName,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([fileName]);
    } catch (e) {
      rethrow;
    }
  }
}