import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../domain/feed_page.dart';

class FollowedTeamBar extends StatelessWidget {
  const FollowedTeamBar({
    required this.teams,
    required this.selectedTeamId,
    required this.onSelected,
    super.key,
  });

  final List<FollowedTeam> teams;
  final int? selectedTeamId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      key: const ValueKey('followed_team_bar'),
      height: 40,
      child: ListView.separated(
        key: const ValueKey('followed_team_text_list'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: teams.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _TeamChip(
              key: const ValueKey('followed_team_all'),
              label: '全部',
              selected: selectedTeamId == null,
              onTap: () => onSelected(null),
            );
          }
          final team = teams[index - 1];
          final canSelect = team.teamId > 0;
          return _TeamChip(
            key: ValueKey('followed_team_${team.teamId}'),
            label: team.teamName,
            semanticLabel:
                canSelect
                    ? '筛选 ${team.teamName} 内容'
                    : '${team.teamName} 暂不可用',
            selected: selectedTeamId == team.teamId,
            onTap: canSelect ? () => onSelected(team.teamId) : null,
          );
        },
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  const _TeamChip({
    required this.label,
    this.semanticLabel,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String? semanticLabel;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: semanticLabel ?? label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.inkMuted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}
