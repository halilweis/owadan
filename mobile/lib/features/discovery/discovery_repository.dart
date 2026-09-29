import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import 'models/category_model.dart';
import 'models/professional_review.dart';
import 'models/professional_service.dart';
import 'models/professional_summary.dart';

class ProfessionalsPage {
  const ProfessionalsPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.pages,
  });

  final List<ProfessionalSummary> items;
  final int page;
  final int size;
  final int total;
  final int pages;
}

class ProfessionalDetailBundle {
  const ProfessionalDetailBundle({
    required this.professional,
    required this.services,
    required this.reviews,
    required this.isFavorite,
  });

  final ProfessionalSummary professional;
  final List<ProfessionalService> services;
  final List<ProfessionalReview> reviews;
  final bool isFavorite;
}

class DiscoveryRepository {
  DiscoveryRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/categories',
      );
      final raw = response.data?['data'];
      if (raw is! List) return const [];
      return raw.whereType<Map<String, dynamic>>().map(CategoryModel.fromJson).toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<ProfessionalsPage> fetchProfessionals({
    String? categorySlug,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final query = <String, dynamic>{'page': page, 'size': size};
      if (categorySlug != null && categorySlug.isNotEmpty) {
        query['category'] = categorySlug;
      }

      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/professionals',
        queryParameters: query,
      );

      final body = response.data ?? const <String, dynamic>{};
      final rawItems = body['data'];
      final rawMeta = body['meta'];

      final items = rawItems is List
          ? rawItems.whereType<Map<String, dynamic>>().map(ProfessionalSummary.fromJson).toList()
          : <ProfessionalSummary>[];

      final meta = rawMeta is Map<String, dynamic>
          ? rawMeta
          : const <String, dynamic>{};

      return ProfessionalsPage(
        items: items,
        page: meta['page'] as int? ?? page,
        size: meta['size'] as int? ?? size,
        total: meta['total'] as int? ?? items.length,
        pages: meta['pages'] as int? ?? 1,
      );
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<ProfessionalSummary> fetchProfessional(String id) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/professionals/$id',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        throw StateError('Invalid professional response.');
      }
      return ProfessionalSummary.fromJson(data);
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<ProfessionalService>> fetchProfessionalServices(String id) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/professionals/$id/services',
      );
      final data = response.data?['data'];
      if (data is! List) return const [];
      return data.whereType<Map<String, dynamic>>().map(ProfessionalService.fromJson).toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<ProfessionalReview>> fetchProfessionalReviews(String id) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/professionals/$id/reviews',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return const [];
      final reviews = data['reviews'];
      if (reviews is! List) return const [];
      return reviews.whereType<Map<String, dynamic>>().map(ProfessionalReview.fromJson).toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<bool> isFavorite(String professionalId) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/me/favorites',
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return false;
      final favorites = data['favorites'];
      if (favorites is! List) return false;
      return favorites.whereType<Map<String, dynamic>>().any(
        (favorite) => favorite['professionalId']?.toString() == professionalId,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) return false;
      throw ApiClient.mapError(error);
    }
  }

  Future<void> addFavorite(String professionalId) async {
    try {
      await _apiClient.dio.post<void>('/api/v1/me/favorites/$professionalId');
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<void> removeFavorite(String professionalId) async {
    try {
      await _apiClient.dio.delete<void>('/api/v1/me/favorites/$professionalId');
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<ProfessionalDetailBundle> fetchProfessionalDetailBundle(String id) async {
    final professional = await fetchProfessional(id);
    final services = await fetchProfessionalServices(id);
    final reviews = await fetchProfessionalReviews(id);
    final favorite = await isFavorite(id);

    return ProfessionalDetailBundle(
      professional: professional,
      services: services,
      reviews: reviews,
      isFavorite: favorite,
    );
  }
}
