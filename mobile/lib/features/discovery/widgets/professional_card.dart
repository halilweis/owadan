import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/professional_summary.dart';

class ProfessionalCard extends StatelessWidget {
  const ProfessionalCard({
    required this.professional,
    required this.onTap,
    super.key,
  });
  final ProfessionalSummary professional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  _initials(professional.displayName),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            professional.displayName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (professional.verificationStatus == 'APPROVED')
                          Icon(Icons.verified, size: 20, color: scheme.primary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      professional.minPrice == null
                          ? l10n.t('priceOnRequest')
                          : l10n.replace('fromPrice', {
                              'price': professional.minPrice!.toStringAsFixed(
                                2,
                              ),
                              'currency': professional.currency,
                            }),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          professional.averageRating == null
                              ? l10n.t('newProfessional')
                              : professional.averageRating!.toStringAsFixed(1),
                        ),
                        const SizedBox(width: 6),
                        Text('(${professional.reviewCount})'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final result = parts.take(2).map((e) => e[0].toUpperCase()).join();
    return result.isEmpty ? '?' : result;
  }
}
