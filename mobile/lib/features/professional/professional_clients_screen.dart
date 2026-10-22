import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'models/pro_client.dart';
import 'professional_client_detail_screen.dart';
import 'professional_repository.dart';

class ProfessionalClientsScreen extends StatefulWidget {
  const ProfessionalClientsScreen({required this.repository, super.key});

  final ProfessionalRepository repository;

  @override
  State<ProfessionalClientsScreen> createState() =>
      _ProfessionalClientsScreenState();
}

class _ProfessionalClientsScreenState extends State<ProfessionalClientsScreen> {
  bool _loading = true;
  String? _error;
  String _query = '';
  List<ProClientSummary> _clients = const [];

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
      final clients = await widget.repository.fetchClients();

      if (!mounted) return;

      setState(() {
        _clients = clients;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
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

  List<ProClientSummary> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _clients;

    return _clients.where((client) {
      return client.title.toLowerCase().contains(q) ||
          client.phoneNumber.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final clients = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: Text(_text(en: 'Clients', ru: 'Клиенты', tk: 'Müşderiler')),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 130),
                  const Icon(Icons.people_outline, size: 54),
                  const SizedBox(height: 14),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _load,
                    child: Text(
                      _text(
                        en: 'Try again',
                        ru: 'Повторить',
                        tk: 'Gaýtadan synanyş',
                      ),
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: _text(
                        en: 'Search clients',
                        ru: 'Поиск клиентов',
                        tk: 'Müşderi gözle',
                      ),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (clients.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Row(
                          children: [
                            const Icon(Icons.people_outline),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _text(
                                  en: 'No clients found.',
                                  ru: 'Клиенты не найдены.',
                                  tk: 'Müşderi tapylmady.',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...clients.map(
                      (client) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(_initials(client.title)),
                            ),
                            title: Text(
                              client.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (client.displayName != null)
                                  Text(client.phoneNumber),
                                const SizedBox(height: 4),
                                Text(
                                  _text(
                                    en: '${client.appointmentCount} appointments • ${client.completedCount} completed',
                                    ru: '${client.appointmentCount} записей • ${client.completedCount} завершено',
                                    tk: '${client.appointmentCount} ýazgy • ${client.completedCount} tamamlandy',
                                  ),
                                ),
                                if (client.noShowCount > 0)
                                  Text(
                                    _text(
                                      en: '${client.noShowCount} no-show',
                                      ru: 'Неявок: ${client.noShowCount}',
                                      tk: 'Gelmedik: ${client.noShowCount}',
                                    ),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ProfessionalClientDetailScreen(
                                        repository: widget.repository,
                                        customerId: client.customerId,
                                      ),
                                ),
                              );

                              if (mounted) {
                                await _load();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
