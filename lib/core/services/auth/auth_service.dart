import 'package:flutter/foundation.dart';
import 'package:sales_management/core/models/auth_response.dart';
import '../base_api_service.dart';
import '../../network/api_constants.dart';

class AuthService {
  final BaseApiService _api;
  AuthService(this._api);
  Future<String?> login(String username, String password) async {
    final credentials = {
      'username': username,
      'password': password,
    };

    try {
      final responseBody = await _api.request<Map<String, dynamic>>(
        ApiEndpoints.authLogin,
        body: credentials,
        options: VanguardeRequestOptions(
          showLoader: true,
          successMessage: 'Login successful!',
        ),
      );

      if (responseBody != null) {
        debugPrint('🔥 RAW API RESPONSE: $responseBody');

        Map<String, dynamic> dataToParse;

        // 1. Check if the BaseApiService ALREADY unwrapped it
        if (responseBody.containsKey('token') && responseBody.containsKey('role')) {
          dataToParse = responseBody;
        }
        // 2. Check if it's still wrapped in the outer layer
        else if (responseBody.containsKey('data')) {
          dataToParse = responseBody['data'];
        }
        // 3. Fallback if the structure is completely unrecognized
        else {
          debugPrint('❌ LOGIN ERROR: Unrecognized JSON structure.');
          return null;
        }

        // Pass the correct map to our model
        final authData = AuthResponse.fromJson(dataToParse);

        await _api.tokenService.saveSession(authData);
        return authData.role;
      }
    } catch (e) {
      debugPrint('❌ LOGIN ERROR: ${e.toString()}');
    }

    return null;
  }
}