import 'package:flutter/material.dart';

import '../design_system/app_design_tokens.dart';

class AppContentImage extends StatelessWidget {
  const AppContentImage({this.imageUrl, this.aspectRatio = 4 / 3, super.key});

  final String? imageUrl;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.sports_soccer_rounded,
          color: AppColors.inkMuted,
          size: 38,
        ),
      ),
    );
    return Semantics(
      image: true,
      label: '内容封面',
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: imageUrl == null
            ? fallback
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
