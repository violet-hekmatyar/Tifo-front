import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../domain/feed_filter.dart';
import '../../domain/feed_page.dart';

class FeedFilterBar extends ConsumerWidget {
  const FeedFilterBar({
    required this.selected,
    required this.onSelected,
    this.teams = const [],
    this.selectedTeamId,
    this.onTeamSelected,
    this.onManageTeams,
    super.key,
  });

  final FeedFilter selected;
  final ValueChanged<FeedFilter> onSelected;
  final List<FollowedTeam> teams;
  final int? selectedTeamId;
  final ValueChanged<int?>? onTeamSelected;
  final VoidCallback? onManageTeams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              key: const ValueKey('home_feed_navigation'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              children: [
                for (final filter in FeedFilter.values)
                  _FilterTab(
                    key: ValueKey('feed_filter_${filter.name}'),
                    label: filter.label,
                    selected: selected == filter,
                    onTap: () => onSelected(filter),
                  ),
                if (teams.isNotEmpty) ...[
                  const _NavDivider(),
                  for (final team in teams)
                    _TeamNavItem(
                      key: ValueKey('followed_team_${team.teamId}'),
                      team: team,
                      selected: selectedTeamId == team.teamId,
                      showName: true,
                      imageUrl: resolveMediaUrl(config, team.logoUrl),
                      onTap: onTeamSelected == null || team.teamId <= 0
                          ? null
                          : () => onTeamSelected!(
                              selectedTeamId == team.teamId
                                  ? null
                                  : team.teamId,
                            ),
                    ),
                ],
              ],
            ),
          ),
          if (onManageTeams != null)
            Container(
              width: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.border)),
              ),
              child: IconButton(
                key: const ValueKey('manage_followed_teams'),
                tooltip: '管理关注球队',
                onPressed: onManageTeams,
                icon: const Icon(Icons.menu_rounded),
                color: AppColors.inkMuted,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        height: 46,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? AppColors.ink : AppColors.inkMuted,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 3,
              width: selected ? 24 : 0,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NavDivider extends StatelessWidget {
  const _NavDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 22,
    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    color: AppColors.border,
  );
}

class _TeamNavItem extends StatelessWidget {
  const _TeamNavItem({
    required this.team,
    required this.selected,
    required this.showName,
    required this.imageUrl,
    required this.onTap,
    super.key,
  });

  final FollowedTeam team;
  final bool selected;
  final bool showName;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: onTap == null ? '${team.teamName} 暂不可用' : '筛选 ${team.teamName} 内容',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TeamNavLogo(imageUrl: imageUrl, size: 24),
            if (showName) ...[
              const SizedBox(width: 3),
              Text(
                team.teamName,
                maxLines: 1,
                softWrap: false,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? AppColors.brandDark : AppColors.inkMuted,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _TeamNavLogo extends StatelessWidget {
  const _TeamNavLogo({required this.imageUrl, required this.size});

  static const _asset = 'assets/ui/home/neutral-team-crest.png';
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final networkImage = imageUrl?.toLowerCase().endsWith('.png') == true;
    final fallback = Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.brandSoft),
        const Center(
          child: Icon(
            Icons.shield_rounded,
            color: AppColors.brandDark,
            size: 21,
          ),
        ),
        Image.asset(_asset, fit: BoxFit.contain),
      ],
    );
    final image = networkImage
        ? Stack(
            fit: StackFit.expand,
            children: [
              fallback,
              Image.network(
                imageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const SizedBox.shrink(),
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ],
          )
        : fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox.square(dimension: size, child: image),
    );
  }
}
