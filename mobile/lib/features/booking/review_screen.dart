import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'booking_repository.dart';
import 'models/booking_model.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    required this.booking,
    required this.bookingRepository,
    super.key,
  });

  final BookingModel booking;
  final BookingRepository bookingRepository;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final TextEditingController _commentController = TextEditingController();

  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _rating < 1 || _rating > 5) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await widget.bookingRepository.submitReview(
        bookingId: widget.booking.id,
        rating: _rating,
        comment: _commentController.text,
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
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;

    final title = switch (language) {
      'tk' => 'Hyzmata baha beriň',
      'ru' => 'Оцените услугу',
      _ => 'Rate your appointment',
    };

    final subtitle = switch (language) {
      'tk' => 'Tejribäňizi beýleki müşderiler bilen paýlaşyň.',
      'ru' => 'Поделитесь своим опытом с другими клиентами.',
      _ => 'Share your experience with other customers.',
    };

    final commentLabel = switch (language) {
      'tk' => 'Teswir (hökmany däl)',
      'ru' => 'Комментарий (необязательно)',
      _ => 'Comment (optional)',
    };

    final commentHint = switch (language) {
      'tk' => 'Hyzmat barada näme pikir edýärsiňiz?',
      'ru' => 'Что вы думаете об услуге?',
      _ => 'What did you think about the service?',
    };

    final submitLabel = switch (language) {
      'tk' => 'Teswiri iber',
      'ru' => 'Отправить отзыв',
      _ => 'Submit review',
    };

    final chooseRating = switch (language) {
      'tk' => '1-den 5-e çenli baha saýlaň.',
      'ru' => 'Выберите оценку от 1 до 5.',
      _ => 'Choose a rating from 1 to 5.',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.booking.serviceName,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(subtitle),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = value <= _rating;

              return IconButton(
                tooltip: '$value',
                onPressed: _submitting
                    ? null
                    : () {
                        setState(() {
                          _rating = value;
                          _error = null;
                        });
                      },
                iconSize: 42,
                icon: Icon(selected ? Icons.star : Icons.star_border),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            _rating == 0 ? chooseRating : '$_rating / 5',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _commentController,
            enabled: !_submitting,
            minLines: 4,
            maxLines: 7,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: commentLabel,
              hintText: commentHint,
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
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _rating == 0 || _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.star_outline),
            label: Text(submitLabel),
          ),
        ],
      ),
    );
  }
}
