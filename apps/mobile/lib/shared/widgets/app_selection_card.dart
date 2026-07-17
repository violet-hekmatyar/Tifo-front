import 'package:flutter/material.dart';

import '../design_system/app_design_tokens.dart';

class AppSelectionCard extends StatelessWidget {
  const AppSelectionCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: selected ? AppColors.brandSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selected ? AppColors.brand : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          leading: leading,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: subtitle?.isNotEmpty == true ? Text(subtitle!) : null,
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: selected
                ? const Icon(
                    Icons.check_circle_rounded,
                    key: ValueKey('selected'),
                    color: AppColors.brand,
                  )
                : const Icon(
                    Icons.circle_outlined,
                    key: ValueKey('unselected'),
                    color: AppColors.inkMuted,
                  ),
          ),
        ),
      ),
    ),
  );
}
