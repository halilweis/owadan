import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../discovery/models/professional_service.dart';
import '../discovery/models/professional_summary.dart';
import 'booking_repository.dart';
import 'models/availability_slot.dart';
import 'models/booking_model.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    required this.repository,
    required this.professional,
    required this.services,
    super.key,
  });

  final BookingRepository repository;
  final ProfessionalSummary professional;
  final List<ProfessionalService> services;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  ProfessionalService? _selectedService;
  late DateTime _selectedDate;

  List<AvailabilitySlot> _slots = const [];
  AvailabilitySlot? _selectedSlot;

  bool _loadingSlots = false;
  bool _submitting = false;
  String? _error;

  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);

    if (widget.services.isNotEmpty) {
      _selectedService = widget.services.first;
      _loadSlots();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<DateTime> get _dates {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);

    return List.generate(14, (index) => start.add(Duration(days: index)));
  }

  Future<void> _loadSlots() async {
    final service = _selectedService;
    if (service == null) return;

    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
      _error = null;
    });

    try {
      final slots = await widget.repository.fetchAvailability(
        professionalId: widget.professional.id,
        service: service,
        date: _selectedDate,
      );

      if (!mounted) return;

      setState(() {
        _slots = slots;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _slots = const [];
        _error = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSlots = false;
        });
      }
    }
  }

  Future<void> _book() async {
    final service = _selectedService;
    final slot = _selectedSlot;

    if (service == null || slot == null || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final booking = await widget.repository.createBooking(
        service: service,
        slot: slot,
        note: _noteController.text,
      );

      if (!mounted) return;

      await _showSuccess(booking);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
      });

      if (error.code == 'TIME_NOT_AVAILABLE' ||
          error.code == 'TIME_BLOCKED' ||
          error.code == 'OUTSIDE_WORKING_HOURS') {
        await _loadSlots();
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _showSuccess(BookingModel booking) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 48),
          title: const Text('Booking requested'),
          content: Text(
            '${booking.serviceName}\n'
            '${_formatFullDate(booking.startsAt)}\n'
            'Status: ${booking.status}',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = _selectedService;

    return Scaffold(
      appBar: AppBar(title: const Text('Book appointment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Text(
            widget.professional.displayName,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 24),
          Text(
            'Choose service',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...widget.services.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ServiceChoice(
                service: item,
                selected: item.id == service?.id,
                onTap: () {
                  setState(() {
                    _selectedService = item;
                  });
                  _loadSlots();
                },
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Choose date',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final date = _dates[index];

                return _DateChoice(
                  date: date,
                  selected: _isSameDay(date, _selectedDate),
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    _loadSlots();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Choose time',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_loadingSlots)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_slots.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(Icons.event_busy_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('No available time slots for this date.'),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _slots.map((slot) {
                final selected = slot.startsAtIso == _selectedSlot?.startsAtIso;

                return ChoiceChip(
                  selected: selected,
                  label: Text(_formatTime(slot.startsAt)),
                  onSelected: (_) {
                    setState(() {
                      _selectedSlot = slot;
                    });
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 26),
          TextField(
            controller: _noteController,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Anything the professional should know?',
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          onPressed:
              _selectedService == null || _selectedSlot == null || _submitting
              ? null
              : _book,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm booking'),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatFullDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ServiceChoice extends StatelessWidget {
  const _ServiceChoice({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final ProfessionalService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? scheme.primary : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('${service.durationMinutes} min'),
                  ],
                ),
              ),
              Text(
                '${service.price.toStringAsFixed(2)} ${service.currency}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChoice extends StatelessWidget {
  const _DateChoice({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _weekday(date.weekday),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${date.day}',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekday(int weekday) {
    const values = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return values[weekday - 1];
  }
}
