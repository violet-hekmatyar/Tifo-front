import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String? fontFamily = null;

  static TextTheme textTheme(TextTheme base) => base.copyWith(
    displaySmall: base.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.12,
    ),
    headlineSmall: base.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      height: 1.2,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.25,
    ),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    bodyLarge: base.bodyLarge?.copyWith(height: 1.55),
    bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}
