import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';

enum PublishMode { post, article }

class PublishModeBar extends StatelessWidget {
  const PublishModeBar({
    required this.mode,
    required this.onModeSelected,
    this.tools = const [],
    this.auxiliary = const [],
    this.enabled = true,
    super.key,
  });

  final PublishMode mode;
  final ValueChanged<PublishMode> onModeSelected;
  final List<Widget> tools;
  final List<Widget> auxiliary;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auxiliary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: auxiliary,
                  ),
                ),
              ),
            Row(
              children: [
                for (final tool in tools) tool,
                const Spacer(),
                SizedBox(
                  width: 168,
                  child: Row(
                    key: const ValueKey('publish_mode_switcher'),
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ModeButton(
                        key: const ValueKey('publish_mode_post'),
                        label: '帖子',
                        selected: mode == PublishMode.post,
                        enabled: enabled,
                        onPressed: () => onModeSelected(PublishMode.post),
                      ),
                      _ModeButton(
                        key: const ValueKey('publish_mode_article'),
                        label: '文章',
                        selected: mode == PublishMode.article,
                        enabled: enabled,
                        onPressed: () => onModeSelected(PublishMode.article),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 84,
    height: 48,
    child: TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: selected ? AppColors.brand : AppColors.ink,
        shape: const RoundedRectangleBorder(),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Positioned(
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: selected ? 28 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
