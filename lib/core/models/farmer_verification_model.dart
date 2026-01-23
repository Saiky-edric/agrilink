import 'package:equatable/equatable.dart';

enum VerificationStatus { pending, approved, rejected, needsResubmit }

class FarmerVerificationModel extends Equatable {
  final String id;
  final String farmerId;
  final String farmName;
  final String farmAddress;
  final String farmerIdImageUrl;
  final String barangayCertImageUrl;
  final String selfieImageUrl;
  final VerificationStatus status;
  final String? rejectionReason;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? reviewedByAdminId;
  final DateTime? reviewedAt;
  
  // New fields to match database schema
  final String? reviewedBy;
  final String? reviewNotes;
  final String? userName;
  final String? userEmail;
  final String? verificationType;
  final DateTime? submittedAt;
  final Map<String, dynamic>? farmDetails;

  const FarmerVerificationModel({
    required this.id,
    required this.farmerId,
    required this.farmName,
    required this.farmAddress,
    required this.farmerIdImageUrl,
    required this.barangayCertImageUrl,
    required this.selfieImageUrl,
    required this.status,
    this.rejectionReason,
    this.adminNotes,
    required this.createdAt,
    this.updatedAt,
    this.reviewedByAdminId,
    this.reviewedAt,
    // New fields
    this.reviewedBy,
    this.reviewNotes,
    this.userName,
    this.userEmail,
    this.verificationType,
    this.submittedAt,
    this.farmDetails,
  });

  factory FarmerVerificationModel.fromJson(Map<String, dynamic> json) {
    return FarmerVerificationModel(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      farmName: json['farm_name'] as String,
      farmAddress: json['farm_address'] as String,
      farmerIdImageUrl: json['farmer_id_image_url'] as String,
      barangayCertImageUrl: json['barangay_cert_image_url'] as String,
      selfieImageUrl: json['selfie_image_url'] as String,
      status: VerificationStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => VerificationStatus.pending,
      ),
      rejectionReason: json['rejection_reason'] as String?,
      adminNotes: json['admin_notes'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      reviewedByAdminId: json['reviewed_by_admin_id'] as String?,
      reviewedAt: json['reviewed_at'] != null 
          ? DateTime.parse(json['reviewed_at']) 
          : null,
      // New fields
      reviewedBy: json['reviewed_by'] as String?,
      reviewNotes: json['review_notes'] as String?,
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      verificationType: json['verification_type'] as String? ?? 'farmer',
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
      farmDetails: json['farm_details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'farm_name': farmName,
      'farm_address': farmAddress,
      'farmer_id_image_url': farmerIdImageUrl,
      'barangay_cert_image_url': barangayCertImageUrl,
      'selfie_image_url': selfieImageUrl,
      'status': status.name,
      'rejection_reason': rejectionReason,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'reviewed_by_admin_id': reviewedByAdminId,
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }

  FarmerVerificationModel copyWith({
    String? id,
    String? farmerId,
    String? farmName,
    String? farmAddress,
    String? farmerIdImageUrl,
    String? barangayCertImageUrl,
    String? selfieImageUrl,
    VerificationStatus? status,
    String? rejectionReason,
    String? adminNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reviewedByAdminId,
    DateTime? reviewedAt,
  }) {
    return FarmerVerificationModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmName: farmName ?? this.farmName,
      farmAddress: farmAddress ?? this.farmAddress,
      farmerIdImageUrl: farmerIdImageUrl ?? this.farmerIdImageUrl,
      barangayCertImageUrl: barangayCertImageUrl ?? this.barangayCertImageUrl,
      selfieImageUrl: selfieImageUrl ?? this.selfieImageUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedByAdminId: reviewedByAdminId ?? this.reviewedByAdminId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  bool get isPending => status == VerificationStatus.pending;
  bool get isApproved => status == VerificationStatus.approved;
  bool get isRejected => status == VerificationStatus.rejected;
  bool get needsResubmit => status == VerificationStatus.needsResubmit;

  String get statusDisplayName {
    switch (status) {
      case VerificationStatus.pending:
        return 'Pending Review';
      case VerificationStatus.approved:
        return 'Approved';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.needsResubmit:
        return 'Needs Resubmission';
    }
  }

  @override
  List<Object?> get props => [
        id,
        farmerId,
        farmName,
        farmAddress,
        farmerIdImageUrl,
        barangayCertImageUrl,
        selfieImageUrl,
        status,
        rejectionReason,
        adminNotes,
        createdAt,
        updatedAt,
        reviewedByAdminId,
        reviewedAt,
      ];
}