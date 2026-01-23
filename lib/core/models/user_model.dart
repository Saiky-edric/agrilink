import 'package:equatable/equatable.dart';

enum UserRole {
  buyer,
  farmer,
  admin;

  // Add missing methods for compatibility
  String toLowerCase() => name.toLowerCase();
  String toUpperCase() => name.toUpperCase();

  int compareTo(UserRole other) => name.compareTo(other.name);
}

class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final UserRole role;
  final String? municipality;
  final String? barangay;
  final String? street;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isAddressComplete;
  final bool isActive;
  
  // New fields to match database schema
  final String? phone; // Additional phone field in schema
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? storeName;
  final String? storeDescription;
  final String? storeBannerUrl;
  final String? storeLogoUrl;
  final String? storeMessage;
  final String? businessHours;
  final bool isStoreOpen;
  
  // Pickup settings (Phase 1)
  final bool pickupEnabled;
  final String? pickupAddress;
  final String? pickupInstructions;
  final Map<String, dynamic>? pickupHours;

  // Subscription fields
  final String subscriptionTier; // 'free' or 'premium'
  final DateTime? subscriptionExpiresAt;
  final DateTime? subscriptionStartedAt;

  // Alias getters for compatibility
  String get name => fullName;
  String get address => fullAddress;
  
  // Subscription helper getters
  bool get isPremium => subscriptionTier == 'premium' && !isSubscriptionExpired;
  bool get isSubscriptionExpired {
    if (subscriptionExpiresAt == null) return false;
    return subscriptionExpiresAt!.isBefore(DateTime.now());
  }

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.municipality,
    this.barangay,
    this.street,
    required this.createdAt,
    this.updatedAt,
    this.isAddressComplete = false,
    this.isActive = true,
    // New fields
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.storeName,
    this.storeDescription,
    this.storeBannerUrl,
    this.storeLogoUrl,
    this.storeMessage,
    this.businessHours,
    this.isStoreOpen = true,
    // Pickup settings
    this.pickupEnabled = false,
    this.pickupAddress,
    this.pickupInstructions,
    this.pickupHours,
    // Subscription fields
    this.subscriptionTier = 'free',
    this.subscriptionExpiresAt,
    this.subscriptionStartedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both users table (with 'id') and profiles table (with 'user_id')
    final userId = (json['id'] ?? json['user_id'] ?? '') as String;
    
    if (userId.isEmpty) {
      throw Exception('User ID is required but not found in JSON data');
    }

    return UserModel(
      id: userId,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'User',
      phoneNumber: json['phone_number'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.buyer,
      ),
      municipality: json['municipality'] as String?,
      barangay: json['barangay'] as String?,
      street: json['street'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isAddressComplete:
          json['municipality'] != null &&
          json['barangay'] != null &&
          json['street'] != null,
      isActive: json['is_active'] ?? true,
      // New fields from schema
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      storeName: json['store_name'] as String?,
      storeDescription: json['store_description'] as String? ?? 
          (json['role'] == 'farmer' ? 'Fresh agricultural products from our farm.' : null),
      storeBannerUrl: json['store_banner_url'] as String?,
      storeLogoUrl: json['store_logo_url'] as String?,
      storeMessage: json['store_message'] as String?,
      businessHours: json['business_hours'] as String? ?? 
          (json['role'] == 'farmer' ? 'Mon-Sun 6:00 AM - 6:00 PM' : null),
      isStoreOpen: json['is_store_open'] ?? true,
      // Pickup settings
      pickupEnabled: json['pickup_enabled'] as bool? ?? false,
      pickupAddress: json['pickup_address'] as String?,
      pickupInstructions: json['pickup_instructions'] as String?,
      pickupHours: json['pickup_hours'] as Map<String, dynamic>?,
      // Subscription fields
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'] as String)
          : null,
      subscriptionStartedAt: json['subscription_started_at'] != null
          ? DateTime.parse(json['subscription_started_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role.name,
      'municipality': municipality,
      'barangay': barangay,
      'street': street,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      // New fields
      'phone': phone,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'store_name': storeName,
      'store_description': storeDescription,
      'store_banner_url': storeBannerUrl,
      'store_logo_url': storeLogoUrl,
      'store_message': storeMessage,
      'business_hours': businessHours,
      'is_store_open': isStoreOpen,
      // Pickup settings
      'pickup_enabled': pickupEnabled,
      'pickup_address': pickupAddress,
      'pickup_instructions': pickupInstructions,
      'pickup_hours': pickupHours,
      // Subscription fields
      'subscription_tier': subscriptionTier,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'subscription_started_at': subscriptionStartedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    UserRole? role,
    String? municipality,
    String? barangay,
    String? street,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    String? storeName,
    String? storeDescription,
    String? storeBannerUrl,
    String? storeLogoUrl,
    String? storeMessage,
    String? businessHours,
    bool? isStoreOpen,
    bool? pickupEnabled,
    String? pickupAddress,
    String? pickupInstructions,
    Map<String, dynamic>? pickupHours,
    String? subscriptionTier,
    DateTime? subscriptionExpiresAt,
    DateTime? subscriptionStartedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      municipality: municipality ?? this.municipality,
      barangay: barangay ?? this.barangay,
      street: street ?? this.street,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      storeName: storeName ?? this.storeName,
      storeDescription: storeDescription ?? this.storeDescription,
      storeBannerUrl: storeBannerUrl ?? this.storeBannerUrl,
      storeLogoUrl: storeLogoUrl ?? this.storeLogoUrl,
      storeMessage: storeMessage ?? this.storeMessage,
      businessHours: businessHours ?? this.businessHours,
      isStoreOpen: isStoreOpen ?? this.isStoreOpen,
      pickupEnabled: pickupEnabled ?? this.pickupEnabled,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      pickupHours: pickupHours ?? this.pickupHours,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      subscriptionStartedAt: subscriptionStartedAt ?? this.subscriptionStartedAt,
    );
  }

  String get fullAddress {
    if (!isAddressComplete) return 'Address not set';
    return '$street, $barangay, $municipality';
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    phoneNumber,
    role,
    municipality,
    barangay,
    street,
    createdAt,
    updatedAt,
    isActive,
    phone,
    avatarUrl,
    dateOfBirth,
    gender,
    storeName,
    storeDescription,
    storeBannerUrl,
    storeLogoUrl,
    storeMessage,
    businessHours,
    isStoreOpen,
    pickupEnabled,
    pickupAddress,
    pickupInstructions,
    pickupHours,
    subscriptionTier,
    subscriptionExpiresAt,
    subscriptionStartedAt,
  ];
}
