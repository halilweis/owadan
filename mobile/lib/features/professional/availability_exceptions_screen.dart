import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'models/availability_exception_item.dart';
import 'professional_repository.dart';

class AvailabilityExceptionsScreen extends StatefulWidget {
  const AvailabilityExceptionsScreen({required this.repository, super.key});

  final ProfessionalRepository repository;

  @override
  State<AvailabilityExceptionsScreen> createState() =>
      _AvailabilityExceptionsScreenState();
}

class _AvailabilityExceptionsScreenState
    extends State<AvailabilityExceptionsScreen> {
  bool _loading = true;
  String? _error;
  List<AvailabilityExceptionItem> _items = const [];

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
      final items = await widget.repository.fetchAvailabilityExceptions();

      if (!mounted) {
        return;
      }

      setState(() {
        _items = items;
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

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            AvailabilityExceptionEditor(repository: widget.repository),
      ),
    );

    if (created == true) {
      await _load();
    }
  }

  Future<void> _delete(AvailabilityExceptionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _text(
            en: 'Remove exception?',
            ru: 'Удалить исключение?',
            tk: 'Kadadan çykmany aýyrmalymy?',
          ),
        ),
        content: Text(
          _text(
            en: 'This availability exception will be deleted.',
            ru: 'Это исключение доступности будет удалено.',
            tk: 'Bu elýeterlilik kadadan çykmasy öçüriler.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_text(en: 'Keep', ru: 'Оставить', tk: 'Goý')),
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
      await widget.repository.deleteAvailabilityException(item.id);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(
            en: 'Availability exceptions',
            ru: 'Исключения доступности',
            tk: 'Elýeterlilik kadadan çykmalary',
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(_text(en: 'Add', ru: 'Добавить', tk: 'Goş')),
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
          const Icon(Icons.event_available_outlined, size: 60),
          const SizedBox(height: 16),
          Text(
            _text(
              en: 'No availability exceptions yet.',
              ru: 'Исключений доступности пока нет.',
              tk: 'Häzirlikçe elýeterlilik kadadan çykmasy ýok.',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        final start = item.startsAt.toLocal();
        final end = item.endsAt.toLocal();

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                item.isBlocked
                    ? Icons.block_outlined
                    : Icons.add_circle_outline,
              ),
            ),
            title: Text(
              item.isBlocked
                  ? _text(
                      en: 'Blocked time',
                      ru: 'Недоступное время',
                      tk: 'Ýapyk wagt',
                    )
                  : _text(
                      en: 'Extra availability',
                      ru: 'Дополнительное время',
                      tk: 'Goşmaça elýeterlilik',
                    ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${_date(start)}  ${_time(start)} – ${_time(end)}'),
                if (item.note != null && item.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.note!),
                ],
              ],
            ),
            trailing: IconButton(
              tooltip: _text(en: 'Delete', ru: 'Удалить', tk: 'Aýyr'),
              onPressed: () => _delete(item),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        );
      },
    );
  }

  String _date(DateTime value) {
    return '${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String _time(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class AvailabilityExceptionEditor extends StatefulWidget {
  const AvailabilityExceptionEditor({required this.repository, super.key});

  final ProfessionalRepository repository;

  @override
  State<AvailabilityExceptionEditor> createState() =>
      _AvailabilityExceptionEditorState();
}

class _AvailabilityExceptionEditorState
    extends State<AvailabilityExceptionEditor> {
  final TextEditingController _noteController = TextEditingController();

  String _type = 'BLOCKED';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 13, minute: 0);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (value != null && mounted) {
      setState(() {
        _selectedDate = value;
      });
    }
  }

  Future<void> _pickTime({required bool start}) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );

    if (value != null && mounted) {
      setState(() {
        if (start) {
          _start = value;
        } else {
          _end = value;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    final startsAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _start.hour,
      _start.minute,
    );

    final endsAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _end.hour,
      _end.minute,
    );

    if (!startsAt.isBefore(endsAt)) {
      setState(() {
        _error = _text(
          en: 'Start time must be before end time.',
          ru: 'Время начала должно быть раньше времени окончания.',
          tk: 'Başlangyç wagty gutaryş wagtyndan öň bolmaly.',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.repository.createAvailabilityException(
        startsAt: startsAt,
        endsAt: endsAt,
        type: _type,
        note: _noteController.text,
      );

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

  String _text({required String en, required String ru, required String tk}) {
    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(
            en: 'Add exception',
            ru: 'Добавить исключение',
            tk: 'Kadadan çykma goş',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'BLOCKED',
                icon: const Icon(Icons.block_outlined),
                label: Text(
                  _text(en: 'Blocked', ru: 'Недоступно', tk: 'Ýapyk'),
                ),
              ),
              ButtonSegment(
                value: 'EXTRA',
                icon: const Icon(Icons.add_circle_outline),
                label: Text(
                  _text(en: 'Extra', ru: 'Дополнительно', tk: 'Goşmaça'),
                ),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) {
              setState(() {
                _type = value.first;
              });
            },
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(_date(_selectedDate)),
            subtitle: Text(_text(en: 'Date', ru: 'Дата', tk: 'Sene')),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(start: true),
                  icon: const Icon(Icons.schedule),
                  label: Text(_start.format(context)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('–'),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(start: false),
                  icon: const Icon(Icons.schedule),
                  label: Text(_end.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: _text(
                en: 'Note (optional)',
                ru: 'Примечание (необязательно)',
                tk: 'Bellik (hökmany däl)',
              ),
            ),
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
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_text(en: 'Save', ru: 'Сохранить', tk: 'Ýatda sakla')),
          ),
        ],
      ),
    );
  }

  String _date(DateTime value) {
    return '${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
