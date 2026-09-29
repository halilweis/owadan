import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../auth/auth_repository.dart';
import '../discovery/discovery_repository.dart';
import '../discovery/models/category_model.dart';
import '../discovery/models/professional_summary.dart';
import '../discovery/professional_list_screen.dart';
import '../discovery/widgets/category_chip_card.dart';
import '../discovery/widgets/professional_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.authRepository,
    required this.discoveryRepository,
    required this.onSignedOut,
    super.key,
  });

  final AuthRepository authRepository;
  final DiscoveryRepository discoveryRepository;
  final VoidCallback onSignedOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
  List<CategoryModel> _categories = const [];
  List<ProfessionalSummary> _professionals = const [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHome();
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

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _professionals = professionalsPage.items;
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

  Future<void> _logout() async {
    await widget.authRepository.logout();
    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHome(),
          ProfessionalListScreen(repository: widget.discoveryRepository),
          const _ComingSoonPage(
            title: 'Bookings',
            icon: Icons.calendar_month_outlined,
          ),
          const _ComingSoonPage(
            title: 'Favorites',
            icon: Icons.favorite_border,
          ),
          _ProfilePage(onLogout: _logout),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadHome,
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
                  tooltip: 'Notifications',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifications screen is next.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Find your next beauty appointment',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Discover verified professionals and book the service that fits you.',
            ),
            const SizedBox(height: 20),
            SearchBar(
              hintText: 'Search professionals',
              leading: const Icon(Icons.search),
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            const SizedBox(height: 28),
            _sectionHeader(
              title: 'Categories',
              actionText: 'See all',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfessionalListScreen(
                      repository: widget.discoveryRepository,
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
              const _EmptyCard(
                icon: Icons.category_outlined,
                message: 'No categories available yet.',
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
              title: 'Recommended professionals',
              actionText: 'Explore',
              onAction: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            const SizedBox(height: 14),
            if (!_loading && _professionals.isEmpty && _error == null)
              const _EmptyCard(
                icon: Icons.people_outline,
                message: 'No professionals available yet.',
              )
            else
              ..._professionals.map(
                (professional) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProfessionalCard(
                    professional: professional,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${professional.displayName}: professional detail is next.',
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
            TextButton(onPressed: onRetry, child: const Text('Try again')),
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

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Coming in the next mobile step.'),
          ],
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
