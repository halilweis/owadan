import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../discovery/models/category_model.dart';
import 'models/pro_service.dart';
import 'professional_repository.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({required this.repository, super.key});

  final ProfessionalRepository repository;

  @override
  State<ServiceManagementScreen> createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  bool _loading = true;
  String? _error;
  List<ProService> _services = const [];
  List<CategoryModel> _categories = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.repository.fetchServices(),
        widget.repository.fetchCategories(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _services = results[0] as List<ProService>;
        _categories = results[1] as List<CategoryModel>;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEditor([ProService? service]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ServiceEditorScreen(
          repository: widget.repository,
          categories: _categories,
          service: service,
        ),
      ),
    );

    if (changed == true) {
      await _load();
    }
  }

  String _text({required String en, required String ru, required String tk}) {
    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };
  }

  String _priceText(ProService service) {
    if (service.priceType == 'ON_REQUEST' || service.price == null) {
      return _text(
        en: 'Price on request',
        ru: 'Цена по запросу',
        tk: 'Bahasy sorag boýunça',
      );
    }

    final prefix = service.priceType == 'FROM'
        ? _text(en: 'From ', ru: 'От ', tk: '')
        : '';

    return '$prefix${service.price!.toStringAsFixed(2)} ${service.currency}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_text(en: 'Services', ru: 'Услуги', tk: 'Hyzmatlar')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _categories.isEmpty ? null : () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(
          _text(en: 'Add service', ru: 'Добавить услугу', tk: 'Hyzmat goş'),
        ),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _load,
            child: Text(
              _text(en: 'Try again', ru: 'Повторить', tk: 'Gaýtadan synanyş'),
            ),
          ),
        ],
      );
    }

    if (_services.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 150),
          const Icon(Icons.design_services_outlined, size: 60),
          const SizedBox(height: 16),
          Text(
            _text(
              en: 'No services yet.',
              ru: 'Услуг пока нет.',
              tk: 'Häzirlikçe hyzmat ýok.',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _services.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final service = _services[index];

        return Card(
          child: ListTile(
            onTap: () => _openEditor(service),
            leading: CircleAvatar(
              child: Icon(
                service.active
                    ? Icons.design_services_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            title: Text(
              service.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${service.durationMinutes} min • ${_priceText(service)}'),
                const SizedBox(height: 4),
                Text(
                  service.active
                      ? _text(en: 'Active', ru: 'Активна', tk: 'Işjeň')
                      : _text(en: 'Inactive', ru: 'Неактивна', tk: 'Işjeň däl'),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class ServiceEditorScreen extends StatefulWidget {
  const ServiceEditorScreen({
    required this.repository,
    required this.categories,
    this.service,
    super.key,
  });

  final ProfessionalRepository repository;
  final List<CategoryModel> categories;
  final ProService? service;

  @override
  State<ServiceEditorScreen> createState() => _ServiceEditorScreenState();
}

class _ServiceEditorScreenState extends State<ServiceEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;

  late int _categoryId;
  late String _priceType;
  late bool _active;

  bool _saving = false;
  String? _error;

  bool get _editing => widget.service != null;

  List<CategoryModel> get _selectableCategories {
    final result = <CategoryModel>[];

    for (final parent in widget.categories) {
      result.add(parent);
      result.addAll(parent.subcategories);
    }

    return result;
  }

  @override
  void initState() {
    super.initState();

    final service = widget.service;
    final categories = _selectableCategories;

    _nameController = TextEditingController(text: service?.name ?? '');
    _descriptionController = TextEditingController(
      text: service?.description ?? '',
    );
    _durationController = TextEditingController(
      text: service?.durationMinutes.toString() ?? '60',
    );
    _priceController = TextEditingController(
      text: service?.price?.toStringAsFixed(2) ?? '',
    );

    _categoryId =
        service?.categoryId ??
        (categories.isNotEmpty ? categories.first.id : 0);
    _priceType = service?.priceType ?? 'FIXED';
    _active = service?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _text({required String en, required String ru, required String tk}) {
    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };
  }

  String _categoryName(CategoryModel category) {
    return category.displayName(
      locale: Localizations.localeOf(context).languageCode,
    );
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    final name = _nameController.text.trim();
    final duration = int.tryParse(_durationController.text.trim());
    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );

    if (name.isEmpty) {
      setState(() {
        _error = _text(
          en: 'Service name is required.',
          ru: 'Укажите название услуги.',
          tk: 'Hyzmatyň adyny giriziň.',
        );
      });
      return;
    }

    if (duration == null || duration < 5 || duration > 720) {
      setState(() {
        _error = _text(
          en: 'Duration must be between 5 and 720 minutes.',
          ru: 'Длительность должна быть от 5 до 720 минут.',
          tk: 'Dowamlylygy 5 bilen 720 minudyň arasynda bolmaly.',
        );
      });
      return;
    }

    if (_priceType != 'ON_REQUEST' && (price == null || price < 0)) {
      setState(() {
        _error = _text(
          en: 'Enter a valid price.',
          ru: 'Введите корректную цену.',
          tk: 'Dogry bahany giriziň.',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_editing) {
        await widget.repository.updateService(
          id: widget.service!.id,
          categoryId: _categoryId,
          name: name,
          description: _descriptionController.text,
          durationMinutes: duration,
          priceType: _priceType,
          price: _priceType == 'ON_REQUEST' ? null : price,
          active: _active,
        );
      } else {
        await widget.repository.createService(
          categoryId: _categoryId,
          name: name,
          description: _descriptionController.text,
          durationMinutes: duration,
          priceType: _priceType,
          price: _priceType == 'ON_REQUEST' ? null : price,
          active: _active,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _selectableCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing
              ? _text(
                  en: 'Edit service',
                  ru: 'Редактировать услугу',
                  tk: 'Hyzmaty üýtget',
                )
              : _text(
                  en: 'Add service',
                  ru: 'Добавить услугу',
                  tk: 'Hyzmat goş',
                ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _categoryId,
            decoration: InputDecoration(
              labelText: _text(
                en: 'Category',
                ru: 'Категория',
                tk: 'Kategoriýa',
              ),
            ),
            items: categories
                .map(
                  (category) => DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(_categoryName(category)),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _categoryId = value;
                      });
                    }
                  },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            enabled: !_saving,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: _text(
                en: 'Service name',
                ru: 'Название услуги',
                tk: 'Hyzmatyň ady',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            enabled: !_saving,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: _text(
                en: 'Description (optional)',
                ru: 'Описание (необязательно)',
                tk: 'Düşündiriş (hökmany däl)',
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _durationController,
            enabled: !_saving,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _text(
                en: 'Duration in minutes',
                ru: 'Длительность в минутах',
                tk: 'Dowamlylygy minutda',
              ),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _priceType,
            decoration: InputDecoration(
              labelText: _text(
                en: 'Price type',
                ru: 'Тип цены',
                tk: 'Baha görnüşi',
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'FIXED',
                child: Text(
                  _text(en: 'Fixed', ru: 'Фиксированная', tk: 'Kesgitlenen'),
                ),
              ),
              DropdownMenuItem(
                value: 'FROM',
                child: Text(_text(en: 'From', ru: 'От', tk: 'Başlaýan baha')),
              ),
              DropdownMenuItem(
                value: 'ON_REQUEST',
                child: Text(
                  _text(
                    en: 'On request',
                    ru: 'По запросу',
                    tk: 'Sorag boýunça',
                  ),
                ),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _priceType = value;
                      });
                    }
                  },
          ),
          if (_priceType != 'ON_REQUEST') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _text(
                  en: 'Price (TMT)',
                  ru: 'Цена (TMT)',
                  tk: 'Bahasy (TMT)',
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_text(en: 'Active', ru: 'Активна', tk: 'Işjeň')),
            subtitle: Text(
              _text(
                en: 'Customers can discover and book this service.',
                ru: 'Клиенты могут видеть и бронировать эту услугу.',
                tk: 'Müşderiler bu hyzmaty görüp we bron edip bilerler.',
              ),
            ),
            value: _active,
            onChanged: _saving
                ? null
                : (value) {
                    setState(() {
                      _active = value;
                    });
                  },
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving || categories.isEmpty ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _text(
                en: 'Save service',
                ru: 'Сохранить услугу',
                tk: 'Hyzmaty ýatda sakla',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
