import 'package:flutter/material.dart';

import '../../../base/crypt/security.dart';
import '../../../base/router/route_helper.dart';
import '../../../core/util/cached_image.dart';
import '../../../localize/tab_labels.dart';
import '../../../shared/widget/character_card.dart';

class StoryCardWidget extends StatelessWidget {
  const StoryCardWidget({super.key, required this.item});

  final Map item;

  @override
  Widget build(BuildContext context) {
    final String name = item[Security.security_name] ?? '';
    final String coverUrl = item[Security.security_coverUrl] ?? '';
    final List<String> tags = ((item[Security.security_tags] ?? []) as List)
        .cast<String>();
    final String brief = item[Security.security_brief] ?? '';

    return CharacterCard(
      image: CachedNetImage(imageUrl: coverUrl, fit: BoxFit.cover),
      name: name,
      badge: CharacterCardBadge(label: TabLabels.story),
      bio: brief,
      tags: tags,
      onTap: () => RouteHelper.toChatTheater(item),
      footer: CharacterCardAction(label: Security.security_gO),
    );
  }
}
