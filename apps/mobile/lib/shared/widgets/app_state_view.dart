import 'package:flutter/material.dart';

import '../design_system/app_design_tokens.dart';
import 'app_primary_button.dart';

enum AppStateKind { loading, empty, error, success }

class AppStateView extends StatelessWidget {
  const AppStateView({
    required this.kind,
    required this.title,
    required this.message,
    this.onRetry,
    super.key,
  });

  final AppStateKind kind;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      AppStateKind.loading => Icons.hourglass_top_rounded,
      AppStateKind.empty => Icons.inbox_outlined,
      AppStateKind.error => Icons.cloud_off_rounded,
      AppStateKind.success => Icons.check_circle_rounded,
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kind == AppStateKind.loading)
                const CircularProgressIndicator()
              else
                Icon(icon, size: 54, color: AppColors.brand),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: '重试',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
