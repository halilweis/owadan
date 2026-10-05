import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'models/pro_profile.dart';
import 'professional_repository.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  const ProfessionalProfileScreen({required this.repository, super.key});

  final ProfessionalRepository repository;

  @override
  State<ProfessionalProfileScreen> createState() =>
      _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _submitting = false;
  String? _error;

  ProProfile? _profile;
  List<ProDistrict> _districts = const [];
  int? _districtId;
  final Set<String> _languages = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.repository.fetchProfile(),
        widget.repository.fetchDistricts(),
      ]);

      if (!mounted) {
        return;
      }

      final profile = results[0] as ProProfile?;
      final districts = results[1] as List<ProDistrict>;

      _nameController.text = profile?.displayName ?? '';
      _bioController.text = profile?.bio ?? '';
      _experienceController.text = profile?.experienceYears?.toString() ?? '';
      _languages
        ..clear()
        ..addAll(profile?.languages ?? const []);
      _districtId = profile?.districtId;

      setState(() {
        _profile = profile;
        _districts = districts;
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

  Future<void> _save() async {
    if (_saving) {
      return;
    }

    final name = _nameController.text.trim();
    final experienceText = _experienceController.text.trim();
    final experience = experienceText.isEmpty
        ? null
        : int.tryParse(experienceText);

    if (name.isEmpty) {
      setState(() {
        _error = _text(
          en: 'Display name is required.',
          ru: 'Укажите отображаемое имя.',
          tk: 'Görkezilýän at hökmany.',
        );
      });
      return;
    }

    if (experienceText.isNotEmpty &&
        (experience == null || experience < 0 || experience > 80)) {
      setState(() {
        _error = _text(
          en: 'Experience must be between 0 and 80 years.',
          ru: 'Опыт должен быть от 0 до 80 лет.',
          tk: 'Tejribe 0 bilen 80 ýylyň arasynda bolmaly.',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final profile = await widget.repository.saveProfile(
        displayName: name,
        bio: _bioController.text,
        experienceYears: experience,
        languages: _languages.toList()..sort(),
        districtId: _districtId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              en: 'Professional profile saved.',
              ru: 'Профиль специалиста сохранён.',
              tk: 'Hünärmen profili ýatda saklandy.',
            ),
          ),
        ),
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
          _saving = false;
        });
      }
    }
  }

  Future<void> _submitForVerification() async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final profile = await widget.repository.submitVerification();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              en: 'Profile submitted for verification.',
              ru: 'Профиль отправлен на проверку.',
              tk: 'Profil barlag üçin ugradyldy.',
            ),
          ),
        ),
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
          _submitting = false;
        });
      }
    }
  }

  String _text({required String en, required String ru, required String tk}) {
    return switch (Localizations.localeOf(context).languageCode) {
      'tk' => tk,
      'ru' => ru,
      _ => en,
    };
  }

  String _statusText(String status) {
    return switch (status) {
      'DRAFT' => _text(en: 'Draft', ru: 'Черновик', tk: 'Garalama'),
      'PENDING' => _text(en: 'Pending', ru: 'На проверке', tk: 'Barlagda'),
      'APPROVED' => _text(en: 'Approved', ru: 'Одобрено', tk: 'Tassyklanan'),
      'REJECTED' => _text(en: 'Rejected', ru: 'Отклонено', tk: 'Ret edilen'),
      _ => status,
    };
  }

  bool get _canSubmitForVerification {
    final status = _profile?.verificationStatus ?? 'DRAFT';
    return status == 'DRAFT' || status == 'REJECTED';
  }

  void _toggleLanguage(String code, bool selected) {
    setState(() {
      if (selected) {
        _languages.add(code);
      } else {
        _languages.remove(code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(
            en: 'Professional profile',
            ru: 'Профиль специалиста',
            tk: 'Hünärmen profili',
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _StatusCard(
                  label: _text(
                    en: 'Verification status',
                    ru: 'Статус проверки',
                    tk: 'Barlag ýagdaýy',
                  ),
                  status: _statusText(_profile?.verificationStatus ?? 'DRAFT'),
                  active: _profile?.active ?? true,
                  activeText: _text(
                    en: 'Profile active',
                    ru: 'Профиль активен',
                    tk: 'Profil işjeň',
                  ),
                  inactiveText: _text(
                    en: 'Profile inactive',
                    ru: 'Профиль неактивен',
                    tk: 'Profil işjeň däl',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  enabled: !_saving,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: _text(
                      en: 'Display name',
                      ru: 'Отображаемое имя',
                      tk: 'Görkezilýän at',
                    ),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bioController,
                  enabled: !_saving,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 1500,
                  decoration: InputDecoration(
                    labelText: _text(
                      en: 'Bio',
                      ru: 'О себе',
                      tk: 'Özüň barada',
                    ),
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _experienceController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _text(
                      en: 'Experience (years)',
                      ru: 'Опыт (лет)',
                      tk: 'Tejribe (ýyl)',
                    ),
                    prefixIcon: const Icon(Icons.workspace_premium_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _text(en: 'Languages', ru: 'Языки', tk: 'Diller'),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Türkmençe'),
                      selected: _languages.contains('tk'),
                      onSelected: (value) => _toggleLanguage('tk', value),
                    ),
                    FilterChip(
                      label: const Text('Русский'),
                      selected: _languages.contains('ru'),
                      onSelected: (value) => _toggleLanguage('ru', value),
                    ),
                    FilterChip(
                      label: const Text('English'),
                      selected: _languages.contains('en'),
                      onSelected: (value) => _toggleLanguage('en', value),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int?>(
                  initialValue: _districtId,
                  decoration: InputDecoration(
                    labelText: _text(en: 'District', ru: 'Район', tk: 'Etrap'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        _text(
                          en: 'Not selected',
                          ru: 'Не выбран',
                          tk: 'Saýlanmady',
                        ),
                      ),
                    ),
                    ..._districts.map(
                      (district) => DropdownMenuItem<int?>(
                        value: district.id,
                        child: Text('${district.cityName} • ${district.name}'),
                      ),
                    ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          setState(() {
                            _districtId = value;
                          });
                        },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _text(
                      en: 'Save profile',
                      ru: 'Сохранить профиль',
                      tk: 'Profili ýatda sakla',
                    ),
                  ),
                ),
                if (_canSubmitForVerification) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _submitForVerification,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_outlined),
                    label: Text(
                      _text(
                        en: 'Submit for verification',
                        ru: 'Отправить на проверку',
                        tk: 'Barlaga ugrat',
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.status,
    required this.active,
    required this.activeText,
    required this.inactiveText,
  });

  final String label;
  final String status;
  final bool active;
  final String activeText;
  final String inactiveText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.verified_user_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(active ? activeText : inactiveText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
