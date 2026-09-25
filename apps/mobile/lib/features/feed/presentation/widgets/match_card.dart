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
      borderRadius: BorderRadius.circular(AppRadius.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                color: AppColors.brandDark,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.leagueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Text(
                        status.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Team(team: card.homeTeam, logoUrl: homeLogoUrl),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Column(
                          children: [
                            Text(
                              card.hasScore
                                  ? '${card.homeScore} : ${card.awayScore}'
                                  : _compactTime(card.matchTime),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: status.color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    height: 1.05,
                                  ),
                            ),
                            if (card.hasScore && card.matchTime != null)
                              Text(
                                _compactTime(card.matchTime),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
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
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  color: AppColors.brandSoft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.event_note_outlined,
                          size: 14,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          card.eventSummary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
        size: 32,
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        team.teamName,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall,
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

String _compactTime(DateTime? value) {
  if (value == null) return '待定';
  return '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}\n'
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
