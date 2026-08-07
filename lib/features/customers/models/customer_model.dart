class CustomerModel {
  final int? id;

  final String customerName;
  final String phone;

  final String? address;
  final String? aadharNumber;
  final String? pincode;

  final String? vehicleType;
  final String? vehicleNumber;

  // NEW OPTIONAL FIELD
  final String? keyCuttingNumber;

  final String? customerPhoto;
  final String? rcPhoto;

  final String? aadharFrontPhoto;
  final String? aadharBackPhoto;

  final DateTime createdAt;

  const CustomerModel({
    this.id,
    required this.customerName,
    required this.phone,
    this.address,
    this.aadharNumber,
    this.pincode,
    this.vehicleType,
    this.vehicleNumber,
    this.keyCuttingNumber,
    this.customerPhoto,
    this.rcPhoto,
    this.aadharFrontPhoto,
    this.aadharBackPhoto,
    required this.createdAt,
  });

  // Create model from SQLite map
  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int?,
      customerName: map['customer_name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'],
      aadharNumber: map['aadhar_number'],
      pincode: map['pincode'],
      vehicleType: map['vehicle_type'],
      vehicleNumber: map['vehicle_number'],
      keyCuttingNumber: map['key_cutting_number'],
      customerPhoto: map['customer_photo'],
      rcPhoto: map['rc_photo'],
      aadharFrontPhoto: map['aadhar_front_photo'],
      aadharBackPhoto: map['aadhar_back_photo'],
      createdAt:
      DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  // Convert model to SQLite map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'aadhar_number': aadharNumber,
      'pincode': pincode,
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'key_cutting_number': keyCuttingNumber,
      'customer_photo': customerPhoto,
      'rc_photo': rcPhoto,
      'aadhar_front_photo': aadharFrontPhoto,
      'aadhar_back_photo': aadharBackPhoto,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create a modified copy
  CustomerModel copyWith({
    int? id,
    String? customerName,
    String? phone,
    String? address,
    String? aadharNumber,
    String? pincode,
    String? vehicleType,
    String? vehicleNumber,
    String? keyCuttingNumber,
    String? customerPhoto,
    String? rcPhoto,
    String? aadharFrontPhoto,
    String? aadharBackPhoto,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      pincode: pincode ?? this.pincode,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      keyCuttingNumber:
      keyCuttingNumber ?? this.keyCuttingNumber,
      customerPhoto: customerPhoto ?? this.customerPhoto,
      rcPhoto: rcPhoto ?? this.rcPhoto,
      aadharFrontPhoto:
      aadharFrontPhoto ?? this.aadharFrontPhoto,
      aadharBackPhoto:
      aadharBackPhoto ?? this.aadharBackPhoto,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters

  /// Mask Aadhaar for list display
  String get maskedAadhar {
    if (aadharNumber == null || aadharNumber!.isEmpty) {
      return '';
    }

    final cleaned = aadharNumber!.replaceAll(' ', '');

    if (cleaned.length < 4) return aadharNumber!;

    return 'XXXX XXXX ${cleaned.substring(cleaned.length - 4)}';
  }

  /// Initials for avatar
  String get initials {
    final parts = customerName.trim().split(' ');

    if (parts.isEmpty) return '';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) +
        parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Whether customer photo exists
  bool get hasCustomerPhoto =>
      customerPhoto != null && customerPhoto!.isNotEmpty;

  bool get hasRcPhoto =>
      rcPhoto != null && rcPhoto!.isNotEmpty;

  bool get hasAadharFrontPhoto =>
      aadharFrontPhoto != null &&
          aadharFrontPhoto!.isNotEmpty;

  bool get hasAadharBackPhoto =>
      aadharBackPhoto != null &&
          aadharBackPhoto!.isNotEmpty;

  bool get hasKeyCuttingNumber =>
      keyCuttingNumber != null &&
          keyCuttingNumber!.isNotEmpty;

  @override
  String toString() {
    return 'CustomerModel(id: $id, name: $customerName, phone: $phone, keyCuttingNumber: $keyCuttingNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CustomerModel &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}