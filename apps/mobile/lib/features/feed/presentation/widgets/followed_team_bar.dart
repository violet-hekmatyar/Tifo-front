import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/feed_page.dart';

class FollowedTeamBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (teams.isEmpty) return const SizedBox.shrink();
    final config = ref.watch(appConfigProvider);
    return SizedBox(
      height: 86,
      child: ListView.separated(
        key: const ValueKey('followed_team_bar'),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: teams.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _TeamButton(
              label: '全部',
              selected: selectedTeamId == null,
              onTap: () => onSelected(null),
              child: const Icon(Icons.apps_rounded, color: AppColors.brand),
            );
          }
          final team = teams[index - 1];
          return _TeamButton(
            key: ValueKey('followed_team_${team.teamId}'),
            label: team.teamName,
            selected: selectedTeamId == team.teamId,
            onTap: () => onSelected(team.teamId),
            child: AppTeamLogo(
              identity: 'team:${team.teamId}',
              name: team.teamName,
              imageUrl: resolveMediaUrl(config, team.logoUrl),
              size: 42,
            ),
          );
        },
      ),
    );
  }
}

class _TeamButton extends StatelessWidget {
  const _TeamButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppRadius.md),
    child: Container(
      width: 66,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: selected ? AppColors.brandSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: selected ? AppColors.brand : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(dimension: 42, child: Center(child: child)),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}
