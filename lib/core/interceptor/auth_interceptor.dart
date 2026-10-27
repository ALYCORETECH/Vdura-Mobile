import 'package:dio/dio.dart';
import '../services/auth/token_service.dart';
import '../utils/ui_feedback_service.dart';

class AuthInterceptor extends Interceptor {
  final TokenService _tokenService;
  final UiFeedbackService _uiFeedbackService;

  AuthInterceptor(this._tokenService, this._uiFeedbackService);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Get the token from secure storage
    final token = await _tokenService.getToken();

    // 2. If it exists, append the Bearer header
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Continue the request
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 3. Handle globally expired tokens or unauthorized access
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      _tokenService.clearSession();
      _uiFeedbackService.showError('Session expired. Please log in again.');

      // TODO: Trigger navigation to Login Screen here using your Router
    }

    return super.onError(err, handler);
  }
}