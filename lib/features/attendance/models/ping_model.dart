class Ping {
  final int? id; // Returned by GET, not needed for POST
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime capturedAt;
  final int? leadId; // ── ADDED FOR LEAD GEOTAGGING ──
  final int? dealerId; // ── ADDED FOR DEALER GEOTAGGING ──

  Ping({
    this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.capturedAt,
    this.leadId,
    this.dealerId, // ⬅️ NEW
  });

  factory Ping.fromJson(Map<String, dynamic> json) {
    return Ping(
      id: json['id'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      capturedAt: DateTime.parse(json['capturedAt']),
      leadId: json['leadId'],
      dealerId: json['dealerId'], // ⬅️ NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "latitude": latitude,
      "longitude": longitude,
      if (accuracy != null) "accuracy": accuracy,
      "capturedAt": capturedAt.toUtc().toIso8601String(),
      if (leadId != null) "leadId": leadId, // Attaches the lead if present
      if (dealerId != null) "dealerId": dealerId,
    };
  }
}

class BatchPingResponse {
  final int received;
  final int accepted;
  final int rejectedAsNoise;
  final double actualDistanceKm;

  BatchPingResponse({
    required this.received,
    required this.accepted,
    required this.rejectedAsNoise,
    required this.actualDistanceKm,
  });

  factory BatchPingResponse.fromJson(Map<String, dynamic> json) {
    return BatchPingResponse(
      received: json['received'] ?? 0,
      accepted: json['accepted'] ?? 0,
      rejectedAsNoise: json['rejectedAsNoise'] ?? 0,
      actualDistanceKm: (json['actualDistanceKm'] ?? 0).toDouble(),
    );
  }
}