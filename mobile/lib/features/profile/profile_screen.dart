import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import '../auth/auth_repository.dart';
import 'edit_profile_screen.dart';
import 'models/account_user.dart';
import 'profile_repository.dart';
import '../professional/professional_repository.dart';
import '../professional/professional_workspace_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.profileRepository,
    required this.authRepository,
    required this.professionalRepository,
    required this.onSignedOut,
    required this.onLanguageChanged,
    super.key,
  });

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;
  final ProfessionalRepository professionalRepository;
  final VoidCallback onSignedOut;
  final ValueChanged<String> onLanguageChanged;

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
      setState(() => _user = user);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile() async {
    final user = _user;
    if (user == null) return;

    final updated = await Navigator.of(context).push<AccountUser>(
      MaterialPageRoute<AccountUser>(
        builder: (_) =>
            EditProfileScreen(repository: widget.profileRepository, user: user),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _user = updated);
      widget.onLanguageChanged(updated.preferredLanguage);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.t('profileUpdated'))));
    }
  }

  Future<void> _logout() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.authRepository.logout();
    if (!mounted) return;
    widget.onSignedOut();
  }

  Future<void> _logoutAll() async {
    if (_busy) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('signOutAllQuestion')),
        content: Text(l10n.t('signOutAllMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.t('signOutAll')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.authRepository.logoutAll();
      if (!mounted) return;
      widget.onSignedOut();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final l10n = context.l10n;
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _Header(text: l10n.t('profile')),
          const SizedBox(height: 220),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _Header(text: l10n.t('profile')),
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

    final user = _user;
    if (user == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _Header(text: l10n.t('profile')),
          const SizedBox(height: 140),
          Center(child: Text(l10n.t('accountUnavailable'))),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Row(
          children: [
            Expanded(child: _Header(text: l10n.t('profile'))),
            IconButton(
              tooltip: l10n.t('editProfile'),
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _AccountCard(user: user),
        const SizedBox(height: 24),
        Text(
          l10n.t('account'),
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _SettingTile(
          icon: Icons.person_outline,
          title: l10n.t('displayName'),
          subtitle: user.displayName?.trim().isNotEmpty == true
              ? user.displayName!
              : l10n.t('notSet'),
          onTap: _editProfile,
        ),
        _SettingTile(
          icon: Icons.phone_outlined,
          title: l10n.t('phoneNumber'),
          subtitle: user.phoneNumber,
        ),
        _SettingTile(
          icon: Icons.language_outlined,
          title: l10n.t('language'),
          subtitle: _languageName(user.preferredLanguage),
          onTap: _editProfile,
        ),
        _SettingTile(
          icon: Icons.security_outlined,
          title: l10n.t('accountType'),
          subtitle: _accountType(user),
        ),
        if (user.isProfessional) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProfessionalWorkspaceScreen(
                    repository: widget.professionalRepository,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.work_outline),
            label: Text(
              Localizations.localeOf(context).languageCode == 'tk'
                  ? 'Hünärmen paneli'
                  : Localizations.localeOf(context).languageCode == 'ru'
                  ? 'Кабинет специалиста'
                  : 'Professional workspace',
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          l10n.t('session'),
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _logout,
          icon: const Icon(Icons.logout),
          label: Text(l10n.t('signOut')),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _busy ? null : _logoutAll,
          icon: const Icon(Icons.logout_outlined),
          label: Text(l10n.t('signOutAll')),
        ),
      ],
    );
  }

  String _accountType(AccountUser user) {
    final l10n = context.l10n;
    if (user.isAdmin) return l10n.t('administrator');
    if (user.isProfessional) return l10n.t('customerProfessional');
    return l10n.t('customer');
  }

  String _languageName(String code) => switch (code) {
    'tk' => 'Türkmençe',
    'ru' => 'Русский',
    _ => 'English',
  };
}

class _Header extends StatelessWidget {
  const _Header({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.headlineMedium
        ?.copyWith(fontWeight: FontWeight.w800),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});
  final AccountUser user;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : user.phoneNumber;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                _initial(title),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  if (title != user.phoneNumber) Text(user.phoneNumber),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
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
  Widget build(BuildContext context) => Card(
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
