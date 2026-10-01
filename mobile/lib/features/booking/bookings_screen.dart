import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import '../discovery/discovery_repository.dart';
import '../discovery/models/professional_summary.dart';
import 'booking_detail_screen.dart';
import 'booking_repository.dart';
import 'models/booking_model.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({
    required this.bookingRepository,
    required this.discoveryRepository,
    super.key,
  });
  final BookingRepository bookingRepository;
  final DiscoveryRepository discoveryRepository;
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool _loading = true;
  String? _error;
  List<BookingModel> _bookings = const [];
  int _segment = 0;
  final Map<String, ProfessionalSummary> _professionals = {};

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
      final bookings = await widget.bookingRepository.fetchMyBookings();
      if (!mounted) return;
      setState(() => _bookings = bookings);
      for (final id in bookings.map((e) => e.professionalId).toSet()) {
        if (_professionals.containsKey(id)) continue;
        try {
          final professional = await widget.discoveryRepository
              .fetchProfessional(id);
          if (!mounted) return;
          setState(() => _professionals[id] = professional);
        } catch (_) {}
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<BookingModel> get _upcoming {
    final now = DateTime.now();
    final items = _bookings.where((booking) {
      final active =
          booking.status == 'PENDING' || booking.status == 'CONFIRMED';
      return active && booking.endsAt.toLocal().isAfter(now);
    }).toList();
    items.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return items;
  }

  List<BookingModel> get _history {
    final upcomingIds = _upcoming.map((e) => e.id).toSet();
    final items = _bookings.where((e) => !upcomingIds.contains(e.id)).toList();
    items.sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = _segment == 0 ? _upcoming : _history;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text(
              l10n.t('bookings'),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(l10n.t('upcoming'))),
                ButtonSegment(value: 1, label: Text(l10n.t('history'))),
              ],
              selected: {_segment},
              onSelectionChanged: (value) =>
                  setState(() => _segment = value.first),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _Message(
                icon: Icons.cloud_off_outlined,
                text: _error!,
                action: TextButton(
                  onPressed: _load,
                  child: Text(l10n.t('tryAgain')),
                ),
              )
            else if (current.isEmpty)
              _Message(
                icon: _segment == 0
                    ? Icons.event_available_outlined
                    : Icons.history,
                text: _segment == 0
                    ? l10n.t('noUpcomingBookings')
                    : l10n.t('noBookingHistory'),
              )
            else
              ...current.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        await Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => BookingDetailScreen(
                              booking: booking,
                              bookingRepository: widget.bookingRepository,
                              discoveryRepository: widget.discoveryRepository,
                            ),
                          ),
                        );
                        if (mounted) await _load();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    booking.serviceName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _professionals[booking.professionalId]
                                            ?.displayName ??
                                        l10n.t('professional'),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_date(booking.startsAt.toLocal())} • ${_time(booking.startsAt.toLocal())}',
                                  ),
                                  const SizedBox(height: 8),
                                  Text(l10n.status(booking.status)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 100),
    child: Column(
      children: [
        Icon(icon, size: 56),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}
