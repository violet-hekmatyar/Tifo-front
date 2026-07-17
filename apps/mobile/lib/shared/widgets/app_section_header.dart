import 'package:flutter/material.dart';

import '../design_system/app_design_tokens.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    required this.description,
    this.trailing,
    super.key,
  });

  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?trailing,
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        description,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
      ),
    ],
  );
}
