import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../discovery/models/professional_review.dart';
import '../discovery/models/professional_service.dart';
import 'models/availability_slot.dart';
import 'models/booking_model.dart';
import '../messaging/models/booking_message.dart';

class BookingRepository {
  BookingRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AvailabilitySlot>> fetchAvailability({
    required String professionalId,
    required ProfessionalService service,
    required DateTime date,
  }) async {
    try {
      final dateText =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/professionals/$professionalId/availability',
        queryParameters: {'serviceId': service.id, 'date': dateText},
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return const [];

      final rawSlots = data['slots'];
      if (rawSlots is! List) return const [];

      return rawSlots
          .whereType<Map<String, dynamic>>()
          .map(AvailabilitySlot.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<BookingModel> createBooking({
    required ProfessionalService service,
    required AvailabilitySlot slot,
    String? note,
  }) async {
    try {
      final trimmedNote = note?.trim();

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/bookings',
        data: {
          'serviceId': service.id,
          'startsAt': slot.startsAtIso,
          if (trimmedNote != null && trimmedNote.isNotEmpty)
            'note': trimmedNote,
        },
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid booking response.');
      }

      final booking = data['booking'];
      if (booking is! Map<String, dynamic>) {
        throw StateError('Invalid booking response.');
      }

      return BookingModel.fromJson(booking);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<BookingModel>> fetchMyBookings() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/me/bookings',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return const [];

      final rawBookings = data['bookings'];
      if (rawBookings is! List) return const [];

      return rawBookings
          .whereType<Map<String, dynamic>>()
          .map(BookingModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<BookingModel> cancelBooking(String bookingId) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/bookings/$bookingId/cancel',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid booking response.');
      }

      final booking = data['booking'];
      if (booking is! Map<String, dynamic>) {
        throw StateError('Invalid booking response.');
      }

      return BookingModel.fromJson(booking);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<ProfessionalReview> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    try {
      final trimmedComment = comment?.trim();

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/bookings/$bookingId/review',
        data: {
          'rating': rating,
          if (trimmedComment != null && trimmedComment.isNotEmpty)
            'comment': trimmedComment,
        },
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid review response.');
      }

      final review = data['review'];
      if (review is! Map<String, dynamic>) {
        throw StateError('Invalid review response.');
      }

      return ProfessionalReview.fromJson(review);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<BookingMessage>> fetchBookingMessages(String bookingId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/bookings/$bookingId/messages',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return const [];

      final raw = data['messages'];
      if (raw is! List) return const [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map(BookingMessage.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<BookingMessage> sendBookingMessage(
    String bookingId,
    String body,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/bookings/$bookingId/messages',
        data: {'body': body.trim()},
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid booking message response.');
      }

      final raw = data['message'];
      if (raw is! Map<String, dynamic>) {
        throw StateError('Invalid booking message response.');
      }

      return BookingMessage.fromJson(raw);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
