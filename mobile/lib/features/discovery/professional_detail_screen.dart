import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'discovery_repository.dart';
import 'models/professional_review.dart';
import 'models/professional_service.dart';
import 'models/professional_summary.dart';

class ProfessionalDetailScreen extends StatefulWidget {
  const ProfessionalDetailScreen({
    required this.repository,
    required this.professionalId,
    super.key,
  });

  final DiscoveryRepository repository;
  final String professionalId;

  @override
  State<ProfessionalDetailScreen> createState() => _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState extends State<ProfessionalDetailScreen> {
  bool _loading = true;
  bool _favoriteBusy = false;
  String? _error;
  ProfessionalSummary? _professional;
  List<ProfessionalService> _services = const [];
  List<ProfessionalReview> _reviews = const [];
  bool _isFavorite = false;

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
      final bundle = await widget.repository.fetchProfessionalDetailBundle(
        widget.professionalId,
      );

      if (!mounted) return;

      setState(() {
        _professional = bundle.professional;
        _services = bundle.services;
        _reviews = bundle.reviews;
        _isFavorite = bundle.isFavorite;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
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

  Future<void> _toggleFavorite() async {
    if (_favoriteBusy) return;

    setState(() {
      _favoriteBusy = true;
    });

    try {
      if (_isFavorite) {
        await widget.repository.removeFavorite(widget.professionalId);
      } else {
        await widget.repository.addFavorite(widget.professionalId);
      }

      if (!mounted) return;
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _favoriteBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional'),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Remove favorite' : 'Add favorite',
            onPressed: _loading || _favoriteBusy ? null : _toggleFavorite,
            icon: _favoriteBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _body(),
      ),
      bottomNavigationBar: _professional == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                onPressed: _services.isEmpty
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Availability selection is the next step.',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text('Book appointment'),
              ),
            ),
    );
  }

  Widget _body() {
    if (_loading) {
      return ListView(
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.cloud_off_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _load,
            child: const Text('Try again'),
          ),
        ],
      );
    }

    final professional = _professional;
    if (professional == null) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: Text('Professional not found.')),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        _ProfileHeader(professional: professional),
        const SizedBox(height: 24),
        if (professional.bio != null && professional.bio!.trim().isNotEmpty) ...[
          const _SectionTitle('About'),
          const SizedBox(height: 8),
          Text(professional.bio!),
          const SizedBox(height: 24),
        ],
        if (professional.experienceYears != null ||
            professional.languages.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (professional.experienceYears != null)
                Chip(
                  avatar: const Icon(Icons.workspace_premium_outlined, size: 18),
                  label: Text(
                    '${professional.experienceYears} years experience',
                  ),
                ),
              ...professional.languages.map(
                (language) => Chip(
                  avatar: const Icon(Icons.language, size: 18),
                  label: Text(language),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        const _SectionTitle('Services'),
        const SizedBox(height: 12),
        if (_services.isEmpty)
          const _EmptyCard(
            icon: Icons.design_services_outlined,
            text: 'No active services yet.',
          )
        else
          ..._services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ServiceCard(service: service),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: _SectionTitle('Reviews')),
            Text(
              '${professional.reviewCount}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_reviews.isEmpty)
          const _EmptyCard(
            icon: Icons.rate_review_outlined,
            text: 'No reviews yet.',
          )
        else
          ..._reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(review: review),
            ),
          ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.professional});

  final ProfessionalSummary professional;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                _initials(professional.displayName),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          professional.displayName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (professional.verificationStatus == 'APPROVED')
                        Icon(Icons.verified, color: scheme.primary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        professional.averageRating == null
                            ? 'New'
                            : professional.averageRating!.toStringAsFixed(1),
                      ),
                      const SizedBox(width: 6),
                      Text('(${professional.reviewCount})'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    professional.minPrice == null
                        ? 'Price on request'
                        : 'From ${professional.minPrice!.toStringAsFixed(2)} ${professional.currency}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final result = parts.take(2).map((e) => e[0].toUpperCase()).join();
    return result.isEmpty ? '?' : result;
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final ProfessionalService service;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    service.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  '${service.price.toStringAsFixed(2)} ${service.currency}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Text('${service.durationMinutes} min'),
                const SizedBox(width: 12),
                Text(service.priceType),
              ],
            ),
            if (service.description != null && service.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(service.description!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ProfessionalReview review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  size: 20,
                ),
              ),
            ),
            if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!),
            ],
            if (review.createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatDate(review.createdAt!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
