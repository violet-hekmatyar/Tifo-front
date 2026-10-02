import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/football_models.dart';

String footballDate(DateTime? value) {
  if (value == null) return '日期待定';
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String footballTime(DateTime? value) {
  if (value == null) return '时间待定';
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

({String label, Color color}) footballStatus(String raw) => switch (raw) {
  'LIVE' ||
  'IN_PROGRESS' ||
  'PLAYING' ||
  'HALF_TIME' ||
  'SECOND_HALF' ||
  'EXTRA_TIME' => (label: '进行中', color: AppColors.error),
  'FINISHED' ||
  'ENDED' ||
  'COMPLETED' => (label: '已结束', color: AppColors.brand),
  'SCHEDULED' ||
  'NOT_STARTED' ||
  'UPCOMING' => (label: '未开始', color: AppColors.success),
  'POSTPONED' => (label: '已延期', color: AppColors.warning),
  'CANCELLED' => (label: '已取消', color: AppColors.inkMuted),
  _ => (label: raw.trim().isEmpty ? '状态未知' : raw, color: AppColors.inkMuted),
};

class ScheduleMatchCard extends ConsumerWidget {
  const ScheduleMatchCard({
    required this.match,
    this.header,
    this.showFavorite = true,
    super.key,
  });
  final FootballMatch match;
  final String? header;
  final bool showFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = footballStatus(match.status);
    final config = ref.watch(appConfigProvider);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('schedule_match_${match.id}'),
        onTap: match.id > 0 ? () => context.push('/matches/${match.id}') : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              if (header != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    header!,
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 18,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      match.leagueName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  if (showFavorite)
                    const Icon(
                      Icons.star_border_rounded,
                      size: 24,
                      color: AppColors.inkMuted,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    status.label,
                    style: TextStyle(
                      color: status.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _Team(
                      team: match.homeTeam,
                      imageUrl: resolveMediaUrl(config, match.homeTeam.logoUrl),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Text(
                          match.homeTeam.score != null &&
                                  match.awayTeam.score != null
                              ? '${match.homeTeam.score} : ${match.awayTeam.score}'
                              : footballTime(match.matchTime),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: match.homeTeam.score != null
                                    ? AppColors.ink
                                    : AppColors.inkMuted,
                              ),
                        ),
                        if (match.homeTeam.score != null &&
                            match.awayTeam.score != null)
                          Text(
                            footballTime(match.matchTime),
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _Team(
                      team: match.awayTeam,
                      imageUrl: resolveMediaUrl(config, match.awayTeam.logoUrl),
                    ),
                  ),
                ],
              ),
              if (match.eventSummary?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        size: 18,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          match.eventSummary!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.inkMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Team extends StatelessWidget {
  const _Team({required this.team, required this.imageUrl});
  final FootballTeam team;
  final String? imageUrl;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '查看${team.name}球队详情',
    child: InkWell(
      onTap: team.id > 0 ? () => context.push('/teams/${team.id}') : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: Column(
          children: [
            AppTeamLogo(
              identity: 'team:${team.id}',
              name: team.name,
              imageUrl: imageUrl,
              size: 50,
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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

class CapabilityEmpty extends StatelessWidget {
  const CapabilityEmpty({
    required this.title,
    required this.message,
    super.key,
  });
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.data_usage_outlined,
              color: AppColors.inkMuted,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    ),
  );
}

class DetailFact extends StatelessWidget {
  const DetailFact({required this.label, required this.value, super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: const TextStyle(color: AppColors.inkMuted)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
