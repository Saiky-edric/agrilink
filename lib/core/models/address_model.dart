class AddressModel {
  String id;
  String name;
  String streetAddress;
  String barangay;
  String municipality;
  String province;
  String postalCode;
  bool isDefault;
  double? latitude;
  double? longitude;
  double? accuracy;
  DateTime? createdAt;
  DateTime? updatedAt;

  AddressModel({
    required this.id,
    required this.name,
    required this.streetAddress,
    required this.barangay,
    required this.municipality,
    this.province = 'Agusan del Sur',
    this.postalCode = '',
    required this.isDefault,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.createdAt,
    this.updatedAt,
  });

  String get fullAddress {
    final parts = [streetAddress, barangay, municipality];
    if (province.isNotEmpty) parts.add(province);
    if (postalCode.isNotEmpty) parts.add(postalCode);
    return parts.join(', ');
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Address',
      streetAddress: json['street_address'] as String,
      barangay: json['barangay'] as String,
      municipality: json['municipality'] as String,
      province: json['province'] as String? ?? 'Agusan del Sur',
      postalCode: json['postal_code'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      accuracy: json['accuracy'] as double?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'street_address': streetAddress,
      'barangay': barangay,
      'municipality': municipality,
      'province': province,
      'postal_code': postalCode,
      'is_default': isDefault,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AddressModel copyWith({
    String? id,
    String? name,
    String? streetAddress,
    String? barangay,
    String? municipality,
    String? province,
    String? postalCode,
    bool? isDefault,
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      name: name ?? this.name,
      streetAddress: streetAddress ?? this.streetAddress,
      barangay: barangay ?? this.barangay,
      municipality: municipality ?? this.municipality,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}