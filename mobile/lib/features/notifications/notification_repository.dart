import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import 'models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/me/notifications',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return const [];
      }

      final raw = data['notifications'];
      if (raw is! List) {
        return const [];
      }

      return raw
          .whereType<Map>()
          .map(
            (item) => AppNotification.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/me/notifications/unread-count',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return 0;
      }

      final value = data['unreadCount'];
      if (value is int) {
        return value;
      }

      return int.tryParse(value?.toString() ?? '') ?? 0;
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _apiClient.dio.post<void>('/api/v1/me/notifications/$id/read');
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<int> markAllRead() async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/me/notifications/read-all',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return 0;
      }

      final value = data['updated'];
      if (value is int) {
        return value;
      }

      return int.tryParse(value?.toString() ?? '') ?? 0;
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
