class Dealer {
  final int dealerId;
  final String dealerName;
  final String mobileNo;
  final String emailId;
  final String adharCard;
  final String panCard;
  final String gst;
  final int? addressId;
  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String area;
  final String city;
  final String state;
  final String pinCode;
  final String country;
  final bool isActive;
  final bool isDeleted;
  final String? username;
  final String? password;
  final int? salesPersonId;

  Dealer({
    this.dealerId = 0,
    required this.dealerName,
    required this.mobileNo,
    this.emailId = "",
    this.adharCard = "",
    this.panCard = "",
    this.gst = "",
    this.addressId,
    this.addressLine1 = "",
    this.addressLine2 = "",
    this.landmark = "",
    this.area = "",
    this.city = "",
    this.state = "",
    this.pinCode = "",
    this.country = "",
    this.isActive = true,
    this.isDeleted = false,
    this.username,
    this.password,
    this.salesPersonId,
  });

  factory Dealer.fromJson(Map<String, dynamic> json) {
    return Dealer(
      dealerId: json['dealerId'] ?? 0,
      dealerName: json['dealerName'] ?? '',
      mobileNo: json['mobileNo'] ?? '',
      emailId: json['emailId'] ?? '',
      adharCard: json['adharCard'] ?? '',
      panCard: json['panCard'] ?? '',
      gst: json['gst'] ?? '',
      addressId: json['addressId'],
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      landmark: json['landmark'] ?? '',
      area: json['area'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pinCode: json['pinCode'] ?? '',
      country: json['country'] ?? '',
      isActive: json['isActive'] ?? true,
      isDeleted: json['isDeleted'] ?? false,
      username: json['username'],
      password: json['password'],
      salesPersonId: json['salesPersonId'],
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      "dealerName": dealerName,
      "mobileNo": mobileNo,
      "emailId": emailId,
      "adharCard": adharCard,
      "panCard": panCard,
      "gst": gst,
      "addressLine1": addressLine1,
      "addressLine2": addressLine2,
      "landmark": landmark,
      "area": area,
      "city": city,
      "state": state,
      "pinCode": pinCode,
      "country": country,
      "username": username ?? "",
      "password": password ?? "",
      "salesPersonId": salesPersonId ?? 0,
    };
  }
}