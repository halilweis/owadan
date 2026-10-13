import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'availability_exceptions_screen.dart';
import 'models/pro_booking.dart';
import 'models/pro_dashboard.dart';
import 'portfolio_management_screen.dart';
import 'professional_profile_screen.dart';
import 'professional_repository.dart';
import 'service_management_screen.dart';
import 'working_hours_screen.dart';
import 'professional_calendar_screen.dart';

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({required this.repository, super.key});

  final ProfessionalRepository repository;

  @override
  State<ProfessionalDashboardScreen> createState() =>
      _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState
    extends State<ProfessionalDashboardScreen> {
  bool _loading = true;
  String? _error;
  ProDashboard? _dashboard;
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
      final results = await Future.wait([
        widget.repository.fetchDashboard(),
        widget.repository.fetchBookings(),
      ]);

      if (!mounted) return;

      setState(() {
        _dashboard = results[0] as ProDashboard;
        _bookings = results[1] as List<ProBooking>;
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

  String _text({required String en, required String ru, required String tk}) {
    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };
  }

  List<ProBooking> get _todayBookings {
    final now = DateTime.now();

    return _bookings.where((booking) {
      final start = booking.startsAt.toLocal();
      return start.year == now.year &&
          start.month == now.month &&
          start.day == now.day &&
          (booking.isPending || booking.isConfirmed);
    }).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  List<ProBooking> get _pendingBookings {
    return _bookings.where((booking) => booking.isPending).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  String _dateTime(DateTime value) {
    final local = value.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date • $time';
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(
            en: 'Professional dashboard',
            ru: 'Панель специалиста',
            tk: 'Hünärmen paneli',
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
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 130),
                  const Icon(Icons.cloud_off_outlined, size: 58),
                  const SizedBox(height: 14),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
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
            : dashboard == null
            ? const SizedBox.shrink()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Text(
                    _text(en: 'Overview', ru: 'Обзор', tk: 'Umumy maglumat'),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.35,
                    children: [
                      _MetricCard(
                        icon: Icons.today_outlined,
                        value: '${dashboard.todayAppointments}',
                        label: _text(en: 'Today', ru: 'Сегодня', tk: 'Şu gün'),
                      ),
                      _MetricCard(
                        icon: Icons.hourglass_top_outlined,
                        value: '${dashboard.pendingBookings}',
                        label: _text(
                          en: 'Pending',
                          ru: 'Ожидают',
                          tk: 'Garaşylýar',
                        ),
                      ),
                      _MetricCard(
                        icon: Icons.task_alt_outlined,
                        value: '${dashboard.completedBookings}',
                        label: _text(
                          en: 'Completed',
                          ru: 'Завершено',
                          tk: 'Tamamlanan',
                        ),
                      ),
                      _MetricCard(
                        icon: Icons.star_outline,
                        value: dashboard.averageRating == null
                            ? '—'
                            : dashboard.averageRating!.toStringAsFixed(1),
                        label:
                            '${_text(en: 'Rating', ru: 'Рейтинг', tk: 'Reýting')} (${dashboard.reviewCount})',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _text(en: 'Revenue', ru: 'Доход', tk: 'Girdeji'),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MoneyCard(
                          label: _text(
                            en: 'This month',
                            ru: 'Этот месяц',
                            tk: 'Şu aý',
                          ),
                          value:
                              '${dashboard.monthRevenue.toStringAsFixed(2)} ${dashboard.currency}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MoneyCard(
                          label: _text(
                            en: 'All time',
                            ru: 'За всё время',
                            tk: 'Ähli döwür',
                          ),
                          value:
                              '${dashboard.totalRevenue.toStringAsFixed(2)} ${dashboard.currency}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (dashboard.nextAppointment != null) ...[
                    Text(
                      _text(
                        en: 'Next appointment',
                        ru: 'Следующая запись',
                        tk: 'Indiki ýazgy',
                      ),
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.event_available_outlined),
                        title: Text(
                          dashboard.nextAppointment!.serviceName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          _dateTime(dashboard.nextAppointment!.startsAt),
                        ),
                        trailing: Chip(
                          label: Text(dashboard.nextAppointment!.status),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    _text(
                      en: 'Quick actions',
                      ru: 'Быстрые действия',
                      tk: 'Çalt hereketler',
                    ),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _QuickAction(
                        icon: Icons.design_services_outlined,
                        label: _text(
                          en: 'Services',
                          ru: 'Услуги',
                          tk: 'Hyzmatlar',
                        ),
                        onTap: () => _open(
                          ServiceManagementScreen(
                            repository: widget.repository,
                          ),
                        ),
                      ),
                      _QuickAction(
                        icon: Icons.schedule_outlined,
                        label: _text(
                          en: 'Working hours',
                          ru: 'Рабочие часы',
                          tk: 'Iş wagtlary',
                        ),
                        onTap: () => _open(
                          WorkingHoursScreen(repository: widget.repository),
                        ),
                      ),
                      _QuickAction(
                        icon: Icons.photo_library_outlined,
                        label: _text(
                          en: 'Portfolio',
                          ru: 'Портфолио',
                          tk: 'Portfolio',
                        ),
                        onTap: () => _open(
                          PortfolioManagementScreen(
                            repository: widget.repository,
                          ),
                        ),
                      ),
                      _QuickAction(
                        icon: Icons.event_busy_outlined,
                        label: _text(
                          en: 'Availability',
                          ru: 'Доступность',
                          tk: 'Elýeterlilik',
                        ),
                        onTap: () => _open(
                          AvailabilityExceptionsScreen(
                            repository: widget.repository,
                          ),
                        ),
                      ),
                      _QuickAction(
                        icon: Icons.manage_accounts_outlined,
                        label: _text(
                          en: 'Profile',
                          ru: 'Профиль',
                          tk: 'Profil',
                        ),
                        onTap: () => _open(
                          ProfessionalProfileScreen(
                            repository: widget.repository,
                          ),
                        ),
                      ),
                      _QuickAction(
                        icon: Icons.calendar_month_outlined,
                        label: _text(
                          en: 'Calendar',
                          ru: 'Календарь',
                          tk: 'Senenama',
                        ),
                        onTap: () => _open(
                          ProfessionalCalendarScreen(
                            repository: widget.repository,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    _text(
                      en: "Today's bookings",
                      ru: 'Записи на сегодня',
                      tk: 'Şu günki ýazgylar',
                    ),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (_todayBookings.isEmpty)
                    _EmptyCard(
                      text: _text(
                        en: 'No appointments today.',
                        ru: 'Сегодня записей нет.',
                        tk: 'Şu gün ýazgy ýok.',
                      ),
                    )
                  else
                    ..._todayBookings.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BookingRow(booking: booking),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _text(
                      en: 'Pending requests',
                      ru: 'Ожидающие запросы',
                      tk: 'Garaşylýan sargytlar',
                    ),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (_pendingBookings.isEmpty)
                    _EmptyCard(
                      text: _text(
                        en: 'No pending booking requests.',
                        ru: 'Нет ожидающих запросов.',
                        tk: 'Garaşylýan sargyt ýok.',
                      ),
                    )
                  else
                    ..._pendingBookings
                        .take(5)
                        .map(
                          (booking) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _BookingRow(booking: booking),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking});

  final ProBooking booking;

  @override
  Widget build(BuildContext context) {
    final start = booking.startsAt.toLocal();
    final time =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(time)),
        title: Text(
          booking.serviceName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(booking.status),
        trailing: booking.price == null
            ? null
            : Text(
                '${booking.price!.toStringAsFixed(0)} ${booking.currency}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.inbox_outlined),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
