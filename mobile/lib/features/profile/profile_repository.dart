import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import 'models/account_user.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AccountUser> fetchMe() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/me',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid account response.');
      }

      final user = data['user'];
      if (user is! Map<String, dynamic>) {
        throw StateError('Invalid account response.');
      }

      return AccountUser.fromJson(user);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
