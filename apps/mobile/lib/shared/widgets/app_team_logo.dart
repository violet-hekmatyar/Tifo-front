import 'package:flutter/material.dart';

import 'app_entity_avatar.dart';

class AppTeamLogo extends StatelessWidget {
  const AppTeamLogo({
    required this.identity,
    required this.name,
    this.imageUrl,
    this.size = 48,
    super.key,
  });

  final String identity;
  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) => AppEntityAvatar(
    identity: identity,
    semanticLabel: '$name 球队标识',
    fallbackIcon: Icons.shield_outlined,
    fallbackText: name.trim().characters.firstOrNull,
    imageUrl: imageUrl,
    size: size,
    circular: false,
  );
}
