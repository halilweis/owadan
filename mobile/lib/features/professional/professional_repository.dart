import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import 'models/pro_booking.dart';
import 'models/working_hours_item.dart';

class ProfessionalRepository {
  ProfessionalRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ProBooking>> fetchBookings() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/bookings',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return const [];
      }

      final raw = data['bookings'];
      if (raw is! List) {
        return const [];
      }

      return raw
          .whereType<Map>()
          .map(
            (item) => ProBooking.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<WorkingHoursItem>> fetchWorkingHours() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/working-hours',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return const [];
      }

      final raw = data['items'];
      if (raw is! List) {
        return const [];
      }

      return raw
          .whereType<Map>()
          .map(
            (item) => WorkingHoursItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> saveWorkingHours(List<WorkingHoursItem> items) async {
    try {
      await _apiClient.dio.put<Map<String, dynamic>>(
        '/api/v1/pro/working-hours',
        data: {'items': items.map((item) => item.toJson()).toList()},
      );
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<ProBooking> confirm(String bookingId) =>
      _changeStatus(bookingId, 'confirm');

  Future<ProBooking> decline(String bookingId) =>
      _changeStatus(bookingId, 'decline');

  Future<ProBooking> cancel(String bookingId) =>
      _changeStatus(bookingId, 'cancel');

  Future<ProBooking> complete(String bookingId) =>
      _changeStatus(bookingId, 'complete');

  Future<ProBooking> noShow(String bookingId) =>
      _changeStatus(bookingId, 'no-show');

  Future<ProBooking> _changeStatus(String bookingId, String action) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/pro/bookings/$bookingId/$action',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid professional booking response.');
      }

      final booking = data['booking'];
      if (booking is! Map<String, dynamic>) {
        throw StateError('Invalid professional booking response.');
      }

      return ProBooking.fromJson(booking);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
