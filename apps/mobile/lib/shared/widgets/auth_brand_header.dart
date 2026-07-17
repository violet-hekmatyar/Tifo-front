import 'package:flutter/material.dart';

import '../design_system/app_design_tokens.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.xxl,
      AppSpacing.xl,
      AppSpacing.huge,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.brandDark, AppColors.brand, AppColors.accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.xl),
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 30),
              SizedBox(width: AppSpacing.sm),
              Text(
                '南看台',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    ),
  );
}
