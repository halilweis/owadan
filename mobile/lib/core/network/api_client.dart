import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] != true) {
            final token = await _tokenStorage.readAccessToken();

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;

          if (error.response?.statusCode != 401 ||
              request.extra['skipAuth'] == true ||
              request.extra['retried'] == true) {
            handler.next(error);
            return;
          }

          final refreshed = await _refreshTokens();

          if (!refreshed) {
            await _tokenStorage.clear();
            handler.next(error);
            return;
          }

          request.extra['retried'] = true;

          final token = await _tokenStorage.readAccessToken();

          if (token != null) {
            request.headers['Authorization'] = 'Bearer $token';
          }

          try {
            final response = await dio.fetch<dynamic>(request);
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;

  late final Dio dio;
  late final Dio _refreshDio;

  Future<bool> _refreshTokens() async {
    final refreshToken = await _tokenStorage.readRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      final tokens = data?['tokens'] as Map<String, dynamic>?;

      final accessToken = tokens?['accessToken'] as String?;
      final newRefreshToken = tokens?['refreshToken'] as String?;

      if (accessToken == null || newRefreshToken == null) {
        return false;
      }

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );

      return true;
    } on DioException {
      return false;
    }
  }

  static ApiException mapError(DioException error) {
    final body = error.response?.data;

    if (body is Map<String, dynamic>) {
      final errorPayload = body['error'];

      if (errorPayload is Map<String, dynamic>) {
        return ApiException(
          code: errorPayload['code']?.toString() ?? 'API_ERROR',
          message:
              errorPayload['message']?.toString() ?? 'Something went wrong.',
          statusCode: error.response?.statusCode,
        );
      }
    }

    return ApiException(
      code: 'API_ERROR',
      message: 'Unable to complete the request.',
      statusCode: error.response?.statusCode,
    );
  }
}
