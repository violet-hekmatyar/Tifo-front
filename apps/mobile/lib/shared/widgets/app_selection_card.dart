import 'package:flutter/material.dart';

import '../design_system/app_design_tokens.dart';

class AppSelectionCard extends StatelessWidget {
  const AppSelectionCard({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.selectedIcon,
    this.unselectedIcon,
    this.selectedFillColor,
    this.selectedBorderColor,
    this.unselectedBorderColor,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.marginBottom,
    this.borderRadius,
    this.contentPadding,
    this.titleStyle,
    this.subtitleStyle,
    this.bodyKey,
    this.dense = false,
    this.visualDensity,
    this.minVerticalPadding,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final IconData? selectedIcon;
  final IconData? unselectedIcon;
  final Color? selectedFillColor;
  final Color? selectedBorderColor;
  final Color? unselectedBorderColor;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final double? marginBottom;
  final double? borderRadius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Key? bodyKey;
  final bool dense;
  final VisualDensity? visualDensity;
  final double? minVerticalPadding;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: AnimatedContainer(
      key: bodyKey,
      duration: const Duration(milliseconds: 160),
      margin: EdgeInsets.only(bottom: marginBottom ?? AppSpacing.sm),
      decoration: BoxDecoration(
        color: selected
            ? (selectedFillColor ?? AppColors.brandSoft)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.md),
        border: Border.all(
          color: selected
              ? (selectedBorderColor ?? AppColors.brand)
              : (unselectedBorderColor ?? AppColors.border),
          width: selected && selectedBorderColor == null ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          dense: dense,
          visualDensity: visualDensity,
          minVerticalPadding: minVerticalPadding,
          leading: leading,
          contentPadding: contentPadding,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle ?? const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: subtitle?.isNotEmpty == true
              ? Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                )
              : null,
          trailing: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: selected
                ? Icon(
                    selectedIcon ?? Icons.check_circle_rounded,
                    key: const ValueKey('selected'),
                    color: selectedIconColor ?? AppColors.brand,
                  )
                : Icon(
                    unselectedIcon ?? Icons.circle_outlined,
                    key: const ValueKey('unselected'),
                    color: unselectedIconColor ?? AppColors.inkMuted,
                  ),
          ),
        ),
      ),
    ),
  );
}
