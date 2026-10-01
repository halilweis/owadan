import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/network/api_exception.dart';
import 'models/account_user.dart';
import 'profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    required this.repository,
    required this.user,
    super.key,
  });
  final ProfileRepository repository;
  final AccountUser user;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late String _language;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.user.displayName ?? '',
    );
    _language = widget.user.preferredLanguage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.repository.updateProfile(
        displayName: name.isEmpty ? null : name,
        preferredLanguage: _language,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('editProfile'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: l10n.t('displayName'),
              hintText: l10n.t('displayNameHint'),
              prefixIcon: const Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.t('preferredLanguage'),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _language,
            onChanged: (value) {
              if (value != null) setState(() => _language = value);
            },
            child: const Column(
              children: [
                RadioListTile<String>(value: 'tk', title: Text('Türkmençe')),
                RadioListTile<String>(value: 'ru', title: Text('Русский')),
                RadioListTile<String>(value: 'en', title: Text('English')),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.t('saveChanges')),
          ),
        ],
      ),
    );
  }
}
