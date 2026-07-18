import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/football_models.dart';
import '../controllers/football_data_controller.dart';
import '../widgets/football_widgets.dart';

class FootballDataPage extends ConsumerStatefulWidget {
  const FootballDataPage({super.key});
  @override
  ConsumerState<FootballDataPage> createState() => _FootballDataPageState();
}

class _FootballDataPageState extends ConsumerState<FootballDataPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(
      () => ref.read(footballDataControllerProvider).loadInitial(),
    );
  }

  void _onScroll() {
    final state = ref.read(footballDataControllerProvider).state;
    if (_scrollController.position.extentAfter < 360 &&
        state.appendMessage == null) {
      ref.read(footballDataControllerProvider).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(footballDataControllerProvider);
    final state = controller.state;
    return Scaffold(
      appBar: AppBar(title: const Text('数据')),
      body: Column(
        children: [
          _SourceBar(state: state, onSelected: controller.selectSource),
          Expanded(
            child: switch (state.status) {
              FootballDataStatus.loading => const AppStateView(
                kind: AppStateKind.loading,
                title: '正在加载赛程',
                message: '正在读取联赛与比赛数据…',
              ),
              FootballDataStatus.failure => AppStateView(
                kind: AppStateKind.error,
                title: '赛程加载失败',
                message: state.message ?? '请检查网络后重试。',
                onRetry: controller.loadInitial,
              ),
              FootballDataStatus.empty => RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 420,
                      child: AppStateView(
                        kind: AppStateKind.empty,
                        title: '暂无比赛',
                        message: '当前范围还没有可展示的赛程，稍后再来看看。',
                      ),
                    ),
                  ],
                ),
              ),
              FootballDataStatus.ready => _MatchList(
                state: state,
                controller: _scrollController,
                onRefresh: controller.refresh,
                onLoadMore: controller.loadMore,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _SourceBar extends StatelessWidget {
  const _SourceBar({required this.state, required this.onSelected});
  final FootballDataState state;
  final ValueChanged<FootballSource> onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('重要'),
            selected: state.source is ImportantSource,
            onSelected: (_) => onSelected(const ImportantSource()),
          ),
          const SizedBox(width: AppSpacing.xs),
          ChoiceChip(
            label: const Text('关注'),
            selected: state.source is FollowingSource,
            onSelected: (_) => onSelected(const FollowingSource()),
          ),
          for (final league in state.leagues) ...[
            const SizedBox(width: AppSpacing.xs),
            _LeagueChip(
              league: league,
              selected:
                  state.source is LeagueSource &&
                  (state.source as LeagueSource).leagueId == league.id,
              onTap: () => onSelected(LeagueSource(league.id)),
            ),
          ],
        ],
      ),
    ),
  );
}

class _LeagueChip extends ConsumerWidget {
  const _LeagueChip({
    required this.league,
    required this.selected,
    required this.onTap,
  });
  final League league;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ActionChip(
    backgroundColor: selected ? AppColors.brandSoft : null,
    side: BorderSide(color: selected ? AppColors.brand : AppColors.border),
    avatar: AppTeamLogo(
      identity: 'league:${league.id}',
      name: league.name,
      imageUrl: resolveMediaUrl(ref.watch(appConfigProvider), league.logoUrl),
      size: 24,
    ),
    label: Text(league.name),
    onPressed: onTap,
  );
}

class _MatchList extends StatelessWidget {
  const _MatchList({
    required this.state,
    required this.controller,
    required this.onRefresh,
    required this.onLoadMore,
  });
  final FootballDataState state;
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    String? previousDate;
    final children = <Widget>[];
    for (final match in state.matches) {
      final date = footballDate(match.matchTime);
      if (date != previousDate) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              date,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        );
        previousDate = date;
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: ScheduleMatchCard(match: match),
        ),
      );
    }
    children.add(
      SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: state.isLoadingMore
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text('正在加载更多…'),
                  ],
                )
              : state.appendMessage != null
              ? Center(
                  child: TextButton.icon(
                    onPressed: onLoadMore,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text('${state.appendMessage} 点击重试'),
                  ),
                )
              : Center(
                  child: Text(
                    state.hasMore ? '继续上滑加载' : '已经到底了',
                    style: const TextStyle(color: AppColors.inkMuted),
                  ),
                ),
        ),
      ),
    );
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey('football_data_list'),
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: children,
      ),
    );
  }
}
