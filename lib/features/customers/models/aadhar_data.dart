class AadhaarData {
  final String? name;
  final String? aadhaarNumber;
  final String? address;
  final String? pincode;

  const AadhaarData({
    this.name,
    this.aadhaarNumber,
    this.address,
    this.pincode,
  });

  AadhaarData copyWith({
    String? name,
    String? aadhaarNumber,
    String? address,
    String? pincode,
  }) {
    return AadhaarData(
      name: name ?? this.name,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      address: address ?? this.address,
      pincode: pincode ?? this.pincode,
    );
  }
}