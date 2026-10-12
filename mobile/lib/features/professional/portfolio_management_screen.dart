import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_exception.dart';
import 'models/portfolio_item.dart';
import 'models/pro_service.dart';
import 'professional_repository.dart';

class PortfolioManagementScreen extends StatefulWidget {
  const PortfolioManagementScreen({required this.repository, super.key});

  final ProfessionalRepository repository;

  @override
  State<PortfolioManagementScreen> createState() =>
      _PortfolioManagementScreenState();
}

class _PortfolioManagementScreenState extends State<PortfolioManagementScreen> {
  bool _loading = true;
  String? _error;
  List<PortfolioItemModel> _items = const [];
  List<ProService> _services = const [];

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
        widget.repository.fetchPortfolio(),
        widget.repository.fetchServices(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _items = results[0] as List<PortfolioItemModel>;
        _services = results[1] as List<ProService>;
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

  Future<void> _openEditor([PortfolioItemModel? item]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PortfolioItemEditorScreen(
          repository: widget.repository,
          services: _services,
          item: item,
        ),
      ),
    );

    if (changed == true) {
      await _load();
    }
  }

  Future<void> _delete(PortfolioItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _text(
            en: 'Delete portfolio item?',
            ru: 'Удалить работу?',
            tk: 'Portfolio işini aýyrmalymy?',
          ),
        ),
        content: Text(
          _text(
            en: 'This work example will no longer appear on your profile.',
            ru: 'Эта работа больше не будет отображаться в профиле.',
            tk: 'Bu iş mysaly indi profiliňizde görkezilmez.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_text(en: 'Cancel', ru: 'Отмена', tk: 'Ýatyr')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_text(en: 'Delete', ru: 'Удалить', tk: 'Aýyr')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.repository.deletePortfolioItem(item.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _items = _items.where((value) => value.id != item.id).toList();
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  String _text({required String en, required String ru, required String tk}) {
    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };
  }

  String _resolvedImageUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return '${ApiConfig.baseUrl}$value';
    }

    return '${ApiConfig.baseUrl}/$value';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_text(en: 'Portfolio', ru: 'Портфолио', tk: 'Portfolio')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(_text(en: 'Add work', ru: 'Добавить работу', tk: 'Iş goş')),
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

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 150),
          const Icon(Icons.photo_library_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            _text(
              en: 'Your portfolio is empty. Add photos of your work so customers can see your style.',
              ru: 'Портфолио пока пусто. Добавьте фотографии работ, чтобы клиенты увидели ваш стиль.',
              tk: 'Portfolioňyz entek boş. Müşderiler stiliňizi görer ýaly işleriňiziň suratlaryny goşuň.',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openEditor(item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _resolvedImageUrl(item.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(Icons.broken_image_outlined, size: 44),
                        ),
                      ),
                      if (item.featured)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 16),
                                  SizedBox(width: 4),
                                  Text('Featured'),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title?.trim().isNotEmpty == true
                                  ? item.title!
                                  : _text(
                                      en: 'Untitled work',
                                      ru: 'Без названия',
                                      tk: 'Atsyz iş',
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.serviceName != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                item.serviceName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 3),
                            Text(
                              item.active
                                  ? _text(
                                      en: 'Visible',
                                      ru: 'Видно',
                                      tk: 'Görünýär',
                                    )
                                  : _text(
                                      en: 'Hidden',
                                      ru: 'Скрыто',
                                      tk: 'Gizlenen',
                                    ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _text(en: 'Delete', ru: 'Удалить', tk: 'Aýyr'),
                        onPressed: () => _delete(item),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PortfolioItemEditorScreen extends StatefulWidget {
  const PortfolioItemEditorScreen({
    required this.repository,
    required this.services,
    this.item,
    super.key,
  });

  final ProfessionalRepository repository;
  final List<ProService> services;
  final PortfolioItemModel? item;

  @override
  State<PortfolioItemEditorScreen> createState() =>
      _PortfolioItemEditorScreenState();
}

class _PortfolioItemEditorScreenState extends State<PortfolioItemEditorScreen> {
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  XFile? _pickedImage;
  Uint8List? _pickedBytes;
  String? _serviceId;
  late bool _featured;
  late bool _active;

  bool _saving = false;
  String? _error;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _serviceId = item?.serviceId;
    _featured = item?.featured ?? false;
    _active = item?.active ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
    );

    if (image == null || !mounted) {
      return;
    }

    final bytes = await image.readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      _pickedImage = image;
      _pickedBytes = bytes;
      _error = null;
    });
  }

  Future<void> _showImageSource() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                _text(
                  en: 'Choose from gallery',
                  ru: 'Выбрать из галереи',
                  tk: 'Galereýadan saýla',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _chooseImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(
                _text(
                  en: 'Take a photo',
                  ru: 'Сделать фото',
                  tk: 'Surata düşür',
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _chooseImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    if (!_editing && _pickedImage == null) {
      setState(() {
        _error = _text(
          en: 'Choose a photo first.',
          ru: 'Сначала выберите фотографию.',
          tk: 'Ilki surat saýlaň.',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      var imageUrl = widget.item?.imageUrl;

      if (_pickedImage != null) {
        imageUrl = await widget.repository.uploadPortfolioPhoto(
          _pickedImage!.path,
        );
      }

      if (imageUrl == null || imageUrl.isEmpty) {
        throw StateError('Portfolio image is missing.');
      }

      if (_editing) {
        await widget.repository.updatePortfolioItem(
          id: widget.item!.id,
          imageUrl: imageUrl,
          title: _titleController.text,
          description: _descriptionController.text,
          serviceId: _serviceId,
          featured: _featured,
          active: _active,
        );
      } else {
        await widget.repository.createPortfolioItem(
          imageUrl: imageUrl,
          title: _titleController.text,
          description: _descriptionController.text,
          serviceId: _serviceId,
          featured: _featured,
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
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = _text(
          en: 'Unable to save the portfolio item.',
          ru: 'Не удалось сохранить работу.',
          tk: 'Portfolio işini ýatda saklap bolmady.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _text({required String en, required String ru, required String tk}) {
    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };
  }

  String _resolvedImageUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return '${ApiConfig.baseUrl}$value';
    }

    return '${ApiConfig.baseUrl}/$value';
  }

  @override
  Widget build(BuildContext context) {
    final existingImageUrl = widget.item?.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing
              ? _text(
                  en: 'Edit portfolio work',
                  ru: 'Редактировать работу',
                  tk: 'Portfolio işini üýtget',
                )
              : _text(
                  en: 'Add portfolio work',
                  ru: 'Добавить работу',
                  tk: 'Portfolio işi goş',
                ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _saving ? null : _showImageSource,
                child: _pickedBytes != null
                    ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                    : existingImageUrl != null
                    ? Image.network(
                        _resolvedImageUrl(existingImageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _saving ? null : _showImageSource,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              _editing
                  ? _text(
                      en: 'Replace photo',
                      ru: 'Заменить фото',
                      tk: 'Suraty çalyş',
                    )
                  : _text(
                      en: 'Choose photo',
                      ru: 'Выбрать фото',
                      tk: 'Surat saýla',
                    ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            enabled: !_saving,
            maxLength: 160,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: _text(
                en: 'Title (optional)',
                ru: 'Название (необязательно)',
                tk: 'Ady (hökmany däl)',
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
          DropdownButtonFormField<String?>(
            initialValue: _serviceId,
            decoration: InputDecoration(
              labelText: _text(
                en: 'Related service',
                ru: 'Связанная услуга',
                tk: 'Baglanyşykly hyzmat',
              ),
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  _text(en: 'No service', ru: 'Без услуги', tk: 'Hyzmatsyz'),
                ),
              ),
              ...widget.services.map(
                (service) => DropdownMenuItem<String?>(
                  value: service.id,
                  child: Text(service.name),
                ),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    setState(() {
                      _serviceId = value;
                    });
                  },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _text(
                en: 'Featured work',
                ru: 'Избранная работа',
                tk: 'Saýlanan iş',
              ),
            ),
            subtitle: Text(
              _text(
                en: 'Highlight this work in your portfolio.',
                ru: 'Выделить эту работу в портфолио.',
                tk: 'Bu işi portfolioňyzda aýratyn görkez.',
              ),
            ),
            value: _featured,
            onChanged: _saving
                ? null
                : (value) {
                    setState(() {
                      _featured = value;
                    });
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _text(
                en: 'Visible to customers',
                ru: 'Показывать клиентам',
                tk: 'Müşderilere görkez',
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
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _text(
                en: 'Save work',
                ru: 'Сохранить работу',
                tk: 'Işi ýatda sakla',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_photo_alternate_outlined, size: 56),
          const SizedBox(height: 8),
          Text(
            _text(
              en: 'Tap to choose a photo',
              ru: 'Нажмите, чтобы выбрать фото',
              tk: 'Surat saýlamak üçin basyň',
            ),
          ),
        ],
      ),
    );
  }
}
