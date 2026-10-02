import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import 'models/pro_booking.dart';
import 'professional_repository.dart';
import 'working_hours_screen.dart';

class ProfessionalWorkspaceScreen extends StatefulWidget {
  const ProfessionalWorkspaceScreen({required this.repository, super.key});

  final ProfessionalRepository repository;

  @override
  State<ProfessionalWorkspaceScreen> createState() =>
      _ProfessionalWorkspaceScreenState();
}

class _ProfessionalWorkspaceScreenState
    extends State<ProfessionalWorkspaceScreen> {
  bool _loading = true;
  String? _error;
  List<ProBooking> _bookings = const [];

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
      final bookings = await widget.repository.fetchBookings();

      if (!mounted) {
        return;
      }

      setState(() {
        _bookings = bookings;
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

  Future<void> _runAction(
    ProBooking booking,
    Future<ProBooking> Function(String bookingId) action,
  ) async {
    try {
      final updated = await action(booking.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _bookings = _bookings
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _openWorkingHours() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WorkingHoursScreen(repository: widget.repository),
      ),
    );
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
    final title = _text(
      en: 'Professional workspace',
      ru: 'Кабинет специалиста',
      tk: 'Hünärmen paneli',
    );

    final empty = _text(
      en: 'No bookings yet.',
      ru: 'Записей пока нет.',
      tk: 'Häzirlikçe ýazgy ýok.',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: _text(
              en: 'Working hours',
              ru: 'Рабочие часы',
              tk: 'Iş wagtlary',
            ),
            onPressed: _openWorkingHours,
            icon: const Icon(Icons.schedule_outlined),
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
                  const SizedBox(height: 120),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _load,
                    child: Text(context.l10n.t('tryAgain')),
                  ),
                ],
              )
            : _bookings.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 160),
                  const Icon(Icons.event_busy_outlined, size: 58),
                  const SizedBox(height: 12),
                  Text(empty, textAlign: TextAlign.center),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                itemCount: _bookings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final booking = _bookings[index];

                  return _BookingCard(
                    booking: booking,
                    onConfirm: booking.isPending
                        ? () => _runAction(booking, widget.repository.confirm)
                        : null,
                    onDecline: booking.isPending
                        ? () => _runAction(booking, widget.repository.decline)
                        : null,
                    onCancel: booking.isPending || booking.isConfirmed
                        ? () => _runAction(booking, widget.repository.cancel)
                        : null,
                    onComplete: booking.isConfirmed
                        ? () => _runAction(booking, widget.repository.complete)
                        : null,
                    onNoShow: booking.isConfirmed
                        ? () => _runAction(booking, widget.repository.noShow)
                        : null,
                  );
                },
              ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    this.onConfirm,
    this.onDecline,
    this.onCancel,
    this.onComplete,
    this.onNoShow,
  });

  final ProBooking booking;
  final VoidCallback? onConfirm;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final VoidCallback? onNoShow;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final start = booking.startsAt.toLocal();
    final end = booking.endsAt.toLocal();

    String text(String en, String ru, String tk) => switch (language) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Chip(label: Text(context.l10n.status(booking.status))),
              ],
            ),
            const SizedBox(height: 8),
            Text('${_date(start)} • ${_time(start)}–${_time(end)}'),
            const SizedBox(height: 6),
            Text(
              booking.price == null
                  ? context.l10n.t('priceOnRequest')
                  : '${booking.price!.toStringAsFixed(2)} ${booking.currency}',
            ),
            if (booking.note != null && booking.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(booking.note!),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onConfirm != null)
                  FilledButton(
                    onPressed: onConfirm,
                    child: Text(text('Confirm', 'Подтвердить', 'Tassykla')),
                  ),
                if (onDecline != null)
                  OutlinedButton(
                    onPressed: onDecline,
                    child: Text(text('Decline', 'Отклонить', 'Ret et')),
                  ),
                if (onComplete != null)
                  FilledButton.tonal(
                    onPressed: onComplete,
                    child: Text(text('Complete', 'Завершить', 'Tamamla')),
                  ),
                if (onNoShow != null)
                  OutlinedButton(
                    onPressed: onNoShow,
                    child: Text(text('No-show', 'Неявка', 'Gelmedi')),
                  ),
                if (onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    child: Text(text('Cancel', 'Отменить', 'Ýatyr')),
                  ),
              ],
            ),
          ],
        ),
      ),
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
