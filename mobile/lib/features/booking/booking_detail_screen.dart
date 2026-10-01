import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import '../discovery/discovery_repository.dart';
import '../discovery/models/professional_review.dart';
import '../discovery/models/professional_summary.dart';
import 'booking_repository.dart';
import 'models/booking_model.dart';
import 'review_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({
    required this.booking,
    required this.bookingRepository,
    required this.discoveryRepository,
    super.key,
  });

  final BookingModel booking;
  final BookingRepository bookingRepository;
  final DiscoveryRepository discoveryRepository;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late BookingModel _booking;
  ProfessionalSummary? _professional;
  ProfessionalReview? _existingReview;

  bool _cancelling = false;
  bool _loadingReview = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _loadProfessional();
    _loadReviewStatus();
  }

  Future<void> _loadProfessional() async {
    try {
      final professional = await widget.discoveryRepository.fetchProfessional(
        _booking.professionalId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _professional = professional;
      });
    } catch (_) {}
  }

  Future<void> _loadReviewStatus() async {
    if (_booking.status != 'COMPLETED') {
      return;
    }

    setState(() {
      _loadingReview = true;
    });

    try {
      final reviews = await widget.discoveryRepository.fetchProfessionalReviews(
        _booking.professionalId,
      );

      if (!mounted) {
        return;
      }

      ProfessionalReview? match;

      for (final review in reviews) {
        if (review.bookingId == _booking.id) {
          match = review;
          break;
        }
      }

      setState(() {
        _existingReview = match;
      });
    } catch (_) {
      // Review state is supplementary; booking details still remain usable.
    } finally {
      if (mounted) {
        setState(() {
          _loadingReview = false;
        });
      }
    }
  }

  bool get _canCancel =>
      _booking.status == 'PENDING' || _booking.status == 'CONFIRMED';

  bool get _canReview =>
      _booking.status == 'COMPLETED' &&
      !_loadingReview &&
      _existingReview == null;

  Future<void> _cancel() async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('cancelBookingQuestion')),
        content: Text(l10n.t('cancelBookingMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('keepBooking')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.t('cancelBooking')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _cancelling = true;
      _error = null;
    });

    try {
      final updated = await widget.bookingRepository.cancelBooking(_booking.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _booking = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.t('bookingCancelled'))),
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
          _cancelling = false;
        });
      }
    }
  }

  Future<void> _openReview() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReviewScreen(
          booking: _booking,
          bookingRepository: widget.bookingRepository,
        ),
      ),
    );

    if (submitted != true || !mounted) {
      return;
    }

    await _loadReviewStatus();

    if (!mounted) {
      return;
    }

    final language = Localizations.localeOf(context).languageCode;

    final message = switch (language) {
      'tk' => 'Teswiriňiz iberildi.',
      'ru' => 'Ваш отзыв отправлен.',
      _ => 'Your review was submitted.',
    };

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final start = _booking.startsAt.toLocal();
    final end = _booking.endsAt.toLocal();
    final language = Localizations.localeOf(context).languageCode;

    final leaveReviewLabel = switch (language) {
      'tk' => 'Teswir galdyr',
      'ru' => 'Оставить отзыв',
      _ => 'Leave a review',
    };

    final reviewedLabel = switch (language) {
      'tk' => 'Siz bu hyzmaty bahalandyrypsyňyz',
      'ru' => 'Вы уже оценили эту услугу',
      _ => 'You reviewed this appointment',
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('bookingDetails'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                l10n.status(_booking.status),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _booking.serviceName,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  _Row(
                    icon: Icons.person_outline,
                    text: _professional?.displayName ?? l10n.t('professional'),
                  ),
                  _Row(icon: Icons.calendar_today_outlined, text: _date(start)),
                  _Row(
                    icon: Icons.schedule_outlined,
                    text: '${_time(start)} – ${_time(end)}',
                  ),
                  _Row(
                    icon: Icons.payments_outlined,
                    text: _booking.price == null
                        ? l10n.t('priceOnRequest')
                        : '${_booking.price!.toStringAsFixed(2)} '
                              '${_booking.currency}',
                  ),
                  if (_booking.note != null && _booking.note!.trim().isNotEmpty)
                    _Row(icon: Icons.notes_outlined, text: _booking.note!),
                ],
              ),
            ),
          ),
          if (_booking.status == 'COMPLETED') ...[
            const SizedBox(height: 16),
            if (_loadingReview)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_existingReview != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reviewedLabel,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < _existingReview!.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 22,
                                ),
                              ),
                            ),
                            if (_existingReview!.comment != null &&
                                _existingReview!.comment!
                                    .trim()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(_existingReview!.comment!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              FilledButton.icon(
                onPressed: _canReview ? _openReview : null,
                icon: const Icon(Icons.star_outline),
                label: Text(leaveReviewLabel),
              ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_canCancel) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _cancelling ? null : _cancel,
              icon: _cancelling
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(l10n.t('cancelBooking')),
            ),
          ],
        ],
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

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
