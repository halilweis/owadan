import 'package:flutter/material.dart';

import '../models/category_model.dart';

class CategoryChipCard extends StatelessWidget {
  const CategoryChipCard({
    required this.category,
    required this.onTap,
    super.key,
  });

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 132,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.secondaryContainer,
                child: Icon(_iconFor(category.slug)),
              ),
              const SizedBox(height: 12),
              Text(
                category.displayName(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String slug) {
    final value = slug.toLowerCase();
    if (value.contains('hair')) return Icons.content_cut;
    if (value.contains('nail')) return Icons.back_hand_outlined;
    if (value.contains('makeup')) return Icons.brush_outlined;
    if (value.contains('skin')) return Icons.spa_outlined;
    return Icons.auto_awesome_outlined;
  }
}
