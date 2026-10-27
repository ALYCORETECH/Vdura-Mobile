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
  final String city;
  final String state;
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
    required this.city,
    required this.state,
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
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      photoBase64: json['photoBase64'],
    );
  }
}