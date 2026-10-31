// lib/features/profile/models/profile_model.dart

class SalesPersonProfile {
  final int userId;
  final String username;
  final String role;
  final int salesPersonId;
  final String designationName;
  final String fullName;
  final String mobileNumber;
  final String aadharId;
  final String pancard;
  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String area;
  final String city;
  final String state;
  final String pinCode;
  final String country;
  final String? photoBase64;

  SalesPersonProfile({
    required this.userId,
    required this.username,
    required this.role,
    required this.salesPersonId,
    required this.designationName,
    required this.fullName,
    required this.mobileNumber,
    required this.aadharId,
    required this.pancard,
    required this.addressLine1,
    required this.addressLine2,
    required this.landmark,
    required this.area,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.country,
    this.photoBase64,
  });

  factory SalesPersonProfile.fromJson(Map<String, dynamic> json) {
    return SalesPersonProfile(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      salesPersonId: json['salesPersonId'] ?? 0,
      designationName: json['designationName'] ?? 'No Designation',
      fullName: json['fullName'] ?? 'Unknown User',
      mobileNumber: json['mobileNumber'] ?? '',
      aadharId: json['aadharId'] ?? '',
      pancard: json['pancard'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      landmark: json['landmark'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pinCode: json['pinCode'] ?? '',
      country: json['country'] ?? '',
      photoBase64: json['photoBase64'],
    );
  }
}