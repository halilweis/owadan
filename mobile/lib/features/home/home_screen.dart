import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import '../auth/auth_repository.dart';
import '../booking/booking_repository.dart';
import '../booking/bookings_screen.dart';
import '../discovery/discovery_repository.dart';
import '../discovery/models/category_model.dart';
import '../discovery/models/professional_summary.dart';
import '../discovery/professional_detail_screen.dart';
import '../discovery/professional_list_screen.dart';
import '../discovery/widgets/category_chip_card.dart';
import '../discovery/widgets/professional_card.dart';
import '../favorites/favorites_screen.dart';
import '../notifications/notification_repository.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_repository.dart';
import '../profile/profile_screen.dart';
import '../professional/professional_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.authRepository,
    required this.discoveryRepository,
    required this.bookingRepository,
    required this.profileRepository,
    required this.notificationRepository,
    required this.professionalRepository,
    required this.onSignedOut,
    required this.onLanguageChanged,
    super.key,
  });

  final AuthRepository authRepository;
  final DiscoveryRepository discoveryRepository;
  final BookingRepository bookingRepository;
  final ProfileRepository profileRepository;
  final NotificationRepository notificationRepository;
  final ProfessionalRepository professionalRepository;
  final VoidCallback onSignedOut;
  final ValueChanged<String> onLanguageChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
  List<CategoryModel> _categories = const [];
  List<ProfessionalSummary> _professionals = const [];
  int _selectedIndex = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadHome();
    _loadUnreadCount();
  }

  Future<void> _loadHome() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categoriesFuture = widget.discoveryRepository.fetchCategories();
      final professionalsFuture = widget.discoveryRepository.fetchProfessionals(
        size: 6,
      );

      final categories = await categoriesFuture;
      final professionalsPage = await professionalsFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _professionals = professionalsPage.items;
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

  Future<void> _loadUnreadCount() async {
    try {
      final count = await widget.notificationRepository.fetchUnreadCount();

      if (!mounted) {
        return;
      }

      setState(() {
        _unreadNotifications = count;
      });
    } on ApiException {
      // Notification count is non-critical for the home screen.
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsScreen(
          repository: widget.notificationRepository,
          onUnreadCountChanged: (count) {
            if (mounted) {
              setState(() {
                _unreadNotifications = count;
              });
            }
          },
          onOpenBookings: () {
            if (mounted) {
              setState(() {
                _selectedIndex = 2;
              });
            }
          },
        ),
      ),
    );

    await _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: switch (_selectedIndex) {
        0 => _buildHome(),
        1 => ProfessionalListScreen(
          repository: widget.discoveryRepository,
          bookingRepository: widget.bookingRepository,
        ),
        2 => BookingsScreen(
          bookingRepository: widget.bookingRepository,
          discoveryRepository: widget.discoveryRepository,
        ),
        3 => FavoritesScreen(
          discoveryRepository: widget.discoveryRepository,
          bookingRepository: widget.bookingRepository,
        ),
        _ => ProfileScreen(
          profileRepository: widget.profileRepository,
          authRepository: widget.authRepository,
          professionalRepository: widget.professionalRepository,
          onSignedOut: widget.onSignedOut,
          onLanguageChanged: widget.onLanguageChanged,
        ),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.t('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: l10n.t('explore'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.t('bookings'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: l10n.t('favorites'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: l10n.t('profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final l10n = context.l10n;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadHome(), _loadUnreadCount()]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Owadan',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: l10n.t('notifications'),
                  onPressed: _openNotifications,
                  icon: Badge(
                    isLabelVisible: _unreadNotifications > 0,
                    label: Text(
                      _unreadNotifications > 99
                          ? '99+'
                          : '$_unreadNotifications',
                    ),
                    child: const Icon(Icons.notifications_none),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.t('findBeauty'),
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(l10n.t('discoverVerified')),
            const SizedBox(height: 20),
            SearchBar(
              hintText: l10n.t('searchProfessionals'),
              leading: const Icon(Icons.search),
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            const SizedBox(height: 28),
            _sectionHeader(
              title: l10n.t('categories'),
              actionText: l10n.t('seeAll'),
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfessionalListScreen(
                      repository: widget.discoveryRepository,
                      bookingRepository: widget.bookingRepository,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            if (_loading)
              const SizedBox(
                height: 130,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _loadHome)
            else if (_categories.isEmpty)
              _EmptyCard(
                icon: Icons.category_outlined,
                message: l10n.t('noCategories'),
              )
            else
              SizedBox(
                height: 134,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final category = _categories[index];

                    return CategoryChipCard(
                      category: category,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProfessionalListScreen(
                              repository: widget.discoveryRepository,
                              bookingRepository: widget.bookingRepository,
                              category: category,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 30),
            _sectionHeader(
              title: l10n.t('recommendedProfessionals'),
              actionText: l10n.t('explore'),
              onAction: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            const SizedBox(height: 14),
            if (!_loading && _professionals.isEmpty && _error == null)
              _EmptyCard(
                icon: Icons.people_outline,
                message: l10n.t('noProfessionals'),
              )
            else
              ..._professionals.map(
                (professional) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProfessionalCard(
                    professional: professional,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProfessionalDetailScreen(
                            repository: widget.discoveryRepository,
                            bookingRepository: widget.bookingRepository,
                            professionalId: professional.id,
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

  Widget _sectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionText)),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.t('tryAgain')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
