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
      key: ValueKey('match_card_${card.matchId}'),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF176A61), Color(0xFF064B46)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        card.leagueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      status.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _Team(team: card.homeTeam, logoUrl: homeLogoUrl),
                    ),
                    SizedBox(
                      width: 58,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!card.hasScore && card.matchTime != null) ...[
                            Text(
                              _matchDateLabel(card.matchTime!),
                              key: const ValueKey('match_date_label'),
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .9),
                                fontSize: 10,
                                height: 1.05,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            card.hasScore
                                ? '${card.homeScore} : ${card.awayScore}'
                                : _clock(card.matchTime),
                            key: const ValueKey('match_score_or_clock'),
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: status.color,
                              fontSize: card.hasScore ? 21 : 15,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (card.matchStatus == 'LIVE' &&
                              card.matchTime != null)
                            Text(
                              '比赛进行中',
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .72),
                                fontSize: 8,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _Team(team: card.awayTeam, logoUrl: awayLogoUrl),
                    ),
                  ],
                ),
                if (card.eventSummary?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      card.eventSummary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ],
              ],
            ),
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
    mainAxisSize: MainAxisSize.min,
    children: [
      AppTeamLogo(
        identity: 'team:${team.teamId ?? team.teamName}',
        name: team.teamName,
        imageUrl: logoUrl,
        size: 26,
      ),
      const SizedBox(height: 3),
      Text(
        team.teamName,
        textAlign: TextAlign.center,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 9, height: 1.05),
      ),
    ],
  );
}

({String label, Color color}) _status(String raw) => switch (raw) {
  'LIVE' => (label: '进行中', color: const Color(0xFFFF6B63)),
  'FINISHED' => (label: '已结束', color: Colors.white70),
  'SCHEDULED' => (label: '未开始', color: const Color(0xFF8AE3B4)),
  _ => (label: raw, color: Colors.white70),
};

String _clock(DateTime? value) {
  if (value == null) return '待定';
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

String _matchDateLabel(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final matchDay = DateTime(value.year, value.month, value.day);
  final diff = matchDay.difference(today).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '明天';
  return '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
