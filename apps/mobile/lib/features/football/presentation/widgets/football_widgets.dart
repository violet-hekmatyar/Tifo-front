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
  _ => (label: raw, color: AppColors.inkMuted),
};

class ScheduleMatchCard extends ConsumerWidget {
  const ScheduleMatchCard({required this.match, super.key});
  final FootballMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = footballStatus(match.status);
    final config = ref.watch(appConfigProvider);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('schedule_match_${match.id}'),
        onTap: () => context.push('/matches/${match.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.leagueName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    status.label,
                    style: TextStyle(
                      color: status.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _Team(
                      team: match.homeTeam,
                      imageUrl: resolveMediaUrl(config, match.homeTeam.logoUrl),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        Text(
                          match.homeTeam.score != null &&
                                  match.awayTeam.score != null
                              ? '${match.homeTeam.score} : ${match.awayTeam.score}'
                              : footballTime(match.matchTime),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (match.homeTeam.score != null &&
                            match.awayTeam.score != null)
                          Text(footballTime(match.matchTime)),
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
              if (match.eventSummary != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  match.eventSummary!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
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
      onTap: () => context.push('/teams/${team.id}'),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: Column(
          children: [
            AppTeamLogo(
              identity: 'team:${team.id}',
              name: team.name,
              imageUrl: imageUrl,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    team.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16),
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
