import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../discovery/models/category_model.dart';
import 'models/availability_exception_item.dart';
import 'models/pro_booking.dart';
import 'models/pro_profile.dart';
import 'models/portfolio_item.dart';
import 'models/pro_service.dart';
import 'models/working_hours_item.dart';
import 'models/pro_dashboard.dart';
import '../messaging/models/booking_message.dart';
import 'models/pro_client.dart';

class ProfessionalRepository {
  ProfessionalRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ProProfile?> fetchProfile() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/profile',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final raw = data['profile'];
      if (raw == null) {
        return null;
      }
      if (raw is! Map<String, dynamic>) {
        throw StateError('Invalid professional profile response.');
      }

      return ProProfile.fromJson(raw);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<ProProfile> saveProfile({
    required String displayName,
    required String? bio,
    required int? experienceYears,
    required List<String> languages,
    required int? districtId,
  }) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/api/v1/pro/profile',
        data: {
          'displayName': displayName.trim(),
          'bio': bio?.trim(),
          'experienceYears': experienceYears,
          'languages': languages,
          'districtId': districtId,
        },
      );

      return _parseProfile(response);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<ProProfile> submitVerification() async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/pro/profile/submit-verification',
      );

      return _parseProfile(response);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<ProDistrict>> fetchDistricts() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/districts',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return const [];
      }

      final raw = data['districts'];
      if (raw is! List) {
        return const [];
      }

      return raw
          .whereType<Map<String, dynamic>>()
          .map(ProDistrict.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  ProProfile _parseProfile(Response<Map<String, dynamic>> response) {
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw StateError('Invalid professional profile response.');
    }

    final raw = data['profile'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('Invalid professional profile response.');
    }

    return ProProfile.fromJson(raw);
  }

  Future<List<PortfolioItemModel>> fetchPortfolio() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/portfolio',
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
          .whereType<Map<String, dynamic>>()
          .map(PortfolioItemModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<String> uploadPortfolioPhoto(String filePath) async {
    try {
      final fileName = filePath.split(RegExp(r'[/\\]')).last;

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/pro/portfolio/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid portfolio upload response.');
      }

      final imageUrl = data['imageUrl']?.toString();
      if (imageUrl == null || imageUrl.isEmpty) {
        throw StateError('Invalid portfolio upload response.');
      }

      return imageUrl;
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<PortfolioItemModel> createPortfolioItem({
    required String imageUrl,
    String? title,
    String? description,
    String? serviceId,
    bool featured = false,
    bool active = true,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/pro/portfolio',
        data: {
          'imageUrl': imageUrl,
          'title': title?.trim(),
          'description': description?.trim(),
          'serviceId': serviceId,
          'featured': featured,
          'active': active,
        },
      );

      return _parsePortfolioItem(response);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<PortfolioItemModel> updatePortfolioItem({
    required String id,
    required String imageUrl,
    String? title,
    String? description,
    String? serviceId,
    required bool featured,
    required bool active,
  }) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/api/v1/pro/portfolio/$id',
        data: {
          'imageUrl': imageUrl,
          'title': title?.trim(),
          'description': description?.trim(),
          'serviceId': serviceId,
          'featured': featured,
          'active': active,
        },
      );

      return _parsePortfolioItem(response);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> deletePortfolioItem(String id) async {
    try {
      await _apiClient.dio.delete<void>('/api/v1/pro/portfolio/$id');
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  PortfolioItemModel _parsePortfolioItem(
    Response<Map<String, dynamic>> response,
  ) {
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw StateError('Invalid portfolio response.');
    }

    final raw = data['portfolioItem'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('Invalid portfolio response.');
    }

    return PortfolioItemModel.fromJson(raw);
  }

  Future<List<ProBooking>> fetchBookings() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/bookings',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return const [];
      final raw = data['bookings'];
      if (raw is! List) return const [];

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
      if (data is! Map<String, dynamic>) return const [];
      final raw = data['items'];
      if (raw is! List) return const [];

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

  Future<List<AvailabilityExceptionItem>> fetchAvailabilityExceptions() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/availability-exceptions',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return const [];
      final raw = data['items'];
      if (raw is! List) return const [];

      return raw
          .whereType<Map>()
          .map(
            (item) => AvailabilityExceptionItem.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<AvailabilityExceptionItem> createAvailabilityException({
    required DateTime startsAt,
    required DateTime endsAt,
    required String type,
    String? note,
  }) async {
    try {
      final trimmedNote = note?.trim();

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/pro/availability-exceptions',
        data: {
          'startsAt': startsAt.toIso8601String(),
          'endsAt': endsAt.toIso8601String(),
          'type': type,
          if (trimmedNote != null && trimmedNote.isNotEmpty)
            'note': trimmedNote,
        },
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid availability exception response.');
      }
      final raw = data['availabilityException'];
      if (raw is! Map<String, dynamic>) {
        throw StateError('Invalid availability exception response.');
      }

      return AvailabilityExceptionItem.fromJson(raw);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> deleteAvailabilityException(String id) async {
    try {
      await _apiClient.dio.delete<void>(
        '/api/v1/pro/availability-exceptions/$id',
      );
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/categories',
      );
      final raw = response.data?['data'];
      if (raw is! List) return const [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<ProService>> fetchServices() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/services',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return const [];
      final raw = data['services'];
      if (raw is! List) return const [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map(ProService.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<ProService> createService({
    required int categoryId,
    required String name,
    required int durationMinutes,
    required String priceType,
    required double? price,
    required bool active,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/v1/pro/services',
        data: _servicePayload(
          categoryId: categoryId,
          name: name,
          description: description,
          durationMinutes: durationMinutes,
          priceType: priceType,
          price: price,
          active: active,
        ),
      );

      return _parseServiceResponse(response);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<ProService> updateService({
    required String id,
    required int categoryId,
    required String name,
    required int durationMinutes,
    required String priceType,
    required double? price,
    required bool active,
    String? description,
  }) async {
    try {
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '/api/v1/pro/services/$id',
        data: _servicePayload(
          categoryId: categoryId,
          name: name,
          description: description,
          durationMinutes: durationMinutes,
          priceType: priceType,
          price: price,
          active: active,
        ),
      );

      return _parseServiceResponse(response);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Map<String, dynamic> _servicePayload({
    required int categoryId,
    required String name,
    required int durationMinutes,
    required String priceType,
    required double? price,
    required bool active,
    String? description,
  }) {
    final trimmedDescription = description?.trim();

    return {
      'categoryId': categoryId,
      'name': name.trim(),
      'durationMinutes': durationMinutes,
      'priceType': priceType,
      'price': priceType == 'ON_REQUEST' ? null : price?.toStringAsFixed(2),
      'active': active,
      if (trimmedDescription != null && trimmedDescription.isNotEmpty)
        'description': trimmedDescription,
    };
  }

  ProService _parseServiceResponse(Response<Map<String, dynamic>> response) {
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) {
      throw StateError('Invalid service response.');
    }
    final raw = data['service'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('Invalid service response.');
    }
    return ProService.fromJson(raw);
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

  Future<ProDashboard> fetchDashboard() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/dashboard',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid professional dashboard response.');
      }

      final raw = data['dashboard'];
      if (raw is! Map<String, dynamic>) {
        throw StateError('Invalid professional dashboard response.');
      }

      return ProDashboard.fromJson(raw);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<BookingMessage>> fetchBookingMessages(String bookingId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/bookings/$bookingId/messages',
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
        '/api/v1/pro/bookings/$bookingId/messages',
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

  Future<List<ProClientSummary>> fetchClients() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/clients',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return const [];

      final raw = data['clients'];
      if (raw is! List) return const [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map(ProClientSummary.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<ProClientDetail> fetchClient(String customerId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/pro/clients/$customerId',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid professional client response.');
      }

      final raw = data['client'];
      if (raw is! Map<String, dynamic>) {
        throw StateError('Invalid professional client response.');
      }

      return ProClientDetail.fromJson(raw);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> updateClientNote(
    String customerId,
    String note,
  ) async {
    try {
      await _apiClient.dio.put<Map<String, dynamic>>(
        '/api/v1/pro/clients/$customerId/note',
        data: {
          'note': note.trim().isEmpty ? null : note.trim(),
        },
      );
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
