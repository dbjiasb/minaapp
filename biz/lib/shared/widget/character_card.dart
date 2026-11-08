import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Light character card; keeps copy on a solid surface instead of the image.
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    super.key,
    required this.image,
    required this.name,
    required this.onTap,
    this.badge,
    this.bio = '',
    this.tags = const [],
    this.creator = '',
    this.connections = '',
    this.heat = '',
  });

  final Widget image;
  final String name;
  final VoidCallback onTap;
  final Widget? badge;
  final String bio;
  final List<String> tags;
  final String creator;
  final String connections;
  final String heat;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 0.92, child: image),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (badge != null) badge!,
                    ],
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: tags
                          .take(4)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (creator.isNotEmpty ||
                      connections.isNotEmpty ||
                      heat.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    if (creator.isNotEmpty)
                      Text(
                        '@$creator',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    if (connections.isNotEmpty || heat.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (connections.isNotEmpty)
                            _stat(
                              Icons.chat_bubble_outline_rounded,
                              connections,
                            ),
                          if (heat.isNotEmpty)
                            _stat(Icons.favorite_border_rounded, heat),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: AppColors.textSecondary),
      const SizedBox(width: 3),
      Text(
        value,
        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
      ),
    ],
  );
}
