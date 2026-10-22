import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'models/pro_analytics.dart';
import 'professional_repository.dart';

class ProfessionalAnalyticsScreen extends StatefulWidget {
  const ProfessionalAnalyticsScreen({required this.repository, super.key});

  final ProfessionalRepository repository;

  @override
  State<ProfessionalAnalyticsScreen> createState() =>
      _ProfessionalAnalyticsScreenState();
}

class _ProfessionalAnalyticsScreenState
    extends State<ProfessionalAnalyticsScreen> {
  bool _loading = true;
  String? _error;
  ProAnalytics? _analytics;

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
      final analytics = await widget.repository.fetchAnalytics();

      if (!mounted) return;

      setState(() {
        _analytics = analytics;
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

  @override
  Widget build(BuildContext context) {
    final analytics = _analytics;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(
            en: 'Earnings & analytics',
            ru: 'Доходы и аналитика',
            tk: 'Girdeji we analitika',
          ),
        ),
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
                  const Icon(Icons.analytics_outlined, size: 54),
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
            : analytics == null
            ? const SizedBox.shrink()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.25,
                    children: [
                      _StatCard(
                        icon: Icons.payments_outlined,
                        value:
                            '${analytics.monthRevenue.toStringAsFixed(2)} ${analytics.currency}',
                        label: _text(
                          en: 'This month',
                          ru: 'Этот месяц',
                          tk: 'Şu aý',
                        ),
                      ),
                      _StatCard(
                        icon: Icons.account_balance_wallet_outlined,
                        value:
                            '${analytics.totalRevenue.toStringAsFixed(2)} ${analytics.currency}',
                        label: _text(
                          en: 'All-time revenue',
                          ru: 'Доход за всё время',
                          tk: 'Jemi girdeji',
                        ),
                      ),
                      _StatCard(
                        icon: Icons.task_alt_outlined,
                        value:
                            '${analytics.completionRate.toStringAsFixed(1)}%',
                        label: _text(
                          en: 'Completion rate',
                          ru: 'Завершение',
                          tk: 'Tamamlanma',
                        ),
                      ),
                      _StatCard(
                        icon: Icons.person_off_outlined,
                        value: '${analytics.noShowRate.toStringAsFixed(1)}%',
                        label: _text(
                          en: 'No-show rate',
                          ru: 'Неявки',
                          tk: 'Gelmezlik',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _text(
                      en: 'Revenue trend',
                      ru: 'Динамика дохода',
                      tk: 'Girdeji ösüşi',
                    ),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  _RevenueBars(
                    months: analytics.months,
                    currency: analytics.currency,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _text(en: 'Performance', ru: 'Результаты', tk: 'Netijeler'),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _MetricRow(
                            label: _text(
                              en: 'All bookings',
                              ru: 'Все записи',
                              tk: 'Ähli ýazgylar',
                            ),
                            value: '${analytics.totalCount}',
                          ),
                          const Divider(),
                          _MetricRow(
                            label: _text(
                              en: 'Completed',
                              ru: 'Завершено',
                              tk: 'Tamamlanan',
                            ),
                            value: '${analytics.completedCount}',
                          ),
                          const Divider(),
                          _MetricRow(
                            label: _text(
                              en: 'No-shows',
                              ru: 'Неявки',
                              tk: 'Gelmedik',
                            ),
                            value: '${analytics.noShowCount}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _text(
                      en: 'Top services',
                      ru: 'Лучшие услуги',
                      tk: 'Iň gowy hyzmatlar',
                    ),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (analytics.topServices.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          _text(
                            en: 'No service data yet.',
                            ru: 'Данных по услугам пока нет.',
                            tk: 'Hyzmat maglumatlary entäk ýok.',
                          ),
                        ),
                      ),
                    )
                  else
                    ...analytics.topServices.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${entry.key + 1}'),
                            ),
                            title: Text(
                              entry.value.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              _text(
                                en: '${entry.value.bookings} bookings • ${entry.value.completed} completed',
                                ru: '${entry.value.bookings} записей • ${entry.value.completed} завершено',
                                tk: '${entry.value.bookings} ýazgy • ${entry.value.completed} tamamlandy',
                              ),
                            ),
                            trailing: Text(
                              '${entry.value.revenue.toStringAsFixed(2)} ${analytics.currency}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _RevenueBars extends StatelessWidget {
  const _RevenueBars({required this.months, required this.currency});

  final List<ProAnalyticsMonth> months;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxRevenue = months.fold<double>(
      0,
      (max, month) => month.revenue > max ? month.revenue : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
        child: SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: months.map((month) {
              final ratio = maxRevenue <= 0 ? 0.0 : month.revenue / maxRevenue;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        month.revenue.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 140 * ratio + 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        month.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
