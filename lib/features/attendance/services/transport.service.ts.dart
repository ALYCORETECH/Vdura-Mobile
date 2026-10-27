// lib/features/transport/services/transport_service.dart

import 'package:sales_management/core/network/api_constants.dart';
import 'package:sales_management/core/services/base_api_service.dart';
import 'package:sales_management/features/attendance/models/transport.model.dart';

class TransportService {
  final BaseApiService _apiService;

  TransportService(this._apiService);

  /// Fetches all transport records
  Future<List<TransportDetails>> getAllTransports() async {
    final response = await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/transport-details', method: 'GET'),
      options: VanguardeRequestOptions(showLoader: true),
    );

    // Safely map the JSON array into your Dart objects
    final List<dynamic> list = response ?? [];
    return list.map((json) => TransportDetails.fromJson(json)).toList();
  }

  /// Fetches a specific transport record by ID
  Future<TransportDetails> getTransportById(int transportId) async {
    final response = await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/transport-details/{transportId}', method: 'GET'),
      options: VanguardeRequestOptions(
        showLoader: true,
        pathParams: {'transportId': transportId.toString()},
      ),
    );
    return TransportDetails.fromJson(response);
  }

  /// Creates a new transport record
  Future<TransportDetails> createTransport(TransportPayload payload) async {
    final response = await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/transport-details', method: 'POST'),
      body: payload.toJson(),
      options: VanguardeRequestOptions(
        showLoader: true,
        successMessage: 'Transport mode created successfully!', // Triggers UiFeedbackService
      ),
    );
    return TransportDetails.fromJson(response);
  }

  /// Updates an existing transport record
  Future<TransportDetails> updateTransport(int transportId, TransportPayload payload) async {
    final response = await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/transport-details/{transportId}', method: 'PUT'),
      body: payload.toJson(),
      options: VanguardeRequestOptions(
        showLoader: true,
        pathParams: {'transportId': transportId.toString()},
        successMessage: 'Transport mode updated!',
      ),
    );
    return TransportDetails.fromJson(response);
  }

  /// Soft deletes a transport record
  Future<void> deleteTransport(int transportId) async {
    await _apiService.request<dynamic>(
      EndpointConfig(url: '/api/transport-details/{transportId}', method: 'DELETE'),
      options: VanguardeRequestOptions(
        showLoader: true,
        pathParams: {'transportId': transportId.toString()},
        successMessage: 'Transport mode deleted.',
      ),
    );
  }
}