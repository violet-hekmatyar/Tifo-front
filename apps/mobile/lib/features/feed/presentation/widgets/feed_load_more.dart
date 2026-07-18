import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';

class FeedLoadMore extends StatelessWidget {
  const FeedLoadMore({
    required this.isLoading,
    required this.hasMore,
    this.message,
    this.onRetry,
    super.key,
  });

  final bool isLoading;
  final bool hasMore;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Center(
      child: switch ((isLoading, message, hasMore)) {
        (true, _, _) => const CircularProgressIndicator(),
        (_, final message?, _) => TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text('$message 点击重试'),
        ),
        (_, _, false) => const Text(
          '已经到底了',
          style: TextStyle(color: AppColors.inkMuted),
        ),
        _ => const SizedBox.shrink(),
      },
    ),
  );
}
