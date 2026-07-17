import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Temporary F01 seed color. The product design system will replace it later.
  static const _seedColor = Color(0xFF4F46E5);

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
    useMaterial3: true,
  );
}
