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
    this.footer,
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
  final Widget? footer;

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
            AspectRatio(
              aspectRatio: 0.92,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image,
                  if (badge != null) Positioned(top: 8, left: 8, child: badge!),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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
                  if (footer != null) ...[const SizedBox(height: 10), footer!],
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

/// Shared typography and spacing for labels over card images.
class CharacterCardBadge extends StatelessWidget {
  const CharacterCardBadge({
    super.key,
    required this.label,
    this.backgroundColor = AppColors.selected,
    this.foregroundColor = AppColors.accentForeground,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    ),
  );
}

/// The surrounding card handles taps for this full-width action label too.
class CharacterCardAction extends StatelessWidget {
  const CharacterCardAction({
    super.key,
    required this.label,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.accentForeground,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    height: 36,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: backgroundColor,
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foregroundColor,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    ),
  );
}
