import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../models/professional_portfolio_item.dart';

class ProfessionalPortfolioGallery extends StatelessWidget {
  const ProfessionalPortfolioGallery({required this.items, super.key});

  final List<ProfessionalPortfolioItem> items;

  String _resolvedImageUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return '${ApiConfig.baseUrl}$value';
    }

    return '${ApiConfig.baseUrl}/$value';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];

          return SizedBox(
            width: 150,
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => Dialog(
                      insetPadding: const EdgeInsets.all(16),
                      child: InteractiveViewer(
                        child: Image.network(
                          _resolvedImageUrl(item.imageUrl),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 320,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      _resolvedImageUrl(item.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined, size: 38),
                      ),
                    ),
                    if (item.featured)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(5),
                            child: Icon(Icons.star, size: 18),
                          ),
                        ),
                      ),
                    if ((item.title ?? '').trim().isNotEmpty ||
                        (item.serviceName ?? '').trim().isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black54,
                          child: Text(
                            (item.title ?? '').trim().isNotEmpty
                                ? item.title!
                                : item.serviceName!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
