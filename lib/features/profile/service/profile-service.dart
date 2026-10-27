// lib/features/profile/services/profile_service.dart
import 'package:sales_management/core/network/api_constants.dart';
import 'package:sales_management/core/services/base_api_service.dart';
import 'package:sales_management/features/profile/models/profile-model.dart';

class ProfileService {
  final BaseApiService _apiService;

  ProfileService(this._apiService);

  Future<SalesPersonProfile> getProfile(int userId) async {
    final endpoint = EndpointConfig(
      url: '/api/sales-persons/{userId}',
      method: 'GET',
    );
    final response = await _apiService.request<Map<String, dynamic>>(
      endpoint,
      options: VanguardeRequestOptions(
        pathParams: {'userId': userId.toString()},
        showLoader: false, // ProfileScreen handles its own loading spinner
      ),
    );

    if (response != null) {
      return SalesPersonProfile.fromJson(response);
    } else {
      throw Exception('Failed to load profile data');
    }
  }
}