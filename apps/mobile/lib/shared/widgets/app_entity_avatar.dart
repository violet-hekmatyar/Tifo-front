import 'package:flutter/material.dart';

import '../design_system/app_design_tokens.dart';

const _entityColors = <Color>[
  Color(0xFFE9E6FF),
  Color(0xFFDDF1FF),
  Color(0xFFFFE7D6),
  Color(0xFFDDF4E8),
  Color(0xFFF3E0F6),
  Color(0xFFFFE1E8),
];

Color stableEntityColor(String identity) {
  var hash = 0x811C9DC5;
  for (final unit in identity.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return _entityColors[hash % _entityColors.length];
}

class AppEntityAvatar extends StatelessWidget {
  const AppEntityAvatar({
    required this.identity,
    required this.semanticLabel,
    required this.fallbackIcon,
    this.imageUrl,
    this.fallbackText,
    this.size = 48,
    this.circular = true,
    super.key,
  });

  final String identity;
  final String semanticLabel;
  final IconData fallbackIcon;
  final String? imageUrl;
  final String? fallbackText;
  final double size;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final radius = circular ? size / 2 : AppRadius.sm;
    final fallback = Center(
      child: fallbackText?.isNotEmpty == true
          ? Text(
              fallbackText!,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.brandDark),
            )
          : Icon(fallbackIcon, color: AppColors.brandDark, size: size * .48),
    );
    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: stableEntityColor(identity),
          child: SizedBox.square(
            dimension: size,
            child: imageUrl == null
                ? fallback
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                  ),
          ),
        ),
      ),
    );
  }
}
