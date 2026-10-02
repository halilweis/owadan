import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'models/working_hours_item.dart';
import 'professional_repository.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({required this.repository, super.key});

  final ProfessionalRepository repository;

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  static const _defaultStart = '09:00';
  static const _defaultEnd = '18:00';

  bool _loading = true;
  bool _saving = false;
  String? _error;

  late List<_DaySchedule> _days;

  @override
  void initState() {
    super.initState();
    _days = List.generate(
      7,
      (index) => _DaySchedule(
        dayOfWeek: index + 1,
        enabled: false,
        startTime: _defaultStart,
        endTime: _defaultEnd,
      ),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.repository.fetchWorkingHours();

      if (!mounted) {
        return;
      }

      final byDay = <int, WorkingHoursItem>{
        for (final item in items) item.dayOfWeek: item,
      };

      setState(() {
        _days = List.generate(7, (index) {
          final day = index + 1;
          final item = byDay[day];

          return _DaySchedule(
            dayOfWeek: day,
            enabled: item != null,
            startTime: item?.startTime ?? _defaultStart,
            endTime: item?.endTime ?? _defaultEnd,
          );
        });
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

  Future<void> _pickTime(int index, {required bool start}) async {
    final current = start ? _days[index].startTime : _days[index].endTime;
    final parts = current.split(':');

    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked == null || !mounted) {
      return;
    }

    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    setState(() {
      if (start) {
        _days[index].startTime = value;
      } else {
        _days[index].endTime = value;
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    for (final day in _days.where((item) => item.enabled)) {
      if (day.startTime.compareTo(day.endTime) >= 0) {
        setState(() {
          _error = _text(
            en: 'Start time must be before end time.',
            ru: 'Время начала должно быть раньше времени окончания.',
            tk: 'Başlangyç wagty gutaryş wagtyndan öň bolmaly.',
          );
        });
        return;
      }
    }

    final items = _days
        .where((day) => day.enabled)
        .map(
          (day) => WorkingHoursItem(
            dayOfWeek: day.dayOfWeek,
            startTime: day.startTime,
            endTime: day.endTime,
          ),
        )
        .toList();

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.repository.saveWorkingHours(items);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              en: 'Working hours saved.',
              ru: 'Рабочие часы сохранены.',
              tk: 'Iş wagtlary ýatda saklandy.',
            ),
          ),
        ),
      );
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

  String _dayName(int day) {
    const en = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const ru = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    const tk = [
      'Duşenbe',
      'Sişenbe',
      'Çarşenbe',
      'Penşenbe',
      'Anna',
      'Şenbe',
      'Ýekşenbe',
    ];

    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk[day - 1],
      'ru' => ru[day - 1],
      _ => en[day - 1],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(en: 'Working hours', ru: 'Рабочие часы', tk: 'Iş wagtlary'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _text(
                    en: 'Choose the days and hours when customers can book you.',
                    ru: 'Выберите дни и время, когда клиенты могут записываться.',
                    tk: 'Müşderileriň sizi bron edip biljek günlerini we wagtlaryny saýlaň.',
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(_days.length, (index) {
                  final day = _days[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              _dayName(day.dayOfWeek),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            value: day.enabled,
                            onChanged: (value) {
                              setState(() {
                                day.enabled = value;
                                _error = null;
                              });
                            },
                          ),
                          if (day.enabled)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickTime(index, start: true),
                                    icon: const Icon(Icons.schedule),
                                    label: Text(day.startTime),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('–'),
                                ),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickTime(index, start: false),
                                    icon: const Icon(Icons.schedule),
                                    label: Text(day.endTime),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
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
                      en: 'Save working hours',
                      ru: 'Сохранить рабочие часы',
                      tk: 'Iş wagtlaryny ýatda sakla',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DaySchedule {
  _DaySchedule({
    required this.dayOfWeek,
    required this.enabled,
    required this.startTime,
    required this.endTime,
  });

  final int dayOfWeek;
  bool enabled;
  String startTime;
  String endTime;
}
