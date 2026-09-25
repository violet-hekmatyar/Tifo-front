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
      height: 72,
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
          final canSelectTeam = team.teamId > 0;
          return _TeamButton(
            key: ValueKey('followed_team_${team.teamId}'),
            label: team.teamName,
            selected: selectedTeamId == team.teamId,
            semanticLabel: canSelectTeam
                ? '筛选 ${team.teamName} 内容'
                : '${team.teamName} 暂不可用',
            onTap: canSelectTeam ? () => onSelected(team.teamId) : null,
            child: AppTeamLogo(
              identity: 'team:${team.teamId}',
              name: team.teamName,
              imageUrl: resolveMediaUrl(config, team.logoUrl),
              size: 32,
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
    this.semanticLabel,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: semanticLabel,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 4,
        ),
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
            SizedBox.square(dimension: 32, child: Center(child: child)),
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
    ),
  );
}
