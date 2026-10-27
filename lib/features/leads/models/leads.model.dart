class Lead {
  final int leadId;
  final String name;
  final String mobileNumber;
  final String location;
  final int? photoId;
  final String? photoPath;
  final String? photoBase64;
  final bool isDeleted;
  final int? salesId;
  final String? salesPersonName; // ⬅️ NEW
  final double latitude;         // ⬅️ NEW
  final double longitude;        // ⬅️ NEW

  Lead({
    this.leadId = 0,
    required this.name,
    required this.mobileNumber,
    required this.location,
    this.photoId,
    this.photoPath,
    this.photoBase64,
    this.isDeleted = false,
    this.salesId,
    this.salesPersonName,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      leadId: json['leadId'] ?? 0,
      name: json['name'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      location: json['location'] ?? '',
      photoId: json['photoId'],
      photoPath: json['photoPath'],
      photoBase64: json['photoBase64'],
      isDeleted: json['isDeleted'] ?? false,
      salesId: json['salesId'],
      salesPersonName: json['salesPersonName'],
      // ⬅️ Safely convert to double in case the API sends an integer 0
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      "name": name,
      "mobileNumber": mobileNumber,
      "location": location,
      "photoBase64": photoBase64 ?? "",
      "salesId": salesId ?? 0,
    };
  }
}