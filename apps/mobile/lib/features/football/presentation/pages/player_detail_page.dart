import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_content_image.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../../recommendation/domain/recommendation_behavior.dart';
import '../../../recommendation/presentation/recommendation_behavior_dispatcher.dart';
import '../../../user_center/data/user_center_repository.dart';
import '../../domain/football_models.dart';
import '../../domain/match_display_sort.dart';
import '../../domain/player_detail_models.dart';
import '../../domain/team_detail_models.dart';
import '../controllers/football_data_controller.dart';
import '../controllers/football_detail_providers.dart';
import '../controllers/football_rankings_controller.dart';
import '../controllers/player_detail_controllers.dart';
import '../controllers/team_detail_controllers.dart';
import '../widgets/football_widgets.dart';
import 'team_detail_page.dart';

class PlayerDetailPage extends ConsumerStatefulWidget {
  const PlayerDetailPage({
    required this.playerId,
    this.recommendationSource,
    super.key,
  });
  final int playerId;
  final RecommendationSourceContext? recommendationSource;

  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage> {
  int _tab = 0;
  late final PlayerDetailContext _request;
  bool _detailReported = false;

  @override
  void initState() {
    super.initState();
    final ranking = ref.read(footballRankingsControllerProvider).state;
    _request = (
      playerId: widget.playerId,
      leagueId: ranking.selectedLeagueId,
      seasonId: ranking.selectedSeasonId,
      stageId: ranking.selectedStageId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(playerDetailProvider(widget.playerId));
    if (detail.hasValue && !_detailReported) {
      _detailReported = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(recommendationBehaviorDispatcherProvider)
              .record(
                RecommendationBehaviorType.detail,
                widget.recommendationSource,
              );
        }
      });
    }
    return Scaffold(
      backgroundColor: AppColors.page,
      body: detail.when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载球员',
          message: '正在读取球员基础资料…',
        ),
        error: (error, _) => FootballDetailError(
          target: '球员',
          error: error,
          onRetry: () => ref.invalidate(playerDetailProvider(widget.playerId)),
        ),
        data: (player) => Column(
          children: [
            _PlayerHeader(player: player),
            _PlayerTabs(
              selectedIndex: _tab,
              onChanged: (value) => setState(() => _tab = value),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _OverviewTab(request: _request),
                  _ContentsTab(playerId: widget.playerId),
                  _StatsTab(request: _request),
                  _MatchesTab(playerId: widget.playerId),
                  _CareerTab(playerId: widget.playerId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerTabs extends StatelessWidget {
  const _PlayerTabs({required this.selectedIndex, required this.onChanged});
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const _tabs = <(String, String)>[
    ('player_tab_overview', '总览'),
    ('player_tab_contents', '帖子'),
    ('player_tab_stats', '数据'),
    ('player_tab_matches', '比赛'),
    ('player_tab_career', '生涯'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    color: _playerWine,
    height: 64,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++)
            SizedBox(
              width: 78,
              child: InkWell(
                key: ValueKey(_tabs[i].$1),
                onTap: () => onChanged(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          _tabs[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: i == selectedIndex
                                ? Colors.white
                                : Colors.white.withValues(alpha: .58),
                            fontSize: 16,
                            fontWeight: i == selectedIndex
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        if (i == 1)
                          const Opacity(opacity: 0, child: Text('动态')),
                      ],
                    ),
                    const SizedBox(height: 9),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 3,
                      width: i == selectedIndex ? 30 : 0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

const _playerWine = Color(0xFFA0144A);

class _PlayerHeader extends ConsumerStatefulWidget {
  const _PlayerHeader({required this.player});
  final PlayerDetail player;

  @override
  ConsumerState<_PlayerHeader> createState() => _PlayerHeaderState();
}

class _PlayerHeaderState extends ConsumerState<_PlayerHeader> {
  late bool _followed = widget.player.followed;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy || widget.player.id <= 0) return;
    setState(() => _busy = true);
    try {
      final followed = await ref
          .read(userCenterRepositoryProvider)
          .toggleEntity('PLAYER', widget.player.id);
      if (mounted) setState(() => _followed = followed);
    } on AppNetworkException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(footballErrorMessage(error, target: '关注'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.player.team;
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      color: _playerWine,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        MediaQuery.paddingOf(context).top + AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: '返回',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 42,
                  height: 42,
                ),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/app/data'),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const Spacer(),
              FilledButton(
                key: const ValueKey('player_follow'),
                onPressed: _busy || widget.player.id <= 0 ? null : _toggle,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white, width: 1.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 7,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: Text(_followed ? '已关注' : '关注'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppPlayerAvatar(
                identity: 'player:${widget.player.id}',
                name: widget.player.name,
                imageUrl: resolveMediaUrl(
                  ref.watch(appConfigProvider),
                  widget.player.avatarUrl,
                ),
                size: width < 380 ? 68 : 78,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_positionLabel(widget.player.position)} / ${_number(widget.player.age)}岁',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    if (team case final currentTeam?) ...[
                      const SizedBox(height: 8),
                      _PlayerClubChip(team: currentTeam, ref: ref),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerClubChip extends StatelessWidget {
  const _PlayerClubChip({required this.team, required this.ref});
  final PlayerTeam team;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTeamLogo(
            identity: 'team:${team.id}',
            name: team.name,
            imageUrl: resolveMediaUrl(
              ref.read(appConfigProvider),
              team.logoUrl,
            ),
            size: 24,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    ),
  );
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.request});
  final PlayerDetailContext request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(playerTeamsV1Provider(request.playerId));
    return ref
        .watch(playerOverviewV1Provider(request))
        .when(
          loading: () => const AppStateView(
            kind: AppStateKind.loading,
            title: '正在加载球员总览',
            message: '正在读取俱乐部和国家队信息…',
          ),
          error: (error, _) => FootballDetailError(
            target: '球员总览',
            error: error,
            onRetry: () => ref.invalidate(playerOverviewV1Provider(request)),
          ),
          data: (player) => SingleChildScrollView(
            key: const PageStorageKey('player_overview'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyedSubtree(
                  key: const ValueKey('player_overview_team_pair'),
                  child: _TeamPairCard(player: player),
                ),
                const SizedBox(height: AppSpacing.sm),
                KeyedSubtree(
                  key: const ValueKey('player_overview_personal'),
                  child: _PersonalCard(player: player),
                ),
                const SizedBox(height: AppSpacing.sm),
                KeyedSubtree(
                  key: const ValueKey('player_overview_career'),
                  child: _CareerTimelineCard(value: teams),
                ),
                const SizedBox(height: AppSpacing.sm),
                const KeyedSubtree(
                  key: ValueKey('player_overview_ability'),
                  child: _UnavailableCard(
                    title: '能力值',
                    message: '暂无能力值数据',
                    icon: Icons.radar_outlined,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const KeyedSubtree(
                  key: ValueKey('player_overview_honors'),
                  child: _UnavailableCard(
                    title: '球员荣誉',
                    message: '暂无球员荣誉数据',
                    icon: Icons.emoji_events_outlined,
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

class _TeamPairCard extends ConsumerWidget {
  const _TeamPairCard({required this.player});
  final PlayerOverview player;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
    children: [
      Expanded(
        child: _TeamLinkCard(
          title: '俱乐部',
          team: player.club,
          emptyMessage: '暂无俱乐部信息',
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: _TeamLinkCard(
          title: '国家队',
          team: player.nationalTeam,
          emptyMessage: '暂无国家队信息',
        ),
      ),
    ],
  );
}

class _PersonalCard extends StatelessWidget {
  const _PersonalCard({required this.player});
  final PlayerOverview player;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('个人资料', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = (constraints.maxWidth - AppSpacing.sm * 2) / 3;
              final facts = [
                _fact('位置', _positionLabel(player.position)),
                _fact('国籍', player.nationality),
                _fact('生日', _date(player.birthDate)),
                _fact('年龄', _number(player.age)),
                _fact('身高', _withUnit(player.height, 'cm')),
                _fact('体重', _withUnit(player.weight, 'kg')),
                _fact('惯用脚', player.preferredFoot),
                _fact('号码', _number(player.shirtNumber)),
                _fact('身份', player.retired ? '已退役' : '现役'),
                if (player.captain) _fact('队内身份', '队长'),
              ];
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final fact in facts)
                    SizedBox(width: cellWidth, height: 58, child: fact),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

Widget _fact(String label, String? value) => SizedBox(
  width: double.infinity,
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        value?.trim().isNotEmpty == true ? value! : '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      Text(
        label,
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
      ),
    ],
  ),
);

class _TeamLinkCard extends ConsumerWidget {
  const _TeamLinkCard({
    required this.title,
    required this.team,
    this.emptyMessage,
  });
  final String title;
  final PlayerTeamLink? team;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: team == null ? null : ValueKey('player_team_${team!.id}'),
      onTap: team != null && team!.id > 0
          ? () => context.push('/teams/${team!.id}')
          : null,
      child: SizedBox(
        height: 94,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: team == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag_outlined, color: AppColors.inkMuted),
                    Text(title, style: const TextStyle(fontSize: 13)),
                    Text(
                      emptyMessage ?? '暂无信息',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    AppTeamLogo(
                      identity: 'team:${team!.id}',
                      name: team!.name,
                      imageUrl: resolveMediaUrl(
                        ref.watch(appConfigProvider),
                        team!.logoUrl,
                      ),
                      size: 42,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            team!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (team!.rawType?.trim().isNotEmpty == true)
                            Text(
                              team!.rawType!,
                              style: const TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}

class _CareerTimelineCard extends ConsumerWidget {
  const _CareerTimelineCard({required this.value});
  final AsyncValue<List<PlayerTeamHistory>> value;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: value.when(
        loading: () => const _CompactState(message: '正在读取效力经历…'),
        error: (_, _) => const _CompactState(message: '效力经历暂不可用'),
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('效力经历', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xs),
            if (items.isEmpty)
              const _CompactState(message: '暂无效力经历')
            else
              for (final item in _uniqueHistory(items))
                Row(
                  children: [
                    AppTeamLogo(
                      identity: 'team:${item.teamId}',
                      name: item.teamName,
                      imageUrl: resolveMediaUrl(
                        ref.watch(appConfigProvider),
                        item.teamLogoUrl,
                      ),
                      size: 36,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${item.teamName}\n${item.seasonName ?? _date(item.startDate)} - ${item.endDate == null ? '现在' : _date(item.endDate)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _number(item.shirtNumber),
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                ),
          ],
        ),
      ),
    ),
  );
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.inkMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(message, style: const TextStyle(color: AppColors.inkMuted)),
        ],
      ),
    ),
  );
}

class _CompactState extends StatelessWidget {
  const _CompactState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) =>
      Text(message, style: const TextStyle(color: AppColors.inkMuted));
}

class _StatsTab extends ConsumerStatefulWidget {
  const _StatsTab({required this.request});
  final PlayerDetailContext request;

  @override
  ConsumerState<_StatsTab> createState() => _StatsTabState();
}

enum _StatsMode { total, average }

class _StatsTabState extends ConsumerState<_StatsTab> {
  var _selectedIndex = 0;
  var _mode = _StatsMode.total;

  @override
  Widget build(BuildContext context) => ref
      .watch(playerStatsV1Provider(widget.request))
      .when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载球员数据',
          message: '正在读取赛季统计…',
        ),
        error: (error, _) => FootballDetailError(
          target: '球员数据',
          error: error,
          onRetry: () => ref.invalidate(playerStatsV1Provider(widget.request)),
        ),
        data: (stats) {
          final visible = stats.where((value) => value.hasData).toList();
          if (visible.isEmpty) {
            return const AppStateView(
              kind: AppStateKind.empty,
              title: '暂无球员数据',
              message: '当前赛季或阶段没有可展示的统计。',
            );
          }
          final index = _selectedIndex.clamp(0, visible.length - 1);
          final selected = visible[index];
          final canAverage = (selected.appearances ?? 0) > 0;
          return ListView(
            key: const PageStorageKey('player_stats'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xxl,
            ),
            children: [
              _StatsSelector(
                stats: visible,
                selectedIndex: index,
                onChanged: (value) => setState(() => _selectedIndex = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              _StatsSummary(stats: selected, mode: _mode),
              const SizedBox(height: AppSpacing.sm),
              _StatsModeToggle(
                mode: _mode,
                enabled: canAverage,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
              const SizedBox(height: AppSpacing.sm),
              _StatsGroup(
                title: '进攻',
                rows: [
                  _row('进球', selected.goals, selected),
                  _row('射门', selected.shots, selected),
                  _row('射正', selected.shotsOnTarget, selected),
                  _row('射正率', selected.shotAccuracy, selected, percent: true),
                ],
              ),
              if (selected.assists != null || selected.rating != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _StatsGroup(
                  title: '组织',
                  rows: [
                    _row('助攻', selected.assists, selected),
                    _row('评分', selected.rating, selected, digits: 2),
                  ],
                ),
              ],
              if (selected.yellowCards != null ||
                  selected.redCards != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _StatsGroup(
                  title: '纪律',
                  rows: [
                    _row('黄牌', selected.yellowCards, selected),
                    _row('红牌', selected.redCards, selected),
                  ],
                ),
              ],
              if (selected.saves != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _StatsGroup(
                  title: '门将',
                  rows: [_row('扑救', selected.saves, selected)],
                ),
              ],
            ],
          );
        },
      );

  _PlayerStatValue _row(
    String label,
    num? value,
    PlayerSeasonStats stats, {
    bool percent = false,
    int digits = 0,
  }) => _PlayerStatValue(
    label: label,
    value: _statValue(
      value,
      stats.appearances,
      _mode,
      percent: percent,
      digits: digits,
    ),
    progress: percent && value != null && value.isFinite
        ? (value / 100).clamp(0, 1).toDouble()
        : null,
  );
}

class _StatsSelector extends StatelessWidget {
  const _StatsSelector({
    required this.stats,
    required this.selectedIndex,
    required this.onChanged,
  });
  final List<PlayerSeasonStats> stats;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = stats[selectedIndex];
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        key: const ValueKey('player_stats_selector'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: stats.length < 2
            ? null
            : () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (_) => SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (var i = 0; i < stats.length; i++)
                        ListTile(
                          title: Text(_statsContext(stats[i])),
                          trailing: i == selectedIndex
                              ? const Icon(Icons.check, color: AppColors.brand)
                              : null,
                          onTap: () {
                            Navigator.of(context).pop();
                            onChanged(i);
                          },
                        ),
                    ],
                  ),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              const Icon(Icons.sports_soccer, color: AppColors.brand),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _statsContext(selected),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (stats.length > 1)
                const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.stats, required this.mode});
  final PlayerSeasonStats stats;
  final _StatsMode mode;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        runSpacing: AppSpacing.lg,
        children: [
          _summaryMetric(
            '进球',
            _statValue(stats.goals, stats.appearances, mode),
          ),
          _summaryMetric(
            '助攻',
            _statValue(stats.assists, stats.appearances, mode),
          ),
          _summaryMetric(
            '比赛',
            _statValue(stats.appearances, stats.appearances, mode),
          ),
          _summaryMetric(
            '首发',
            _statValue(stats.starts, stats.appearances, mode),
          ),
          _summaryMetric(
            '上场时间',
            _statValue(stats.minutes, stats.appearances, mode),
          ),
          _summaryMetric(
            '扑救',
            _statValue(stats.saves, stats.appearances, mode),
          ),
        ],
      ),
    ),
  );
}

Widget _summaryMetric(String label, String value) => SizedBox(
  width: 92,
  child: Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      Text(
        label,
        style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
      ),
    ],
  ),
);

class _StatsModeToggle extends StatelessWidget {
  const _StatsModeToggle({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });
  final _StatsMode mode;
  final bool enabled;
  final ValueChanged<_StatsMode> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      children: [
        _modeButton('总计', _StatsMode.total, true),
        _modeButton('场均', _StatsMode.average, enabled),
      ],
    ),
  );

  Widget _modeButton(String label, _StatsMode target, bool active) => Expanded(
    child: FilledButton(
      onPressed: active ? () => onChanged(target) : null,
      style: FilledButton.styleFrom(
        backgroundColor: mode == target ? AppColors.brand : Colors.transparent,
        foregroundColor: mode == target ? Colors.white : AppColors.inkMuted,
        disabledBackgroundColor: Colors.transparent,
        disabledForegroundColor: AppColors.inkMuted.withValues(alpha: .45),
        elevation: 0,
      ),
      child: Text(label),
    ),
  );
}

class _StatsGroup extends StatelessWidget {
  const _StatsGroup({required this.title, required this.rows});
  final String title;
  final List<_PlayerStatValue> rows;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          for (final row in rows) _StatsRow(row: row),
        ],
      ),
    ),
  );
}

class _PlayerStatValue {
  const _PlayerStatValue({
    required this.label,
    required this.value,
    this.progress,
  });
  final String label;
  final String value;
  final double? progress;
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.row});
  final _PlayerStatValue row;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(row.label)),
            Text(
              row.value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (row.progress != null) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: row.progress,
            minHeight: 5,
            borderRadius: BorderRadius.circular(5),
            color: AppColors.brand,
            backgroundColor: AppColors.border,
          ),
        ],
        const Divider(height: 1),
      ],
    ),
  );
}

class _MatchesTab extends ConsumerStatefulWidget {
  const _MatchesTab({required this.playerId});
  final int playerId;

  @override
  ConsumerState<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<_MatchesTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(playerMatchesV1ControllerProvider(widget.playerId))
          .loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      playerMatchesV1ControllerProvider(widget.playerId),
    );
    return _pagedBody(
      state: controller.state,
      title: '比赛',
      onRetry: controller.loadInitial,
      onLoadMore: controller.loadMore,
      onRefresh: controller.refresh,
      children: _matchChildren(controller.state.records, showFavorite: false),
    );
  }
}

class _ContentsTab extends ConsumerStatefulWidget {
  const _ContentsTab({required this.playerId});
  final int playerId;

  @override
  ConsumerState<_ContentsTab> createState() => _ContentsTabState();
}

class _ContentsTabState extends ConsumerState<_ContentsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(playerContentsV1ControllerProvider(widget.playerId))
          .loadInitial(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      playerContentsV1ControllerProvider(widget.playerId),
    );
    return _pagedBody(
      state: controller.state,
      title: '动态',
      onRetry: controller.loadInitial,
      onLoadMore: controller.loadMore,
      onRefresh: controller.refresh,
      children: _contentChildren(context, controller.state.records),
    );
  }
}

class _ContentCard extends ConsumerWidget {
  const _ContentCard({required this.content});
  final TeamContentSummary content;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('player_content_${content.id}'),
      onTap: content.id > 0
          ? () => context.push('/contents/${content.id}')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.coverUrl?.trim().isNotEmpty == true)
            AppContentImage(
              imageUrl: resolveMediaUrl(
                ref.watch(appConfigProvider),
                content.coverUrl,
              ),
              aspectRatio: 1.35,
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (content.summary?.trim().isNotEmpty == true)
                  Text(
                    content.summary!.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _contentTypeLabel(content.rawType),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        '${content.likeCount} 赞 · ${content.commentCount} 评论',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: AppColors.inkMuted),
                      ),
                    ),
                  ],
                ),
                if (content.publishTime != null)
                  Text(
                    _date(content.publishTime),
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CareerTab extends ConsumerStatefulWidget {
  const _CareerTab({required this.playerId});
  final int playerId;

  @override
  ConsumerState<_CareerTab> createState() => _CareerTabState();
}

class _CareerTabState extends ConsumerState<_CareerTab> {
  var _view = _CareerView.team;

  @override
  Widget build(BuildContext context) {
    final career = ref.watch(playerCareerV1Provider(widget.playerId));
    final teams = ref.watch(playerTeamsV1Provider(widget.playerId));
    return ListView(
      key: const PageStorageKey('player_career'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _AsyncCareerSection(
          value: career,
          title: '职业生涯',
          onRetry: () =>
              ref.invalidate(playerCareerV1Provider(widget.playerId)),
          builder: (value) => [
            if (value.byTeam.isNotEmpty || value.bySeason.isNotEmpty) ...[
              KeyedSubtree(
                key: const ValueKey('player_career_toggle'),
                child: _CareerToggle(
                  view: _view,
                  onChanged: (view) => setState(() => _view = view),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _CareerTableCard(
                career: value,
                teams: teams,
                view: _view,
                onRetryTeams: () =>
                    ref.invalidate(playerTeamsV1Provider(widget.playerId)),
              ),
              const SizedBox(height: AppSpacing.md),
              const _NationalCareerEmptyState(),
            ],
          ],
        ),
        if (career.hasError ||
            career.isLoading ||
            (career.hasValue &&
                career.value!.byTeam.isEmpty &&
                career.value!.bySeason.isEmpty))
          _CareerTeamsFallback(
            value: teams,
            onRetry: () =>
                ref.invalidate(playerTeamsV1Provider(widget.playerId)),
          ),
      ],
    );
  }
}

enum _CareerView { team, season }

class _AsyncCareerSection extends StatelessWidget {
  const _AsyncCareerSection({
    required this.value,
    required this.title,
    required this.onRetry,
    required this.builder,
  });
  final AsyncValue<PlayerCareer> value;
  final String title;
  final VoidCallback onRetry;
  final List<Widget> Function(PlayerCareer value) builder;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => _subsectionState(
      title,
      key: const ValueKey('player_career_state'),
      loading: true,
    ),
    error: (error, _) => _subsectionState(
      title,
      key: const ValueKey('player_career_state'),
      retryKey: const ValueKey('player_career_retry'),
      message: _errorText(error),
      onRetry: onRetry,
    ),
    data: (career) =>
        career.hasData || career.byTeam.isNotEmpty || career.bySeason.isNotEmpty
        ? Column(
            key: const ValueKey('player_career_state'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: builder(career),
          )
        : _subsectionState(
            title,
            key: const ValueKey('player_career_state'),
            message: '暂无生涯总计',
          ),
  );
}

class _CareerTableCard extends StatelessWidget {
  const _CareerTableCard({
    required this.career,
    required this.teams,
    required this.view,
    required this.onRetryTeams,
  });
  final PlayerCareer career;
  final AsyncValue<List<PlayerTeamHistory>> teams;
  final _CareerView view;
  final VoidCallback onRetryTeams;

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('player_career_table'),
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CareerColumnHeader(),
          const SizedBox(height: AppSpacing.xs),
          if (view == _CareerView.team)
            _CareerTeamRows(
              value: teams,
              fallback: career.byTeam,
              onRetry: onRetryTeams,
            )
          else
            ...career.bySeason.map((group) => _CareerGroupTile(group: group)),
        ],
      ),
    ),
  );
}

class _NationalCareerEmptyState extends StatelessWidget {
  const _NationalCareerEmptyState();

  @override
  Widget build(BuildContext context) => const Card(
    key: ValueKey('player_national_career_state'),
    color: Colors.white,
    margin: EdgeInsets.zero,
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('国家队生涯', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: AppSpacing.xs),
          Text('暂无国家队生涯数据'),
        ],
      ),
    ),
  );
}

class _CareerTeamRows extends StatelessWidget {
  const _CareerTeamRows({
    required this.value,
    required this.fallback,
    required this.onRetry,
  });
  final AsyncValue<List<PlayerTeamHistory>> value;
  final List<PlayerCareerGroup> fallback;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => _subsectionState(
      '效力球队',
      key: const ValueKey('player_teams_state'),
      loading: true,
    ),
    error: (error, _) => _subsectionState(
      '效力球队',
      key: const ValueKey('player_teams_state'),
      retryKey: const ValueKey('player_teams_retry'),
      message: _errorText(error),
      onRetry: onRetry,
    ),
    data: (history) => KeyedSubtree(
      key: const ValueKey('player_teams_state'),
      child: history.isEmpty
          ? Column(
              children: [
                for (final group in fallback) _CareerGroupTile(group: group),
                const _CompactState(message: '暂无效力补充信息'),
              ],
            )
          : Column(
              children: [
                for (final item in _uniqueHistory(history))
                  _CareerHistoryRow(history: item),
              ],
            ),
    ),
  );
}

class _CareerTeamsFallback extends StatelessWidget {
  const _CareerTeamsFallback({required this.value, required this.onRetry});
  final AsyncValue<List<PlayerTeamHistory>> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => _subsectionState(
      '效力球队',
      key: const ValueKey('player_teams_state'),
      loading: true,
    ),
    error: (error, _) => _subsectionState(
      '效力球队',
      key: const ValueKey('player_teams_state'),
      retryKey: const ValueKey('player_teams_retry'),
      message: _errorText(error),
      onRetry: onRetry,
    ),
    data: (history) => Card(
      key: const ValueKey('player_teams_state'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: history.isEmpty
            ? const Text('暂无历史效力球队')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '效力球队',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  for (final item in _uniqueHistory(history))
                    _HistoryTile(history: item),
                ],
              ),
      ),
    ),
  );
}

Widget _subsectionState(
  String title, {
  Key? key,
  bool loading = false,
  String? message,
  VoidCallback? onRetry,
  Key? retryKey,
}) => Card(
  key: key,
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: loading
        ? Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              const CircularProgressIndicator(),
            ],
          )
        : Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(message ?? '暂无数据'),
              if (onRetry != null)
                TextButton(
                  key: retryKey,
                  onPressed: onRetry,
                  child: const Text('重试'),
                ),
            ],
          ),
  ),
);

class _CareerToggle extends StatelessWidget {
  const _CareerToggle({required this.view, required this.onChanged});
  final _CareerView view;
  final ValueChanged<_CareerView> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      children: [
        _button('球队', _CareerView.team),
        _button('赛季', _CareerView.season),
      ],
    ),
  );

  Widget _button(String label, _CareerView target) => Expanded(
    child: FilledButton(
      onPressed: () => onChanged(target),
      style: FilledButton.styleFrom(
        backgroundColor: view == target ? AppColors.brand : Colors.transparent,
        foregroundColor: view == target ? Colors.white : AppColors.inkMuted,
        elevation: 0,
      ),
      child: Text(label),
    ),
  );
}

class _CareerGroupTile extends StatelessWidget {
  const _CareerGroupTile({required this.group});
  final PlayerCareerGroup group;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        _careerValue(group.appearances),
        _careerValue(group.goals),
        _careerValue(group.assists),
      ],
    ),
  );
}

class _CareerColumnHeader extends StatelessWidget {
  const _CareerColumnHeader();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(child: Text('高级职业生涯')),
        SizedBox(width: 48, child: Text('出场', textAlign: TextAlign.center)),
        SizedBox(width: 48, child: Text('进球', textAlign: TextAlign.center)),
        SizedBox(width: 48, child: Text('助攻', textAlign: TextAlign.center)),
      ],
    ),
  );
}

Widget _careerValue(num? value) => SizedBox(
  width: 48,
  child: Text(
    _display(value),
    textAlign: TextAlign.center,
    style: const TextStyle(fontWeight: FontWeight.w600),
  ),
);

class _CareerHistoryRow extends ConsumerWidget {
  const _CareerHistoryRow({required this.history});
  final PlayerTeamHistory history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = [
      if (history.seasonName?.trim().isNotEmpty == true) history.seasonName!,
      if (history.current) '当前效力',
      if (history.loan) '租借',
      if (history.startDate != null || history.endDate != null)
        '${_date(history.startDate)} - ${history.endDate == null ? '现在' : _date(history.endDate)}',
      if (history.shirtNumber != null) '${history.shirtNumber} 号',
      if (history.position?.trim().isNotEmpty == true &&
          history.position != '租借')
        history.position!,
      if (history.appearances != null) '出场 ${history.appearances}',
      if (history.goals != null) '进球 ${history.goals}',
      if (history.assists != null) '助攻 ${history.assists}',
    ].join(' · ');
    return ListTile(
      key: ValueKey('career_team_${history.teamId}_${history.seasonId}'),
      contentPadding: EdgeInsets.zero,
      onTap: history.teamId > 0
          ? () => context.push('/teams/${history.teamId}')
          : null,
      leading: AppTeamLogo(
        identity: 'team:${history.teamId}',
        name: history.teamName,
        imageUrl: resolveMediaUrl(
          ref.watch(appConfigProvider),
          history.teamLogoUrl,
        ),
        size: 38,
      ),
      title: Text(history.teamName),
      subtitle: Text(
        subtitle.isEmpty ? '暂无效力时间' : subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _careerValue(history.appearances),
          _careerValue(history.goals),
          _careerValue(history.assists),
        ],
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.history});
  final PlayerTeamHistory history;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = history.position?.trim();
    final positionIsLoanMarker = position == '租借';
    return ListTile(
      key: ValueKey('career_team_${history.teamId}_${history.seasonId}'),
      onTap: history.teamId > 0
          ? () => context.push('/teams/${history.teamId}')
          : null,
      leading: AppTeamLogo(
        identity: 'team:${history.teamId}',
        name: history.teamName,
        imageUrl: resolveMediaUrl(
          ref.watch(appConfigProvider),
          history.teamLogoUrl,
        ),
        size: 42,
      ),
      title: Text(history.teamName),
      subtitle: Text(
        [
          if (history.seasonName?.trim().isNotEmpty == true)
            history.seasonName!,
          if (history.current) '当前效力',
          if (history.loan) '租借',
          if (history.startDate != null || history.endDate != null)
            '${_date(history.startDate)} - ${history.endDate == null ? '现在' : _date(history.endDate)}',
          if (history.shirtNumber != null) '${history.shirtNumber} 号',
          if (position?.isNotEmpty == true && !positionIsLoanMarker) position!,
          if (history.appearances != null) '出场 ${history.appearances}',
          if (history.goals != null) '进球 ${history.goals}',
          if (history.assists != null) '助攻 ${history.assists}',
        ].join(' · '),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

Widget _pagedBody<T>({
  required TeamPagedState<T> state,
  required String title,
  required VoidCallback onRetry,
  required VoidCallback onLoadMore,
  required Future<void> Function() onRefresh,
  required List<Widget> children,
}) => switch (state.status) {
  TeamPagedStatus.loading => AppStateView(
    kind: AppStateKind.loading,
    title: '正在加载$title',
    message: '正在读取真实数据…',
  ),
  TeamPagedStatus.failure => AppStateView(
    kind: AppStateKind.error,
    title: '$title加载失败',
    message: state.message ?? '请稍后重试。',
    onRetry: onRetry,
  ),
  TeamPagedStatus.empty => AppStateView(
    kind: AppStateKind.empty,
    title: '暂无$title',
    message: '当前没有可展示的数据。',
    onRetry: onRetry,
  ),
  TeamPagedStatus.ready => NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification.metrics.extentAfter < 320) onLoadMore();
      return false;
    },
    child: RefreshIndicator(
      key: ValueKey('player_refresh_$title'),
      onRefresh: onRefresh,
      child: ListView(
        key: PageStorageKey('player_$title'),
        padding: EdgeInsets.zero,
        children: [
          if (state.message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Material(
                color: AppColors.error.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.message!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(onPressed: onRefresh, child: const Text('重试')),
                    ],
                  ),
                ),
              ),
            ),
          ...children,
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: state.loadingMore
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : state.appendMessage != null
                  ? TextButton(
                      onPressed: onLoadMore,
                      child: Text('${state.appendMessage} 点击重试'),
                    )
                  : Text(
                      state.hasMore ? '继续上滑加载' : '已经到底了',
                      style: const TextStyle(color: AppColors.inkMuted),
                    ),
            ),
          ),
        ],
      ),
    ),
  ),
};

List<Widget> _matchChildren(
  Iterable<FootballMatch> values, {
  bool showFavorite = true,
}) {
  final children = <Widget>[];
  DateTime? lastDate;
  var hasDateGroup = false;
  for (final match in sortMatchesForDisplay(values)) {
    final date = match.matchTime == null
        ? null
        : DateTime(
            match.matchTime!.year,
            match.matchTime!.month,
            match.matchTime!.day,
          );
    if (!hasDateGroup || date != lastDate) {
      children.add(
        Padding(
          key: ValueKey(
            hasDateGroup
                ? 'player_match_date_${date?.toIso8601String() ?? 'unknown'}'
                : 'player_match_date_first',
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Text(
            date == null ? '日期待定' : footballDate(date),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
      lastDate = date;
      hasDateGroup = true;
    }
    children.add(
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: ScheduleMatchCard(match: match, showFavorite: showFavorite),
      ),
    );
  }
  return children;
}

List<Widget> _contentChildren(
  BuildContext context,
  List<TeamContentSummary> values,
) {
  final narrow =
      MediaQuery.sizeOf(context).width < 380 ||
      MediaQuery.textScalerOf(context).scale(1) > 1.2;
  if (narrow) return [for (final value in values) _ContentCard(content: value)];
  final left = <Widget>[];
  final right = <Widget>[];
  for (final entry in values.indexed) {
    (entry.$1.isEven ? left : right).add(_ContentCard(content: entry.$2));
  }
  return [
    Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: left)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(children: right)),
        ],
      ),
    ),
  ];
}

List<PlayerTeamHistory> _uniqueHistory(List<PlayerTeamHistory> values) {
  final unique = <String, PlayerTeamHistory>{};
  for (final item in values) {
    unique['${item.teamId}:${item.seasonId}'] = item;
  }
  return unique.values.toList(growable: false);
}

String _statsContext(PlayerSeasonStats stats) {
  final value = [
    stats.leagueName,
    stats.seasonName,
    stats.teamName,
  ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
  return value.isEmpty ? '赛季数据' : value;
}

String _statValue(
  num? value,
  int? appearances,
  _StatsMode mode, {
  bool percent = false,
  int digits = 0,
  String suffix = '',
}) {
  if (value == null || !value.isFinite) return '—';
  if (mode == _StatsMode.average) {
    if (appearances == null || appearances <= 0) return '—';
    value = value / appearances;
  }
  if (percent) {
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}%';
  }
  final text = digits > 0
      ? value.toStringAsFixed(digits)
      : value is double && value.truncateToDouble() != value
      ? value.toStringAsFixed(1)
      : value.toInt().toString();
  return '$text$suffix';
}

String _positionLabel(String? raw) => switch (raw?.trim().toUpperCase()) {
  'GK' || 'GOALKEEPER' => '门将',
  'DF' || 'DEFENDER' => '后卫',
  'MF' || 'MIDFIELDER' => '中场',
  'FW' || 'FORWARD' || 'STRIKER' => '前锋',
  null || '' => '位置未定',
  _ => '其他位置',
};

String _contentTypeLabel(String raw) => switch (raw.trim().toUpperCase()) {
  'ARTICLE' => '文章',
  'POST' => '帖子',
  _ => '动态',
};

String _number(num? value) => value == null ? '—' : _display(value);

String _display(Object? value) {
  if (value is num && !value.isFinite) return '—';
  return value?.toString() ?? '—';
}

String _withUnit(num? value, String unit) =>
    value == null ? '—' : '${_display(value)} $unit';

String _date(DateTime? value) => value == null ? '—' : footballDate(value);

String _errorText(Object error) => error is AppNetworkException
    ? footballErrorMessage(error, target: '球员生涯')
    : '加载失败，请稍后重试。';
