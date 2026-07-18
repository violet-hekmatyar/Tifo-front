import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/feed_card.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    required this.card,
    required this.onTap,
    this.homeLogoUrl,
    this.awayLogoUrl,
    super.key,
  });

  final MatchFeedCard card;
  final VoidCallback onTap;
  final String? homeLogoUrl;
  final String? awayLogoUrl;

  @override
  Widget build(BuildContext context) {
    final status = _status(card.matchStatus);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                color: AppColors.brand,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.leagueName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      status.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: _Team(team: card.homeTeam, logoUrl: homeLogoUrl),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Column(
                        children: [
                          Text(
                            card.hasScore
                                ? '${card.homeScore} : ${card.awayScore}'
                                : _time(card.matchTime),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: status.color,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          if (card.hasScore && card.matchTime != null)
                            Text(
                              _time(card.matchTime),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _Team(team: card.awayTeam, logoUrl: awayLogoUrl),
                    ),
                  ],
                ),
              ),
              if (card.eventSummary?.isNotEmpty == true)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  color: AppColors.surfaceMuted,
                  child: Text(
                    card.eventSummary!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Team extends StatelessWidget {
  const _Team({required this.team, this.logoUrl});
  final FeedTeam team;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppTeamLogo(
        identity: 'team:${team.teamId ?? team.teamName}',
        name: team.teamName,
        imageUrl: logoUrl,
        size: 44,
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        team.teamName,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    ],
  );
}

({String label, Color color}) _status(String raw) => switch (raw) {
  'LIVE' => (label: '进行中', color: AppColors.error),
  'FINISHED' => (label: '已结束', color: AppColors.brand),
  'SCHEDULED' => (label: '未开始', color: AppColors.success),
  _ => (label: raw, color: AppColors.inkMuted),
};

String _time(DateTime? value) {
  if (value == null) return '时间待定';
  return '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
