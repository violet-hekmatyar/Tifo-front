import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/football_models.dart';
import '../controllers/football_data_controller.dart';
import '../controllers/football_detail_providers.dart';
import '../widgets/football_widgets.dart';

class TeamDetailPage extends ConsumerStatefulWidget {
  const TeamDetailPage({required this.teamId, super.key});
  final int teamId;
  @override
  ConsumerState<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends ConsumerState<TeamDetailPage> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamDetailProvider(widget.teamId));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/app/data'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('球队详情'),
      ),
      body: async.when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载球队',
          message: '正在读取球队资料与赛程…',
        ),
        error: (error, _) => FootballDetailError(
          target: '球队',
          error: error,
          onRetry: () => ref.invalidate(teamDetailProvider(widget.teamId)),
        ),
        data: (team) => Column(
          children: [
            _TeamHeader(team: team),
            NavigationBar(
              height: 64,
              selectedIndex: _tab,
              onDestinationSelected: (value) => setState(() => _tab = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.info_outline),
                  label: '概览',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: '赛程',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  label: '阵容',
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
                  _TeamOverview(team: team),
                  _TeamSchedule(teamId: team.id),
                  const SingleChildScrollView(
                    child: CapabilityEmpty(
                      title: '暂无球队阵容',
                      message: '当前后端尚未提供球队阵容列表接口。',
                    ),
                  ),
                  const SingleChildScrollView(
                    child: CapabilityEmpty(
                      title: '暂无球队统计',
                      message: '当前后端尚未提供球队排名与进阶统计接口。',
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

class _TeamHeader extends ConsumerWidget {
  const _TeamHeader({required this.team});
  final TeamDetail team;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandDark, AppColors.brand],
        ),
      ),
      child: Row(
        children: [
          AppTeamLogo(
            identity: 'team:${team.id}',
            name: team.name,
            imageUrl: resolveMediaUrl(config, team.logoUrl),
            size: 72,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (team.nameEn != null)
                  Text(
                    team.nameEn!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${team.followerCount} 人关注 · ${team.followed ? '已关注' : '未关注'}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamOverview extends StatelessWidget {
  const _TeamOverview({required this.team});
  final TeamDetail team;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              DetailFact(label: '简称', value: team.shortName ?? '暂无'),
              DetailFact(
                label: '国家 / 城市',
                value:
                    [
                      team.country,
                      team.city,
                    ].whereType<String>().join(' · ').isEmpty
                    ? '暂无'
                    : [team.country, team.city].whereType<String>().join(' · '),
              ),
              DetailFact(label: '主场', value: team.stadiumName ?? '暂无'),
              DetailFact(
                label: '成立年份',
                value: team.foundedYear?.toString() ?? '暂无',
              ),
              DetailFact(label: '主教练', value: team.coachName ?? '暂无'),
              DetailFact(label: '身价', value: team.marketValue ?? '暂无'),
            ],
          ),
        ),
      ),
      if (team.upcomingMatches.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        Text('近期比赛', style: Theme.of(context).textTheme.titleLarge),
        for (final match in team.upcomingMatches) ...[
          const SizedBox(height: AppSpacing.sm),
          ScheduleMatchCard(match: match),
        ],
      ],
    ],
  );
}

class _TeamSchedule extends ConsumerStatefulWidget {
  const _TeamSchedule({required this.teamId});
  final int teamId;

  @override
  ConsumerState<_TeamSchedule> createState() => _TeamScheduleState();
}

class _TeamScheduleState extends ConsumerState<_TeamSchedule> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    Future.microtask(
      () =>
          ref.read(teamScheduleControllerProvider(widget.teamId)).loadInitial(),
    );
  }

  void _onScroll() {
    final state = ref.read(teamScheduleControllerProvider(widget.teamId)).state;
    if (_scroll.position.extentAfter < 320 && state.appendMessage == null) {
      ref.read(teamScheduleControllerProvider(widget.teamId)).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(teamScheduleControllerProvider(widget.teamId));
    final state = controller.state;
    return switch (state.status) {
      TeamScheduleStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      TeamScheduleStatus.failure => AppStateView(
        kind: AppStateKind.error,
        title: '球队赛程加载失败',
        message: state.message ?? '请稍后重试。',
        onRetry: controller.loadInitial,
      ),
      TeamScheduleStatus.empty => RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            CapabilityEmpty(title: '暂无赛程', message: '当前球队暂无可展示的比赛。'),
          ],
        ),
      ),
      TeamScheduleStatus.ready => RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: state.matches.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, index) {
            if (index < state.matches.length) {
              return ScheduleMatchCard(match: state.matches[index]);
            }
            if (state.isLoadingMore) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.appendMessage != null) {
              return TextButton(
                onPressed: controller.loadMore,
                child: Text('${state.appendMessage} 点击重试'),
              );
            }
            return Center(
              child: Text(
                state.hasMore ? '继续上滑加载' : '已经到底了',
                style: const TextStyle(color: AppColors.inkMuted),
              ),
            );
          },
        ),
      ),
    };
  }
}

class FootballDetailError extends StatelessWidget {
  const FootballDetailError({
    required this.target,
    required this.error,
    required this.onRetry,
    super.key,
  });
  final String target;
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final message = error is AppNetworkException
        ? footballErrorMessage(error as AppNetworkException, target: target)
        : '$target加载失败，请稍后重试。';
    final missing =
        error is BusinessException &&
        (error as BusinessException).code == 40401;
    return AppStateView(
      kind: missing ? AppStateKind.empty : AppStateKind.error,
      title: missing ? '$target不存在' : '$target加载失败',
      message: message,
      onRetry: missing ? null : onRetry,
    );
  }
}
