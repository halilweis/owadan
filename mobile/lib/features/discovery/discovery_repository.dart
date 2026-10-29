import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../favorites/models/favorite_item.dart';
import 'models/category_model.dart';
import 'models/professional_review.dart';
import 'models/professional_service.dart';
import 'models/professional_summary.dart';
import 'models/professional_portfolio_item.dart';

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
    required this.portfolio,
  });

  final ProfessionalSummary professional;
  final List<ProfessionalService> services;
  final List<ProfessionalReview> reviews;
  final List<ProfessionalPortfolioItem> portfolio;
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

      return raw
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<ProfessionalsPage> fetchProfessionals({
    String? query,
    String? categorySlug,
    String? subcategorySlug,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    DateTime? availableDate,
    String sort = 'rating',
    int page = 1,
    int size = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'size': size,
        'sort': sort,
      };

      final q = query?.trim() ?? '';
      if (q.isNotEmpty) {
        params['q'] = q;
      }

      if (categorySlug != null && categorySlug.isNotEmpty) {
        params['category'] = categorySlug;
      }

      if (subcategorySlug != null && subcategorySlug.isNotEmpty) {
        params['subcategory'] = subcategorySlug;
      }

      if (minPrice != null) {
        params['minPrice'] = minPrice;
      }

      if (maxPrice != null) {
        params['maxPrice'] = maxPrice;
      }

      if (minRating != null) {
        params['minRating'] = minRating;
      }

      if (availableDate != null) {
        params['availableDate'] =
            '${availableDate.year}-'
            '${availableDate.month.toString().padLeft(2, '0')}-'
            '${availableDate.day.toString().padLeft(2, '0')}';
      }

      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/professionals',
        queryParameters: params,
      );

      final body = response.data ?? const <String, dynamic>{};
      final rawItems = body['data'];
      final rawMeta = body['meta'];

      final items = rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(ProfessionalSummary.fromJson)
                .toList()
          : <ProfessionalSummary>[];

      final meta = rawMeta is Map<String, dynamic>
          ? rawMeta
          : const <String, dynamic>{};

      return ProfessionalsPage(
        items: items,
        page: int.tryParse(meta['page']?.toString() ?? '') ?? page,
        size: int.tryParse(meta['size']?.toString() ?? '') ?? size,
        total: int.tryParse(meta['total']?.toString() ?? '') ?? items.length,
        pages: int.tryParse(meta['pages']?.toString() ?? '') ?? 1,
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

      return data
          .whereType<Map<String, dynamic>>()
          .map(ProfessionalService.fromJson)
          .toList();
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

      return reviews
          .whereType<Map<String, dynamic>>()
          .map(ProfessionalReview.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<List<FavoriteItem>> fetchFavorites() async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/me/favorites',
      );

      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) return const [];

      final favorites = data['favorites'];
      if (favorites is! List) return const [];

      return favorites
          .whereType<Map<String, dynamic>>()
          .map(FavoriteItem.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }

  Future<bool> isFavorite(String professionalId) async {
    try {
      final favorites = await fetchFavorites();
      return favorites.any(
        (favorite) => favorite.professionalId == professionalId,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) return false;
      rethrow;
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

  Future<ProfessionalDetailBundle> fetchProfessionalDetailBundle(
    String id,
  ) async {
    final professional = await fetchProfessional(id);
    final services = await fetchProfessionalServices(id);
    final reviews = await fetchProfessionalReviews(id);
    final favorite = await isFavorite(id);
    final portfolio = await fetchProfessionalPortfolio(id);

    return ProfessionalDetailBundle(
      professional: professional,
      services: services,
      reviews: reviews,
      portfolio: portfolio,
      isFavorite: favorite,
    );
  }

  Future<List<ProfessionalPortfolioItem>> fetchProfessionalPortfolio(
    String id,
  ) async {
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>(
        '/api/v1/professionals/$id/portfolio',
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
          .map(ProfessionalPortfolioItem.fromJson)
          .toList();
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
