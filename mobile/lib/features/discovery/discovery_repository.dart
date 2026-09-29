import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import 'models/category_model.dart';
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
        page: meta['page'] as int? ?? page,
        size: meta['size'] as int? ?? size,
        total: meta['total'] as int? ?? items.length,
        pages: meta['pages'] as int? ?? 1,
      );
    } on DioException catch (error) {
      throw ApiClient.mapError(error);
    }
  }
}
