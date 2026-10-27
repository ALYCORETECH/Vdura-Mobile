class Waypoint {
  final int? sequenceOrder;
  final double latitude;
  final double longitude;
  final String? label;
  final double? distanceFromPreviousKm;
  final String? estimationMethod;

  Waypoint({
    this.sequenceOrder,
    required this.latitude,
    required this.longitude,
    this.label,
    this.distanceFromPreviousKm,
    this.estimationMethod,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) {
    return Waypoint(
      sequenceOrder: json['sequenceOrder'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      label: json['label'],
      distanceFromPreviousKm: json['distanceFromPreviousKm']?.toDouble(),
      estimationMethod: json['estimationMethod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (sequenceOrder != null) "sequenceOrder": sequenceOrder,
      "latitude": latitude,
      "longitude": longitude,
      if (label != null) "label": label,
    };
  }
}

class Trip {
  final int id;
  final int salesPersonId;
  final String? salesPersonName;
  final List<Waypoint> waypoints;
  final double? estimatedDistanceKm;
  final String? estimationMethod;
  final double? actualDistanceKm;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;

  Trip({
    required this.id,
    required this.salesPersonId,
    this.salesPersonName,
    this.waypoints = const [],
    this.estimatedDistanceKm,
    this.estimationMethod,
    this.actualDistanceKm,
    required this.status,
    this.startedAt,
    this.endedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    var waypointsList = json['waypoints'] as List? ?? [];
    return Trip(
      id: json['id'] ?? 0,
      salesPersonId: json['salesPersonId'] ?? 0,
      salesPersonName: json['salesPersonName'],
      waypoints: waypointsList.map((w) => Waypoint.fromJson(w)).toList(),
      estimatedDistanceKm: json['estimatedDistanceKm']?.toDouble(),
      estimationMethod: json['estimationMethod'],
      actualDistanceKm: json['actualDistanceKm']?.toDouble(),
      status: json['status'] ?? 'UNKNOWN',
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
    );
  }
}