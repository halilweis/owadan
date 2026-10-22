import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../messaging/booking_message_screen.dart';
import 'models/pro_client.dart';
import 'professional_repository.dart';

class ProfessionalClientDetailScreen extends StatefulWidget {
  const ProfessionalClientDetailScreen({
    required this.repository,
    required this.customerId,
    super.key,
  });

  final ProfessionalRepository repository;
  final String customerId;

  @override
  State<ProfessionalClientDetailScreen> createState() =>
      _ProfessionalClientDetailScreenState();
}

class _ProfessionalClientDetailScreenState
    extends State<ProfessionalClientDetailScreen> {
  bool _loading = true;
  bool _savingNote = false;
  String? _error;
  ProClientDetail? _client;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = await widget.repository.fetchClient(widget.customerId);

      if (!mounted) return;

      _noteController.text = client.note ?? '';

      setState(() {
        _client = client;
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

  Future<void> _saveNote() async {
    if (_savingNote) return;

    setState(() {
      _savingNote = true;
      _error = null;
    });

    try {
      await widget.repository.updateClientNote(
        widget.customerId,
        _noteController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              en: 'Client note saved.',
              ru: 'Заметка о клиенте сохранена.',
              tk: 'Müşderi belligi ýatda saklandy.',
            ),
          ),
        ),
      );

      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _savingNote = false);
      }
    }
  }

  String _text({
    required String en,
    required String ru,
    required String tk,
  }) {
    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };
  }

  @override
  Widget build(BuildContext context) {
    final client = _client;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          client?.title ??
              _text(
                en: 'Client',
                ru: 'Клиент',
                tk: 'Müşderi',
              ),
        ),
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
            : _error != null && client == null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 130),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: Text(
                          _text(
                            en: 'Try again',
                            ru: 'Повторить',
                            tk: 'Gaýtadan synanyş',
                          ),
                        ),
                      ),
                    ],
                  )
                : client == null
                    ? const SizedBox.shrink()
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    client.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(client.phoneNumber),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _Metric(
                                          value:
                                              '${client.appointmentCount}',
                                          label: _text(
                                            en: 'Appointments',
                                            ru: 'Записи',
                                            tk: 'Ýazgylar',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: _Metric(
                                          value: '${client.completedCount}',
                                          label: _text(
                                            en: 'Completed',
                                            ru: 'Завершено',
                                            tk: 'Tamamlanan',
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: _Metric(
                                          value: '${client.noShowCount}',
                                          label: _text(
                                            en: 'No-shows',
                                            ru: 'Неявки',
                                            tk: 'Gelmedik',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _text(
                                      en:
                                          'Total spent: ${client.totalSpent.toStringAsFixed(2)} ${client.currency}',
                                      ru:
                                          'Всего потрачено: ${client.totalSpent.toStringAsFixed(2)} ${client.currency}',
                                      tk:
                                          'Jemi çykdajy: ${client.totalSpent.toStringAsFixed(2)} ${client.currency}',
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _text(
                              en: 'Private client note',
                              ru: 'Личная заметка о клиенте',
                              tk: 'Şahsy müşderi belligi',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _noteController,
                            minLines: 3,
                            maxLines: 6,
                            maxLength: 2000,
                            decoration: InputDecoration(
                              hintText: _text(
                                en:
                                    'Preferences, allergies, style notes, reminders...',
                                ru:
                                    'Предпочтения, аллергии, стиль, напоминания...',
                                tk:
                                    'Islegler, allergiýalar, stil bellikleri, ýatlatmalar...',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _savingNote ? null : _saveNote,
                            icon: _savingNote
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _text(
                                en: 'Save note',
                                ru: 'Сохранить заметку',
                                tk: 'Belligi ýatda sakla',
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          Text(
                            _text(
                              en: 'Appointment history',
                              ru: 'История записей',
                              tk: 'Ýazgy taryhy',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          ...client.appointments.map(
                            (appointment) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AppointmentCard(
                                appointment: appointment,
                                text: _text,
                                onMessage: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => BookingMessageScreen(
                                        bookingId: appointment.id,
                                        title: _text(
                                          en: 'Appointment messages',
                                          ru: 'Сообщения по записи',
                                          tk: 'Ýazgy habarlary',
                                        ),
                                        currentRole: 'PROFESSIONAL',
                                        fetchMessages: widget.repository
                                            .fetchBookingMessages,
                                        sendMessage: widget.repository
                                            .sendBookingMessage,
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.text,
    required this.onMessage,
  });

  final ProClientAppointment appointment;
  final String Function({
    required String en,
    required String ru,
    required String tk,
  }) text;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final start = appointment.startsAt.toLocal();

    final date =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final time =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    appointment.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Chip(label: Text(appointment.status)),
              ],
            ),
            const SizedBox(height: 4),
            Text('$date • $time'),
            if (appointment.price != null) ...[
              const SizedBox(height: 4),
              Text(
                '${appointment.price!.toStringAsFixed(2)} '
                '${appointment.currency}',
              ),
            ],
            if (appointment.note != null &&
                appointment.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(appointment.note!),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onMessage,
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(
                text(
                  en: 'Messages',
                  ru: 'Сообщения',
                  tk: 'Habarlar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
