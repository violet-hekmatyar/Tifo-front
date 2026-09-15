import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';

enum PublishMode { post, article }

class PublishModeBar extends StatelessWidget {
  const PublishModeBar({
    required this.mode,
    required this.onModeSelected,
    this.tools = const [],
    this.enabled = true,
    super.key,
  });

  final PublishMode mode;
  final ValueChanged<PublishMode> onModeSelected;
  final List<Widget> tools;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            for (final tool in tools) tool,
            if (tools.isNotEmpty) const Spacer(),
            Row(
              key: const ValueKey('publish_mode_switcher'),
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeChip(
                  key: const ValueKey('publish_mode_post'),
                  mode: PublishMode.post,
                  selected: mode == PublishMode.post,
                  enabled: enabled,
                  onPressed: () => onModeSelected(PublishMode.post),
                ),
                const SizedBox(width: AppSpacing.xs),
                _ModeChip(
                  key: const ValueKey('publish_mode_article'),
                  mode: PublishMode.article,
                  selected: mode == PublishMode.article,
                  enabled: enabled,
                  onPressed: () => onModeSelected(PublishMode.article),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.mode,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final PublishMode mode;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(mode == PublishMode.post ? '帖子' : '文章'),
    avatar: Icon(
      mode == PublishMode.post ? Icons.forum_outlined : Icons.article_outlined,
      size: 18,
    ),
    selected: selected,
    onSelected: enabled ? (_) => onPressed() : null,
  );
}
