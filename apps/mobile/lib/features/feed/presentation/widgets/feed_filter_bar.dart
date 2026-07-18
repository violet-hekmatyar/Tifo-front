import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../domain/feed_filter.dart';

class FeedFilterBar extends StatelessWidget {
  const FeedFilterBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final FeedFilter selected;
  final ValueChanged<FeedFilter> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      scrollDirection: Axis.horizontal,
      itemCount: FeedFilter.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
      itemBuilder: (context, index) {
        final filter = FeedFilter.values[index];
        return ChoiceChip(
          key: ValueKey('feed_filter_${filter.name}'),
          label: Text(filter.label),
          selected: selected == filter,
          onSelected: (_) => onSelected(filter),
          showCheckmark: false,
          selectedColor: AppColors.brand,
          labelStyle: TextStyle(
            color: selected == filter ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    ),
  );
}
