import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../auth/auth_repository.dart';
import 'models/account_user.dart';
import 'profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.profileRepository,
    required this.authRepository,
    required this.onSignedOut,
    super.key,
  });

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;
  final VoidCallback onSignedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  AccountUser? _user;

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
      final user = await widget.profileRepository.fetchMe();

      if (!mounted) return;

      setState(() {
        _user = user;
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
    if (_busy) return;

    setState(() {
      _busy = true;
    });

    await widget.authRepository.logout();

    if (!mounted) return;
    widget.onSignedOut();
  }

  Future<void> _logoutAll() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out from all devices?'),
        content: const Text(
          'This will revoke all active sessions for your Owadan account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out all'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
    });

    try {
      await widget.authRepository.logoutAll();

      if (!mounted) return;
      widget.onSignedOut();
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));

      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: const [
          _Header(),
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const _Header(),
          const SizedBox(height: 120),
          Icon(
            Icons.cloud_off_outlined,
            size: 54,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Try again')),
        ],
      );
    }

    final user = _user;
    if (user == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: const [
          _Header(),
          SizedBox(height: 140),
          Center(child: Text('Account information unavailable.')),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const _Header(),
        const SizedBox(height: 24),
        _AccountCard(user: user),
        const SizedBox(height: 24),
        Text(
          'Account',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _SettingTile(
          icon: Icons.phone_outlined,
          title: 'Phone number',
          subtitle: user.phoneNumber,
        ),
        _SettingTile(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: 'English',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Language settings will be added next.'),
              ),
            );
          },
        ),
        _SettingTile(
          icon: Icons.security_outlined,
          title: 'Account type',
          subtitle: _accountType(user),
        ),
        const SizedBox(height: 24),
        Text(
          'Session',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _busy ? null : _logoutAll,
          icon: const Icon(Icons.logout_outlined),
          label: const Text('Sign out from all devices'),
        ),
      ],
    );
  }

  String _accountType(AccountUser user) {
    if (user.isAdmin) return 'Administrator';
    if (user.isProfessional) return 'Customer + Professional';
    return 'Customer';
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Profile',
      style: Theme.of(context).textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final AccountUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.person_outline,
                size: 34,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.phoneNumber,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.roles
                        .map((role) => role.replaceFirst('ROLE_', ''))
                        .join(' • '),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
