// lib/features/sales/services/trip_service.dart
import 'package:sales_management/core/services/base_api_service.dart';
import 'package:sales_management/core/network/api_constants.dart';
import 'package:sales_management/features/attendance/models/ping_model.dart';
import 'package:sales_management/features/attendance/models/trip_model.dart';


class TripService {
  final BaseApiService _apiService;

  TripService(this._apiService);

  // ── 1. Start a new trip (Punch In) ──
  Future<Trip> startTrip(int salesPersonId, int transportId, Waypoint startWaypoint) async {
    final response = await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/trips', method: 'POST'),
      body: {
        "salesPersonId": salesPersonId,
        "transportId": transportId,           // ⬅️ Added transportId to JSON
        "waypoint": startWaypoint.toJson(),   // ⬅️ Changed from 'waypoints' list to single 'waypoint'
      },
      options: VanguardeRequestOptions(showLoader: true),
    );
    return Trip.fromJson(response);
  }

  // ── 2. Get trip details ──
  Future<Trip> getTrip(int tripId) async {
    final response = await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/trips/{tripId}', method: 'GET'),
      options: VanguardeRequestOptions(
        showLoader: false,
        pathParams: {'tripId': tripId.toString()}, // ⬅️ Using your dynamic path injector!
      ),
    );
    return Trip.fromJson(response);
  }

  // ── 3. End a trip (Punch Out) ──
  Future<Trip> endTrip(int tripId) async {
    final response = await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/trips/{tripId}/end', method: 'POST'),
      options: VanguardeRequestOptions(
        showLoader: true,
        pathParams: {'tripId': tripId.toString()},
      ),
    );
    return Trip.fromJson(response);
  }

  // ── 4. Send a single waypoint (For Lead & Dealer Geotagging) ──
  Future<void> sendPing(int tripId, Ping ping, {int? leadId, int? dealerId}) async {
    await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/trips/{tripId}/waypoint', method: 'POST'),
      body: {
        "latitude": ping.latitude,
        "longitude": ping.longitude,
        "accuracy": ping.accuracy ?? 0.0,
        "capturedAt": ping.capturedAt?.toIso8601String(),
        if (leadId != null) "leadId": leadId,
        if (dealerId != null) "dealerId": dealerId,
      },
      options: VanguardeRequestOptions(
        showLoader: false,
        pathParams: {'tripId': tripId.toString()},
      ),
    );
  }

  Future<void> sendBatchPings(int tripId, List<Ping> pings) async {
    await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/trips/{tripId}/pings/batch', method: 'POST'),
      body: {
        "pings": pings.map((p) => p.toJson()).toList(),
      },
      options: VanguardeRequestOptions(
        showLoader: false,
        pathParams: {'tripId': tripId.toString()},
      ),
    );
  }

  Future<List<Trip>> getTripsForSalesPerson(int salesPersonId) async {
    final response = await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/trips?salesPersonId=$salesPersonId', method: 'GET'),
      options: VanguardeRequestOptions(
        showLoader: false,
      ),
    );

    // Maps the JSON list into your Trip models safely
    final List<dynamic> list = response ?? [];
    return list.map((json) => Trip.fromJson(json)).toList();
  }
}