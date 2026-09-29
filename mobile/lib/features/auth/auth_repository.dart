import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';

class OtpRequestResult {
  const OtpRequestResult({required this.expiresIn, this.developmentCode});

  final int expiresIn;
  final String? developmentCode;
}

class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<OtpRequestResult> requestOtp(String phoneNumber) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/auth/request-otp',
        data: {'phoneNumber': phoneNumber},
        options: Options(extra: {'skipAuth': true}),
      );

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};

      return OtpRequestResult(
        expiresIn: data['expiresIn'] as int? ?? 300,
        developmentCode: data['developmentCode']?.toString(),
      );
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/auth/verify-otp',
        data: {'phoneNumber': phoneNumber, 'code': code},
        options: Options(extra: {'skipAuth': true}),
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      final tokens = data?['tokens'] as Map<String, dynamic>?;

      final accessToken = tokens?['accessToken'] as String?;
      final refreshToken = tokens?['refreshToken'] as String?;

      if (accessToken == null || refreshToken == null) {
        throw const ApiException(
          code: 'INVALID_AUTH_RESPONSE',
          message: 'Invalid authentication response.',
        );
      }

      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _apiClient.dio.post<void>(
          '/api/v1/auth/logout',
          data: {'refreshToken': refreshToken},
          options: Options(extra: {'skipAuth': true}),
        );
      } on DioException {
        // Local logout should still succeed if the backend is unavailable.
      }
    }

    await _tokenStorage.clear();
  }
}
