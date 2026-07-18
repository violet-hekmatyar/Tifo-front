import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/football_models.dart';
import '../controllers/football_detail_providers.dart';
import '../widgets/football_widgets.dart';
import 'team_detail_page.dart';

class MatchDetailPage extends ConsumerStatefulWidget {
  const MatchDetailPage({required this.matchId, super.key});
  final int matchId;
  @override
  ConsumerState<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends ConsumerState<MatchDetailPage> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    if (widget.matchId <= 0) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: '返回',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/app/data'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('比赛详情'),
        ),
        body: const AppStateView(
          kind: AppStateKind.error,
          title: '比赛编号无效',
          message: '无法打开该比赛，请返回数据页重新选择。',
        ),
      );
    }
    final async = ref.watch(matchDetailProvider(widget.matchId));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/app/data'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('比赛详情'),
      ),
      body: async.when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载比赛',
          message: '正在读取比分、事件与战报…',
        ),
        error: (error, _) => FootballDetailError(
          target: '比赛',
          error: error,
          onRetry: () => ref.invalidate(matchDetailProvider(widget.matchId)),
        ),
        data: (detail) => Column(
          children: [
            _MatchHeader(detail: detail),
            NavigationBar(
              height: 64,
              selectedIndex: _tab,
              onDestinationSelected: (value) => setState(() => _tab = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.timeline_rounded),
                  label: '概览',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  label: '阵容',
                ),
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined),
                  label: '排名',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  label: '数据',
                ),
              ],
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _MatchOverview(detail: detail),
                  const SingleChildScrollView(
                    child: CapabilityEmpty(
                      title: '暂无比赛阵容',
                      message: '当前后端尚未提供首发与替补阵容接口。',
                    ),
                  ),
                  const SingleChildScrollView(
                    child: CapabilityEmpty(
                      title: '暂无联赛排名',
                      message: '当前后端尚未提供赛事积分榜接口。',
                    ),
                  ),
                  const SingleChildScrollView(
                    child: CapabilityEmpty(
                      title: '暂无比赛统计',
                      message: '当前后端尚未提供控球率、射门等比赛统计接口。',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchHeader extends ConsumerWidget {
  const _MatchHeader({required this.detail});
  final MatchDetail detail;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = detail.match;
    final config = ref.watch(appConfigProvider);
    final status = footballStatus(match.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  match.leagueName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                status.label,
                style: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Text(
            '${footballDate(match.matchTime)} ${footballTime(match.matchTime)}',
            style: const TextStyle(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _HeaderTeam(
                  team: match.homeTeam,
                  imageUrl: resolveMediaUrl(config, match.homeTeam.logoUrl),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  match.homeTeam.score != null && match.awayTeam.score != null
                      ? '${match.homeTeam.score} : ${match.awayTeam.score}'
                      : 'VS',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: _HeaderTeam(
                  team: match.awayTeam,
                  imageUrl: resolveMediaUrl(config, match.awayTeam.logoUrl),
                ),
              ),
            ],
          ),
          if (detail.roundName != null || detail.venue != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              [detail.roundName, detail.venue].whereType<String>().join(' · '),
              style: const TextStyle(color: AppColors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderTeam extends StatelessWidget {
  const _HeaderTeam({required this.team, required this.imageUrl});
  final FootballTeam team;
  final String? imageUrl;
  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('match_team_${team.id}'),
    onTap: () => context.push('/teams/${team.id}'),
    child: Column(
      children: [
        AppTeamLogo(
          identity: 'team:${team.id}',
          name: team.name,
          imageUrl: imageUrl,
          size: 56,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          team.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _MatchOverview extends StatelessWidget {
  const _MatchOverview({required this.detail});
  final MatchDetail detail;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    children: [
      if (detail.report != null)
        Card(
          child: ListTile(
            onTap: () => context.push('/contents/${detail.report!.contentId}'),
            leading: const Icon(Icons.article_outlined),
            title: Text(detail.report!.title),
            subtitle: const Text('查看比赛战报'),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      const SizedBox(height: AppSpacing.lg),
      Text('比赛事件', style: Theme.of(context).textTheme.titleLarge),
      if (detail.events.isEmpty)
        const CapabilityEmpty(title: '暂无比赛事件', message: '本场比赛暂未记录事件。')
      else
        for (final event in detail.events) _EventTile(event: event),
    ],
  );
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final MatchEvent event;
  @override
  Widget build(BuildContext context) {
    final minute = event.extraMinute == null
        ? '${event.minute}′'
        : '${event.minute}+${event.extraMinute}′';
    final type = switch (event.type) {
      'GOAL' => '进球',
      'OWN_GOAL' => '乌龙球',
      'PENALTY_GOAL' => '点球',
      'YELLOW_CARD' => '黄牌',
      'RED_CARD' => '红牌',
      'SUBSTITUTION' => '换人',
      _ => event.type,
    };
    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(minute, style: const TextStyle(fontSize: 12)),
        ),
        title: Text(
          '$type${event.scoreAfter == null ? '' : ' · ${event.scoreAfter}'}',
        ),
        subtitle: Text(
          [
            event.teamName,
            event.playerName,
            if (event.assistPlayerName != null) '助攻 ${event.assistPlayerName}',
            event.description,
            if (event.hasDebate) '存在争议',
          ].whereType<String>().join(' · '),
        ),
        onTap: event.playerId == null
            ? null
            : () => context.push('/players/${event.playerId}'),
        trailing: event.playerId == null
            ? null
            : const Tooltip(
                message: '查看球员详情',
                child: Icon(Icons.person_search_outlined),
              ),
      ),
    );
  }
}
