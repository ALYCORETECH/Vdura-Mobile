// lib/features/transport/models/transport_model.dart

class TransportDetails {
  final int transportId;
  final String transportBy;
  final double ratePerKm;
  final bool isDeleted;

  TransportDetails({
    required this.transportId,
    required this.transportBy,
    required this.ratePerKm,
    required this.isDeleted,
  });

  factory TransportDetails.fromJson(Map<String, dynamic> json) {
    return TransportDetails(
      transportId: json['transportId'] as int,
      transportBy: json['transportBy'] as String,
      // Parse safely as double even if the backend sends an int
      ratePerKm: (json['ratePerKm'] as num).toDouble(),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transportId': transportId,
      'transportBy': transportBy,
      'ratePerKm': ratePerKm,
      'isDeleted': isDeleted,
    };
  }
}

class TransportPayload {
  final String transportBy;
  final double ratePerKm;

  TransportPayload({
    required this.transportBy,
    required this.ratePerKm,
  });

  Map<String, dynamic> toJson() {
    return {
      'transportBy': transportBy,
      'ratePerKm': ratePerKm,
    };
  }
}