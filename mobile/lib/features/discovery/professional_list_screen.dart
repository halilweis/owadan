import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import '../booking/booking_repository.dart';
import 'discovery_repository.dart';
import 'models/category_model.dart';
import 'models/professional_summary.dart';
import 'professional_detail_screen.dart';
import 'widgets/professional_card.dart';

class ProfessionalListScreen extends StatefulWidget {
  const ProfessionalListScreen({
    required this.repository,
    required this.bookingRepository,
    this.category,
    super.key,
  });

  final DiscoveryRepository repository;
  final BookingRepository bookingRepository;
  final CategoryModel? category;

  @override
  State<ProfessionalListScreen> createState() => _ProfessionalListScreenState();
}

class _ProfessionalListScreenState extends State<ProfessionalListScreen> {
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  List<ProfessionalSummary> _professionals = const [];
  List<CategoryModel> _categories = const [];

  String? _selectedCategorySlug;
  String? _selectedSubcategorySlug;
  String _sort = 'rating';
  double? _minRating;
  DateTime? _availableDate;

  int _page = 1;
  int _pages = 1;

  @override
  void initState() {
    super.initState();
    _selectedCategorySlug = widget.category?.slug;
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.repository.fetchCategories(),
        _fetchPage(1),
      ]);

      if (!mounted) return;

      final page = results[1] as ProfessionalsPage;

      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _professionals = page.items;
        _page = page.page;
        _pages = page.pages;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<ProfessionalsPage> _fetchPage(int page) {
    final minPrice = double.tryParse(_minPriceController.text.trim());
    final maxPrice = double.tryParse(_maxPriceController.text.trim());

    return widget.repository.fetchProfessionals(
      query: _searchController.text.trim(),
      categorySlug: _selectedCategorySlug,
      subcategorySlug: _selectedSubcategorySlug,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: _minRating,
      availableDate: _availableDate,
      sort: _sort,
      page: page,
      size: 20,
    );
  }

  Future<void> _applyFilters() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _fetchPage(1);

      if (!mounted) return;

      setState(() {
        _professionals = result.items;
        _page = result.page;
        _pages = result.pages;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _pages) return;

    setState(() => _loadingMore = true);

    try {
      final result = await _fetchPage(_page + 1);

      if (!mounted) return;

      setState(() {
        _professionals = [..._professionals, ...result.items];
        _page = result.page;
        _pages = result.pages;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedCategorySlug = widget.category?.slug;
      _selectedSubcategorySlug = null;
      _sort = 'rating';
      _minRating = null;
      _availableDate = null;
    });

    _applyFilters();
  }

  CategoryModel? get _selectedCategory {
    final slug = _selectedCategorySlug;
    if (slug == null) return null;

    for (final category in _categories) {
      if (category.slug == slug) return category;
    }

    return widget.category;
  }

  String _dateValue(DateTime value) {
    return '${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickAvailabilityDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _availableDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _availableDate = picked;
    });
  }

  Future<void> _showFilters() async {
    final l10n = context.l10n;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final category = _selectedCategory;
            final subcategories = category?.subcategories ?? const [];

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  20 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text(en: 'Filters', ru: 'Фильтры', tk: 'Süzgüçler'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedCategorySlug,
                        decoration: InputDecoration(
                          labelText: _text(
                            en: 'Category',
                            ru: 'Категория',
                            tk: 'Kategoriýa',
                          ),
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              _text(
                                en: 'All categories',
                                ru: 'Все категории',
                                tk: 'Ähli kategoriýalar',
                              ),
                            ),
                          ),
                          ..._categories.map(
                            (item) => DropdownMenuItem<String?>(
                              value: item.slug,
                              child: Text(
                                item.displayName(locale: l10n.languageCode),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            _selectedCategorySlug = value;
                            _selectedSubcategorySlug = null;
                          });
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      if (subcategories.isNotEmpty)
                        DropdownButtonFormField<String?>(
                          initialValue: _selectedSubcategorySlug,
                          decoration: InputDecoration(
                            labelText: _text(
                              en: 'Subcategory',
                              ru: 'Подкатегория',
                              tk: 'Aşaky kategoriýa',
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                _text(
                                  en: 'All services',
                                  ru: 'Все услуги',
                                  tk: 'Ähli hyzmatlar',
                                ),
                              ),
                            ),
                            ...subcategories.map(
                              (item) => DropdownMenuItem<String?>(
                                value: item.slug,
                                child: Text(
                                  item.displayName(locale: l10n.languageCode),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setModalState(() {
                              _selectedSubcategorySlug = value;
                            });
                            setState(() {});
                          },
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: _text(
                                  en: 'Min price',
                                  ru: 'Цена от',
                                  tk: 'Min baha',
                                ),
                                suffixText: 'TMT',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _maxPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: _text(
                                  en: 'Max price',
                                  ru: 'Цена до',
                                  tk: 'Maks baha',
                                ),
                                suffixText: 'TMT',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<double?>(
                        initialValue: _minRating,
                        decoration: InputDecoration(
                          labelText: _text(
                            en: 'Minimum rating',
                            ru: 'Минимальный рейтинг',
                            tk: 'Iň pes reýting',
                          ),
                        ),
                        items: [
                          DropdownMenuItem<double?>(
                            value: null,
                            child: Text(
                              _text(
                                en: 'Any rating',
                                ru: 'Любой рейтинг',
                                tk: 'Islendik reýting',
                              ),
                            ),
                          ),
                          const DropdownMenuItem<double?>(
                            value: 4.5,
                            child: Text('4.5+'),
                          ),
                          const DropdownMenuItem<double?>(
                            value: 4.0,
                            child: Text('4.0+'),
                          ),
                          const DropdownMenuItem<double?>(
                            value: 3.0,
                            child: Text('3.0+'),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            _minRating = value;
                          });
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _pickAvailabilityDate();
                          setModalState(() {});
                        },
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(
                          _availableDate == null
                              ? _text(
                                  en: 'Available on date',
                                  ru: 'Доступен на дату',
                                  tk: 'Sene boýunça boş',
                                )
                              : _dateValue(_availableDate!),
                        ),
                      ),
                      if (_availableDate != null)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _availableDate = null;
                            });
                            setState(() {});
                          },
                          child: Text(
                            _text(
                              en: 'Clear date',
                              ru: 'Очистить дату',
                              tk: 'Senäni aýyr',
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _sort,
                        decoration: InputDecoration(
                          labelText: _text(
                            en: 'Sort by',
                            ru: 'Сортировать',
                            tk: 'Tertiple',
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'rating',
                            child: Text(
                              _text(
                                en: 'Best rating',
                                ru: 'Лучший рейтинг',
                                tk: 'Iň gowy reýting',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'price_asc',
                            child: Text(
                              _text(
                                en: 'Lowest price',
                                ru: 'Сначала дешевле',
                                tk: 'Arzan bahadan',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'price_desc',
                            child: Text(
                              _text(
                                en: 'Highest price',
                                ru: 'Сначала дороже',
                                tk: 'Gymmat bahadan',
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'name',
                            child: Text(
                              _text(
                                en: 'Name',
                                ru: 'По имени',
                                tk: 'Ady boýunça',
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => _sort = value);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _resetFilters();
                              },
                              child: Text(
                                _text(
                                  en: 'Reset',
                                  ru: 'Сбросить',
                                  tk: 'Arassala',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _applyFilters();
                              },
                              child: Text(
                                _text(
                                  en: 'Show results',
                                  ru: 'Показать',
                                  tk: 'Netijeleri görkez',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _text({required String en, required String ru, required String tk}) {
    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedSubcategorySlug != null) count++;
    if (_minPriceController.text.trim().isNotEmpty) count++;
    if (_maxPriceController.text.trim().isNotEmpty) count++;
    if (_minRating != null) count++;
    if (_availableDate != null) count++;
    if (_sort != 'rating') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title =
        widget.category?.displayName(locale: l10n.languageCode) ??
        l10n.t('explore');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Badge(
            isLabelVisible: _activeFilterCount > 0,
            label: Text('$_activeFilterCount'),
            child: IconButton(
              tooltip: _text(en: 'Filters', ru: 'Фильтры', tk: 'Süzgüçler'),
              onPressed: _showFilters,
              icon: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _applyFilters, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;

    if (_loading) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.cloud_off_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _applyFilters,
            child: Text(l10n.t('tryAgain')),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _applyFilters(),
          decoration: InputDecoration(
            hintText: _text(
              en: 'Search professionals or services',
              ru: 'Поиск специалистов или услуг',
              tk: 'Hünärmen ýa-da hyzmat gözle',
            ),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      _applyFilters();
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (_selectedCategorySlug != null ||
            _selectedSubcategorySlug != null ||
            _availableDate != null ||
            _minRating != null)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedCategory != null)
                Chip(
                  label: Text(
                    _selectedCategory!.displayName(locale: l10n.languageCode),
                  ),
                ),
              if (_selectedSubcategorySlug != null)
                Chip(label: Text(_selectedSubcategorySlug!)),
              if (_availableDate != null)
                Chip(label: Text(_dateValue(_availableDate!))),
              if (_minRating != null)
                Chip(label: Text('${_minRating!.toStringAsFixed(1)}+ ★')),
            ],
          ),
        if (_selectedCategorySlug != null ||
            _selectedSubcategorySlug != null ||
            _availableDate != null ||
            _minRating != null)
          const SizedBox(height: 12),
        if (_professionals.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.search_off_outlined, size: 52),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('noProfessionalsFound'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _resetFilters,
                    child: Text(
                      _text(
                        en: 'Clear filters',
                        ru: 'Очистить фильтры',
                        tk: 'Süzgüçleri arassala',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ..._professionals.map(
            (professional) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ProfessionalCard(
                professional: professional,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfessionalDetailScreen(
                        repository: widget.repository,
                        bookingRepository: widget.bookingRepository,
                        professionalId: professional.id,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_page < _pages)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OutlinedButton(
                onPressed: _loadingMore ? null : _loadMore,
                child: _loadingMore
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _text(
                          en: 'Load more',
                          ru: 'Показать ещё',
                          tk: 'Ýene görkez',
                        ),
                      ),
              ),
            ),
        ],
      ],
    );
  }
}
