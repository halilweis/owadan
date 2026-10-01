import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import '../booking/booking_repository.dart';
import 'discovery_repository.dart';
import 'models/category_model.dart';
import 'models/professional_summary.dart';
import 'professional_detail_screen.dart';
import 'widgets/professional_card.dart';

class ProfessionalListScreen extends StatefulWidget {
  const ProfessionalListScreen({
    required this.repository,
    required this.bookingRepository,
    this.category,
    super.key,
  });
  final DiscoveryRepository repository;
  final BookingRepository bookingRepository;
  final CategoryModel? category;
  @override
  State<ProfessionalListScreen> createState() => _ProfessionalListScreenState();
}

class _ProfessionalListScreenState extends State<ProfessionalListScreen> {
  bool _loading = true;
  String? _error;
  List<ProfessionalSummary> _professionals = const [];
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
      final result = await widget.repository.fetchProfessionals(
        categorySlug: widget.category?.slug,
      );
      if (!mounted) return;
      setState(() => _professionals = result.items);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title =
        widget.category?.displayName(locale: l10n.languageCode) ??
        l10n.t('explore');
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_loading) {
      return ListView(
        children: const [
          SizedBox(height: 220),
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
          FilledButton(onPressed: _load, child: Text(l10n.t('tryAgain'))),
        ],
      );
    }
    if (_professionals.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.search_off_outlined, size: 52),
          const SizedBox(height: 16),
          Text(l10n.t('noProfessionalsFound'), textAlign: TextAlign.center),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _professionals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = _professionals[index];
        return ProfessionalCard(
          professional: p,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProfessionalDetailScreen(
                  repository: widget.repository,
                  bookingRepository: widget.bookingRepository,
                  professionalId: p.id,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
