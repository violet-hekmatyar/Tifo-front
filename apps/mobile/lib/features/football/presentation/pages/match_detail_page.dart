import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/football_models.dart';
import '../../domain/match_detail_models.dart';
import '../controllers/football_detail_providers.dart';
import '../controllers/match_detail_controllers.dart';
import '../controllers/team_detail_controllers.dart';
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
                  label: '当前排名',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  label: '统计',
                ),
                NavigationDestination(
                  icon: Icon(Icons.star_outline_rounded),
                  label: '评分',
                ),
              ],
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _MatchOverview(detail: detail),
                  _LineupsTab(matchId: widget.matchId),
                  _RankingTab(matchId: widget.matchId),
                  _StatsTab(matchId: widget.matchId, detail: detail),
                  _RatingsTab(matchId: widget.matchId, detail: detail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineupsTab extends ConsumerWidget {
  const _LineupsTab({required this.matchId});
  final int matchId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(matchLineupsProvider(matchId))
      .when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载阵容',
          message: '正在读取首发与替补…',
        ),
        error: (error, _) => FootballDetailError(
          target: '比赛阵容',
          error: error,
          onRetry: () => ref.invalidate(matchLineupsProvider(matchId)),
        ),
        data: (value) => !value.hasData
            ? const AppStateView(
                kind: AppStateKind.empty,
                title: '暂无比赛阵容',
                message: '本场比赛暂未公布阵容。',
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (value.home case final team?) _TeamLineupCard(team: team),
                  if (value.away case final team?) _TeamLineupCard(team: team),
                ],
              ),
      );
}

class _TeamLineupCard extends StatelessWidget {
  const _TeamLineupCard({required this.team});
  final MatchTeamLineup team;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(team.teamName, style: Theme.of(context).textTheme.titleLarge),
          Text(
            [team.formation, team.coachName].whereType<String>().join(' · '),
            style: const TextStyle(color: AppColors.inkMuted),
          ),
          if (team.starters.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text('首发', style: TextStyle(fontWeight: FontWeight.w800)),
            for (final player in team.starters)
              _LineupPlayerTile(player: player),
          ],
          if (team.substitutes.isNotEmpty || team.bench.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text('替补', style: TextStyle(fontWeight: FontWeight.w800)),
            for (final player in [...team.substitutes, ...team.bench])
              _LineupPlayerTile(player: player),
          ],
        ],
      ),
    ),
  );
}

class _LineupPlayerTile extends StatelessWidget {
  const _LineupPlayerTile({required this.player});
  final MatchLineupPlayer player;
  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey('lineup_player_${player.playerId}'),
    contentPadding: EdgeInsets.zero,
    onTap: () => context.push('/players/${player.playerId}'),
    leading: CircleAvatar(child: Text(player.shirtNumber?.toString() ?? '—')),
    title: Text('${player.playerName}${player.captain ? '（队长）' : ''}'),
    subtitle: Text(
      [
        player.position,
        if (player.substitutedInMinute != null)
          '${player.substitutedInMinute}′ 替补登场',
        if (player.substitutedOutMinute != null)
          '${player.substitutedOutMinute}′ 被换下',
      ].whereType<String>().join(' · '),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}

class _RankingTab extends ConsumerWidget {
  const _RankingTab({required this.matchId});
  final int matchId;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(matchOverviewV1Provider(matchId))
      .when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载当前排名',
          message: '正在读取赛事积分榜…',
        ),
        error: (error, _) => FootballDetailError(
          target: '当前排名',
          error: error,
          onRetry: () => ref.invalidate(matchOverviewV1Provider(matchId)),
        ),
        data: (overview) {
          final ranking = overview.ranking;
          if (ranking == null || !ranking.available) {
            return const AppStateView(
              kind: AppStateKind.empty,
              title: '暂无当前排名',
              message: '当前赛事没有可展示的积分榜。',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text('当前排名', style: Theme.of(context).textTheme.headlineSmall),
              Text(
                [
                  ranking.leagueName,
                  ranking.seasonName,
                  ranking.stageName,
                ].whereType<String>().join(' · '),
                style: const TextStyle(color: AppColors.inkMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              if (ranking.home case final row?) _StandingCard(value: row),
              if (ranking.away case final row?) _StandingCard(value: row),
            ],
          );
        },
      );
}

class _StandingCard extends StatelessWidget {
  const _StandingCard({required this.value});
  final MatchStandingSnapshot value;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: () => context.push('/teams/${value.teamId}'),
      leading: CircleAvatar(child: Text(value.rank?.toString() ?? '—')),
      title: Text(value.teamName),
      subtitle: Text(
        '赛 ${value.played ?? '—'} · 胜 ${value.won ?? '—'} · 平 ${value.drawn ?? '—'} · 负 ${value.lost ?? '—'}',
      ),
      trailing: Text(
        '${value.points ?? '—'} 分',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _StatsTab extends ConsumerStatefulWidget {
  const _StatsTab({required this.matchId, required this.detail});
  final int matchId;
  final MatchDetail detail;
  @override
  ConsumerState<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<_StatsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(matchPlayerStatsControllerProvider(widget.matchId))
          .loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamStats = ref.watch(matchTeamStatsProvider(widget.matchId));
    final players = ref.watch(
      matchPlayerStatsControllerProvider(widget.matchId),
    );
    if (teamStats.isLoading ||
        players.state.status == TeamPagedStatus.loading) {
      return const AppStateView(
        kind: AppStateKind.loading,
        title: '正在加载比赛统计',
        message: '正在读取球队和球员数据…',
      );
    }
    if (teamStats.hasError || players.state.status == TeamPagedStatus.failure) {
      return AppStateView(
        kind: AppStateKind.error,
        title: '比赛统计加载失败',
        message: players.state.message ?? '请稍后重试。',
        onRetry: () {
          ref.invalidate(matchTeamStatsProvider(widget.matchId));
          players.loadInitial();
        },
      );
    }
    final stats = teamStats.value ?? const <MatchTeamStatItem>[];
    if (stats.isEmpty && players.state.records.isEmpty) {
      return const AppStateView(
        kind: AppStateKind.empty,
        title: '暂无比赛统计',
        message: '本场比赛暂无球队或球员统计。',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (stats.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.detail.match.homeTeam.name,
                  textAlign: TextAlign.center,
                ),
              ),
              const Expanded(child: Text('球队统计', textAlign: TextAlign.center)),
              Expanded(
                child: Text(
                  widget.detail.match.awayTeam.name,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          for (final item in stats) _TeamStatRow(item: item),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (players.state.records.isNotEmpty)
          Text('球员统计', style: Theme.of(context).textTheme.titleLarge),
        for (final player in players.state.records)
          _PlayerStatTile(player: player),
        if (players.state.hasMore)
          TextButton(
            onPressed: players.state.loadingMore ? null : players.loadMore,
            child: Text(players.state.loadingMore ? '加载中…' : '加载更多'),
          ),
        if (players.state.appendMessage != null)
          TextButton(
            onPressed: players.loadMore,
            child: Text('${players.state.appendMessage}，点击重试'),
          ),
      ],
    );
  }
}

String _displayStat(Object? value, String? unit) =>
    value == null ? '—' : '$value${unit ?? ''}';

class _TeamStatRow extends StatelessWidget {
  const _TeamStatRow({required this.item});
  final MatchTeamStatItem item;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(
            _displayStat(item.homeValue, item.unit),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(child: Text(item.displayName, textAlign: TextAlign.center)),
        Expanded(
          child: Text(
            _displayStat(item.awayValue, item.unit),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _PlayerStatTile extends StatelessWidget {
  const _PlayerStatTile({required this.player});
  final MatchPlayerStat player;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: ValueKey('stat_player_${player.playerId}'),
      onTap: () => context.push('/players/${player.playerId}'),
      title: Text(player.playerName),
      subtitle: Text(
        '${player.teamName ?? '球队'} · ${player.minutes ?? '—'} 分钟 · ${player.goals ?? '—'} 球 · ${player.assists ?? '—'} 助攻',
      ),
      trailing: Text(
        player.officialRating?.toStringAsFixed(1) ?? '—',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _RatingsTab extends ConsumerStatefulWidget {
  const _RatingsTab({required this.matchId, required this.detail});
  final int matchId;
  final MatchDetail detail;
  @override
  ConsumerState<_RatingsTab> createState() => _RatingsTabState();
}

class _RatingsTabState extends ConsumerState<_RatingsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(matchRatingsControllerProvider(widget.matchId)).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      matchRatingsControllerProvider(widget.matchId),
    );
    final state = controller.state;
    if (state.status == MatchRatingsStatus.loading) {
      return const AppStateView(
        kind: AppStateKind.loading,
        title: '正在加载球员评分',
        message: '正在读取官方和用户评分…',
      );
    }
    if (state.status == MatchRatingsStatus.failure) {
      return AppStateView(
        kind: AppStateKind.error,
        title: '球员评分加载失败',
        message: state.message ?? '请稍后重试。',
        onRetry: controller.load,
      );
    }
    if (state.status == MatchRatingsStatus.empty) {
      return const AppStateView(
        kind: AppStateKind.empty,
        title: '暂无可评分球员',
        message: '仅已出场球员可以评分。',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (state.message != null)
          Card(
            color: AppColors.error.withValues(alpha: 0.08),
            child: ListTile(
              title: Text(state.message!),
              trailing: IconButton(
                onPressed: controller.clearMessage,
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        for (final rating in state.records)
          _RatingTile(
            rating: rating,
            busy: state.busyPlayerId == rating.playerId,
            onRate: () => _chooseRating(context, controller, rating),
            onCancel: rating.currentUserRating == null
                ? null
                : () => controller.cancel(rating.playerId),
          ),
      ],
    );
  }

  Future<void> _chooseRating(
    BuildContext context,
    MatchRatingsController controller,
    MatchRatingSummary rating,
  ) async {
    final basis =
        rating.currentUserRating ??
        rating.averageRating ??
        rating.officialRating ??
        7.0;
    var selected = ((basis.clamp(1.0, 10.0) * 2).round() / 2).toDouble();
    final value = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('为 ${rating.playerName} 评分'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selected.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Slider(
                value: selected,
                min: 1,
                max: 10,
                divisions: 18,
                label: selected.toStringAsFixed(1),
                onChanged: (v) => setDialogState(() => selected = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('提交'),
            ),
          ],
        ),
      ),
    );
    if (value != null) await controller.submit(rating.playerId, value);
  }
}

class _RatingTile extends StatelessWidget {
  const _RatingTile({
    required this.rating,
    required this.busy,
    required this.onRate,
    this.onCancel,
  });
  final MatchRatingSummary rating;
  final bool busy;
  final VoidCallback onRate;
  final VoidCallback? onCancel;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: ValueKey('rating_player_${rating.playerId}'),
      onTap: () => context.push('/players/${rating.playerId}'),
      title: Text(rating.playerName),
      subtitle: Text(
        '官方 ${rating.officialRating?.toStringAsFixed(1) ?? '—'} · 用户 ${rating.averageRating?.toStringAsFixed(1) ?? '—'}（${rating.ratingCount}人）${rating.currentUserRating == null ? '' : ' · 我的 ${rating.currentUserRating!.toStringAsFixed(1)}'}',
      ),
      trailing: busy
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onCancel != null)
                  IconButton(
                    key: ValueKey('cancel_rating_${rating.playerId}'),
                    tooltip: '撤销评分',
                    onPressed: onCancel,
                    icon: const Icon(Icons.undo_rounded),
                  ),
                IconButton(
                  key: ValueKey('rate_player_${rating.playerId}'),
                  tooltip: '提交评分',
                  onPressed: onRate,
                  icon: const Icon(Icons.star_rounded),
                ),
              ],
            ),
    ),
  );
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
