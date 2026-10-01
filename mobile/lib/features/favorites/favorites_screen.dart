import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import '../booking/booking_repository.dart';
import '../discovery/discovery_repository.dart';
import '../discovery/models/professional_summary.dart';
import '../discovery/professional_detail_screen.dart';
import '../discovery/widgets/professional_card.dart';
import 'models/favorite_item.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    required this.discoveryRepository,
    required this.bookingRepository,
    super.key,
  });
  final DiscoveryRepository discoveryRepository;
  final BookingRepository bookingRepository;
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = true;
  String? _error;
  List<FavoriteItem> _favorites = const [];
  final Map<String, ProfessionalSummary> _professionals = {};
  final Set<String> _removing = {};
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
      final favorites = await widget.discoveryRepository.fetchFavorites();
      if (!mounted) return;
      setState(() => _favorites = favorites);
      await _loadProfessionals(favorites);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadProfessionals(List<FavoriteItem> favorites) async {
    for (final favorite in favorites) {
      if (_professionals.containsKey(favorite.professionalId)) continue;
      try {
        final p = await widget.discoveryRepository.fetchProfessional(
          favorite.professionalId,
        );
        if (!mounted) return;
        setState(() => _professionals[favorite.professionalId] = p);
      } catch (_) {}
    }
  }

  Future<void> _removeFavorite(FavoriteItem favorite) async {
    if (_removing.contains(favorite.professionalId)) return;
    setState(() => _removing.add(favorite.professionalId));
    try {
      await widget.discoveryRepository.removeFavorite(favorite.professionalId);
      if (!mounted) return;
      setState(() {
        _favorites = _favorites
            .where((e) => e.professionalId != favorite.professionalId)
            .toList();
        _professionals.remove(favorite.professionalId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.replace('removedFromFavorites', {
              'name': favorite.displayName,
            }),
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _removing.remove(favorite.professionalId));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
  );
  Widget _buildBody() {
    final l10n = context.l10n;
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _title(),
          const SizedBox(height: 220),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _title(),
          const SizedBox(height: 120),
          Icon(
            Icons.cloud_off_outlined,
            size: 54,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: Text(l10n.t('tryAgain'))),
        ],
      );
    }
    if (_favorites.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _title(),
          const SizedBox(height: 140),
          const Icon(Icons.favorite_border, size: 60),
          const SizedBox(height: 16),
          Text(
            l10n.t('noFavoritesYet'),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(l10n.t('favoritesHint'), textAlign: TextAlign.center),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      itemCount: _favorites.length + 1,
      separatorBuilder: (_, index) =>
          index == 0 ? const SizedBox(height: 20) : const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) return _title();
        final favorite = _favorites[index - 1];
        final professional = _professionals[favorite.professionalId];
        if (professional == null) {
          return _FallbackFavoriteCard(
            favorite: favorite,
            removing: _removing.contains(favorite.professionalId),
            onRemove: () => _removeFavorite(favorite),
          );
        }
        return Stack(
          children: [
            ProfessionalCard(
              professional: professional,
              onTap: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfessionalDetailScreen(
                      repository: widget.discoveryRepository,
                      bookingRepository: widget.bookingRepository,
                      professionalId: professional.id,
                    ),
                  ),
                );
                if (mounted) await _load();
              },
            ),
            Positioned(
              top: 6,
              right: 38,
              child: IconButton(
                tooltip: l10n.t('removeFavorite'),
                onPressed: _removing.contains(professional.id)
                    ? null
                    : () => _removeFavorite(favorite),
                icon: _removing.contains(professional.id)
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.favorite,
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _title() => Text(
    context.l10n.t('favorites'),
    style: Theme.of(context).textTheme.headlineMedium
        ?.copyWith(fontWeight: FontWeight.w800),
  );
}

class _FallbackFavoriteCard extends StatelessWidget {
  const _FallbackFavoriteCard({
    required this.favorite,
    required this.removing,
    required this.onRemove,
  });
  final FavoriteItem favorite;
  final bool removing;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(
              favorite.displayName.isEmpty
                  ? '?'
                  : favorite.displayName[0].toUpperCase(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              favorite.displayName,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: context.l10n.t('removeFavorite'),
            onPressed: removing ? null : onRemove,
            icon: removing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.favorite),
          ),
        ],
      ),
    ),
  );
}
