import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import 'models/pro_booking.dart';
import 'professional_repository.dart';
import '../messaging/booking_message_screen.dart';

class ProfessionalCalendarScreen extends StatefulWidget {
  const ProfessionalCalendarScreen({required this.repository, super.key});

  final ProfessionalRepository repository;

  @override
  State<ProfessionalCalendarScreen> createState() =>
      _ProfessionalCalendarScreenState();
}

class _ProfessionalCalendarScreenState
    extends State<ProfessionalCalendarScreen> {
  bool _loading = true;
  String? _error;
  List<ProBooking> _bookings = const [];
  late DateTime _selectedDate;
  String _filter = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bookings = await widget.repository.fetchBookings();
      if (!mounted) return;
      setState(() => _bookings = bookings);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _runAction(
    ProBooking booking,
    Future<ProBooking> Function(String bookingId) action,
  ) async {
    try {
      final updated = await action(booking.id);
      if (!mounted) return;

      setState(() {
        _bookings = _bookings
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
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

  bool _sameDay(DateTime a, DateTime b) {
    final x = a.toLocal();
    return x.year == b.year && x.month == b.month && x.day == b.day;
  }

  List<ProBooking> get _selectedBookings {
    final items = _bookings.where((booking) {
      if (!_sameDay(booking.startsAt, _selectedDate)) return false;

      return switch (_filter) {
        'ACTIVE' =>
          booking.status == 'PENDING' || booking.status == 'CONFIRMED',
        'COMPLETED' => booking.status == 'COMPLETED',
        _ => true,
      };
    }).toList();

    items.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return items;
  }

  int _countForDay(DateTime date) {
    return _bookings.where((booking) {
      return _sameDay(booking.startsAt, date) &&
          (booking.status == 'PENDING' || booking.status == 'CONFIRMED');
    }).length;
  }

  List<DateTime> get _visibleDates {
    final start = _selectedDate.subtract(const Duration(days: 3));
    return List.generate(
      7,
      (index) => DateTime(start.year, start.month, start.day + index),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _moveDay(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
  }

  String _weekday(DateTime date) {
    final en = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final ru = const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final tk = const ['Du', 'Si', 'Ça', 'Pe', 'An', 'Şe', 'Ýe'];

    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk[date.weekday - 1],
      'ru' => ru[date.weekday - 1],
      _ => en[date.weekday - 1],
    };
  }

  String _monthYear(DateTime date) {
    final en = const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final ru = const [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    final tk = const [
      'Ýanwar',
      'Fewral',
      'Mart',
      'Aprel',
      'Maý',
      'Iýun',
      'Iýul',
      'Awgust',
      'Sentýabr',
      'Oktýabr',
      'Noýabr',
      'Dekabr',
    ];

    final month = switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk[date.month - 1],
      'ru' => ru[date.month - 1],
      _ => en[date.month - 1],
    };

    return '$month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedBookings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(
            en: 'Booking calendar',
            ru: 'Календарь записей',
            tk: 'Ýazgy senenamasy',
          ),
        ),
        actions: [
          IconButton(
            tooltip: _text(
              en: 'Choose date',
              ru: 'Выбрать дату',
              tk: 'Sene saýla',
            ),
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 130),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _load,
                    child: Text(context.l10n.t('tryAgain')),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _moveDay(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _pickDate,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                Text(
                                  _monthYear(_selectedDate),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_weekday(_selectedDate)}, '
                                  '${_selectedDate.day}.'
                                  '${_selectedDate.month.toString().padLeft(2, '0')}.'
                                  '${_selectedDate.year}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _moveDay(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _visibleDates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final date = _visibleDates[index];
                        final isSelected = _sameDay(date, _selectedDate);
                        final count = _countForDay(date);

                        return SizedBox(
                          width: 64,
                          child: Material(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => setState(() => _selectedDate = date),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _weekday(date),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${date.day}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    if (count > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment<String>(
                        value: 'ACTIVE',
                        icon: const Icon(Icons.schedule_outlined),
                        label: Text(
                          _text(en: 'Active', ru: 'Активные', tk: 'Işjeň'),
                        ),
                      ),
                      ButtonSegment<String>(
                        value: 'COMPLETED',
                        icon: const Icon(Icons.task_alt_outlined),
                        label: Text(
                          _text(en: 'Done', ru: 'Готово', tk: 'Tamam'),
                        ),
                      ),
                      ButtonSegment<String>(
                        value: 'ALL',
                        icon: const Icon(Icons.list_alt_outlined),
                        label: Text(_text(en: 'All', ru: 'Все', tk: 'Ählisi')),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (value) {
                      setState(() => _filter = value.first);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _text(
                            en: 'Appointments',
                            ru: 'Записи',
                            tk: 'Ýazgylar',
                          ),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('${selected.length}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (selected.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Row(
                          children: [
                            const Icon(Icons.event_available_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _text(
                                  en: 'No bookings for this date.',
                                  ru: 'На эту дату записей нет.',
                                  tk: 'Bu sene üçin ýazgy ýok.',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...selected.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AgendaCard(
                          booking: booking,
                          text: _text,
                          onConfirm: booking.isPending
                              ? () => _runAction(
                                  booking,
                                  widget.repository.confirm,
                                )
                              : null,
                          onDecline: booking.isPending
                              ? () => _runAction(
                                  booking,
                                  widget.repository.decline,
                                )
                              : null,
                          onComplete: booking.isConfirmed
                              ? () => _runAction(
                                  booking,
                                  widget.repository.complete,
                                )
                              : null,
                          onNoShow: booking.isConfirmed
                              ? () => _runAction(
                                  booking,
                                  widget.repository.noShow,
                                )
                              : null,
                          onCancel: booking.isPending || booking.isConfirmed
                              ? () => _runAction(
                                  booking,
                                  widget.repository.cancel,
                                )
                              : null,
                          onMessage: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BookingMessageScreen(
                                  bookingId: booking.id,
                                  title: _text(
                                    en: 'Appointment messages',
                                    ru: 'Сообщения по записи',
                                    tk: 'Ýazgy habarlary',
                                  ),
                                  currentRole: 'PROFESSIONAL',
                                  fetchMessages:
                                      widget.repository.fetchBookingMessages,
                                  sendMessage:
                                      widget.repository.sendBookingMessage,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({
    required this.booking,
    required this.text,
    this.onConfirm,
    this.onDecline,
    this.onComplete,
    this.onNoShow,
    this.onCancel,
    this.onMessage,
  });

  final ProBooking booking;
  final String Function({
    required String en,
    required String ru,
    required String tk,
  })
  text;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;
  final VoidCallback? onComplete;
  final VoidCallback? onNoShow;
  final VoidCallback? onCancel;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final start = booking.startsAt.toLocal();
    final end = booking.endsAt.toLocal();

    String time(DateTime value) =>
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 66,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        time(start),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(time(end)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(booking.status),
                      if (booking.price != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${booking.price!.toStringAsFixed(2)} '
                          '${booking.currency}',
                        ),
                      ],
                      if (booking.note != null &&
                          booking.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          booking.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (onConfirm != null ||
                onDecline != null ||
                onComplete != null ||
                onNoShow != null ||
                onCancel != null ||
                onMessage != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onConfirm != null)
                    FilledButton(
                      onPressed: onConfirm,
                      child: Text(
                        text(en: 'Confirm', ru: 'Подтвердить', tk: 'Tassykla'),
                      ),
                    ),
                  if (onDecline != null)
                    OutlinedButton(
                      onPressed: onDecline,
                      child: Text(
                        text(en: 'Decline', ru: 'Отклонить', tk: 'Ret et'),
                      ),
                    ),
                  if (onComplete != null)
                    FilledButton.tonal(
                      onPressed: onComplete,
                      child: Text(
                        text(en: 'Complete', ru: 'Завершить', tk: 'Tamamla'),
                      ),
                    ),
                  if (onNoShow != null)
                    OutlinedButton(
                      onPressed: onNoShow,
                      child: Text(
                        text(en: 'No-show', ru: 'Неявка', tk: 'Gelmedi'),
                      ),
                    ),
                  if (onCancel != null)
                    TextButton(
                      onPressed: onCancel,
                      child: Text(
                        text(en: 'Cancel', ru: 'Отменить', tk: 'Ýatyr'),
                      ),
                    ),
                  if (onMessage != null)
                    OutlinedButton.icon(
                      onPressed: onMessage,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(
                        text(en: 'Message', ru: 'Сообщение', tk: 'Habar'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
