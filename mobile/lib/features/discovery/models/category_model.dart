class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.slug,
    required this.nameI18n,
    required this.sortOrder,
    required this.subcategories,
  });

  final int id;
  final String slug;
  final Map<String, String> nameI18n;
  final int sortOrder;
  final List<CategoryModel> subcategories;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final names = <String, String>{};
    final rawNames = json['nameI18n'];
    if (rawNames is Map<String, dynamic>) {
      for (final entry in rawNames.entries) {
        names[entry.key] = entry.value?.toString() ?? '';
      }
    }

    final children = <CategoryModel>[];
    final rawChildren = json['subcategories'];
    if (rawChildren is List) {
      for (final item in rawChildren) {
        if (item is Map<String, dynamic>) {
          children.add(CategoryModel.fromJson(item));
        }
      }
    }

    return CategoryModel(
      id: json['id'] as int,
      slug: json['slug']?.toString() ?? '',
      nameI18n: names,
      sortOrder: json['sortOrder'] as int? ?? 0,
      subcategories: children,
    );
  }

  String displayName({String locale = 'en'}) {
    return nameI18n[locale] ??
        nameI18n['en'] ??
        nameI18n['tk'] ??
        nameI18n['ru'] ??
        slug;
  }
}
