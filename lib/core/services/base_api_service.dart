import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sales_management/core/utils/ui_feedback_service.dart';
import 'package:sales_management/core/network/api_constants.dart';
import 'package:sales_management/core/utils/file_logger.dart';
import '../interceptor/auth_interceptor.dart';
import '../services/auth/token_service.dart';

class BaseApiService {
  final Dio _dio;
  final UiFeedbackService _uiFeedbackService;
  final TokenService tokenService;

  BaseApiService(this._dio, this._uiFeedbackService, this.tokenService) {
    // _dio.options.baseUrl = 'http://194.163.157.143:8090';
    _dio.options.baseUrl = 'http://194.163.157.143:8080';
    _dio.options.connectTimeout = const Duration(seconds: 10);

    _dio.options.receiveTimeout = const Duration(seconds: 20);
    _dio.options.sendTimeout = const Duration(seconds: 20);

    _dio.interceptors.add(AuthInterceptor(tokenService, _uiFeedbackService));
  }

  Future<T?> request<T>(
      EndpointConfig config, {
        dynamic body,
        VanguardeRequestOptions? options,
      }) async {
    final reqOptions = options ?? VanguardeRequestOptions();
    final shouldShowLoader = reqOptions.showLoader;

    if (shouldShowLoader) {
      _uiFeedbackService.showLoader();
    }

    String finalUrl = config.url;
    if (reqOptions.pathParams != null) {
      reqOptions.pathParams!.forEach((key, value) {
        finalUrl = finalUrl.replaceAll('{$key}', value.toString());
      });
    }

    // ---------------------------------------------------------
    // --- CUSTOM LOGGING: REQUEST START ---
    // ---------------------------------------------------------
    final fullUrl = '${_dio.options.baseUrl}$finalUrl';
    FileLogger().i("API REQ: ${config.method} $fullUrl");
    
    debugPrint('\n🔵 [API REQUEST] ----------------------------------');
    debugPrint('➡️ ENDPOINT : ${config.method} $fullUrl');
    if (body != null) {
      debugPrint('📦 PAYLOAD  : $body');
    }
    debugPrint('---------------------------------------------------\n');

    try {
      // Execute Request
      final response = await _dio.request(
        finalUrl,
        data: body,
        options: Options(method: config.method),
      );
      
      FileLogger().i("API RES: ${config.method} $fullUrl [${response.statusCode}]");

      // Handle Success Toast
      if (reqOptions.successMessage != null) {
        _uiFeedbackService.showSuccess(reqOptions.successMessage!);
      }

      // Handle both wrapped and unwrapped backend payloads safely
      final responseData = response.data;

      if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
        return responseData['data'] as T;
      }

      return responseData as T;

    } on DioException catch (e) {
      // Handle Error
      String errorMsg = 'An unexpected error occurred.';
      if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
        if (e.response?.data['message'] != null) {
          errorMsg = e.response?.data['message'];
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMsg = 'Connection timed out.';
      }

      // ---------------------------------------------------------
      // --- CUSTOM LOGGING: REQUEST ERROR ---
      // ---------------------------------------------------------
      FileLogger().e("API ERR: ${config.method} $fullUrl | Status: ${e.response?.statusCode} | Msg: $errorMsg");

      debugPrint('\n🔴 [API ERROR] ------------------------------------');
      debugPrint('🚨 ENDPOINT : ${config.method} $fullUrl');
      debugPrint(' PAYLOAD : $body ');
      debugPrint('⚠️ STATUS   : ${e.response?.statusCode ?? 'No Status Code'}');
      debugPrint('❌ MESSAGE  : $errorMsg');
      debugPrint('🛑 RAW ERROR: ${e.message}');
      debugPrint('---------------------------------------------------\n');

      // ── 2. PREVENT CRASHES IN BACKGROUND ISOLATE ──
      // Only show error UI if we aren't running silently in the background
      if (shouldShowLoader) {
        _uiFeedbackService.showError(errorMsg);
      }

      rethrow;

    } finally {
      // Hide loader ALWAYS
      if (shouldShowLoader) {
        _uiFeedbackService.hideLoader();
      }
    }
  }
}