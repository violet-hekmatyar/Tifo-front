import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/feed_card.dart';
import '../../domain/feed_filter.dart';
import '../controllers/feed_controller.dart';
import '../controllers/feed_refresh_coordinator.dart';
import '../models/feed_display_sections.dart';
import '../widgets/feed_card_renderer.dart';
import '../widgets/feed_filter_bar.dart';
import '../widgets/feed_load_more.dart';
import '../widgets/followed_team_bar.dart';

class HomeFeedPage extends ConsumerStatefulWidget {
  const HomeFeedPage({super.key});

  @override
  ConsumerState<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends ConsumerState<HomeFeedPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.listenManual(feedRefreshRequestProvider, (previous, next) {
      if (next == null) return;
      ref.read(feedRefreshRequestProvider.notifier).state = null;
      unawaited(ref.read(feedControllerProvider).refresh());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(feedControllerProvider).loadInitial());
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500) {
      unawaited(ref.read(feedControllerProvider).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(feedControllerProvider);
    final state = controller.state;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _HomeHeader(
              onSearch: () => context.push('/search'),
              onPublish: () => context.push('/publish/post'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FeedFilterBar(
              selected: state.filter,
              onSelected: (value) => unawaited(controller.selectFilter(value)),
            ),
            FollowedTeamBar(
              teams: state.followedTeams,
              selectedTeamId: state.teamId,
              onSelected: (value) => unawaited(controller.selectTeam(value)),
            ),
            Expanded(child: _body(context, controller)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, FeedController controller) {
    final state = controller.state;
    return switch (state.status) {
      FeedLoadStatus.loading => const AppStateView(
        key: ValueKey('feed_loading'),
        kind: AppStateKind.loading,
        title: '正在加载看台',
        message: '正在获取最新足球内容与比赛…',
      ),
      FeedLoadStatus.failure => AppStateView(
        key: const ValueKey('feed_error'),
        kind: AppStateKind.error,
        title: '首页加载失败',
        message: state.message ?? '请稍后重试。',
        onRetry: controller.loadInitial,
      ),
      FeedLoadStatus.empty => AppStateView(
        key: const ValueKey('feed_empty'),
        kind: AppStateKind.empty,
        title: _emptyTitle(state.filter, state.teamId),
        message: '当前没有可展示的真实内容，下拉或稍后重试。',
        onRetry: controller.loadInitial,
      ),
      FeedLoadStatus.ready => RefreshIndicator(
        onRefresh: controller.refresh,
        child: _ReadyFeed(
          cards: state.cards,
          controller: _scrollController,
          refreshMessage: state.message,
          onRetryRefresh: controller.refresh,
          loadMore: FeedLoadMore(
            isLoading: state.isLoadingMore,
            hasMore: state.hasMore,
            message: state.appendMessage,
            onRetry: controller.loadMore,
          ),
        ),
      ),
    };
  }
}

class _ReadyFeed extends StatelessWidget {
  const _ReadyFeed({
    required this.cards,
    required this.controller,
    required this.refreshMessage,
    required this.onRetryRefresh,
    required this.loadMore,
  });

  final List<FeedCard> cards;
  final ScrollController controller;
  final String? refreshMessage;
  final Future<void> Function() onRetryRefresh;
  final Widget loadMore;

  @override
  Widget build(BuildContext context) {
    final sections = FeedDisplaySections.fromCards(cards);
    return CustomScrollView(
      key: const PageStorageKey('home_feed_scroll'),
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (refreshMessage != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Material(
                key: const ValueKey('feed_refresh_error'),
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ListTile(
                  dense: true,
                  title: Text(refreshMessage!),
                  trailing: TextButton(
                    onPressed: onRetryRefresh,
                    child: const Text('重试'),
                  ),
                ),
              ),
            ),
          ),
        if (sections.matches.isNotEmpty) _matchSection(sections.matches),
        if (sections.contents.isNotEmpty) _contentSection(sections.contents),
        if (sections.compatibility.isNotEmpty)
          _compatibilitySection(sections.compatibility),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          sliver: SliverToBoxAdapter(child: loadMore),
        ),
      ],
    );
  }
}

SliverPadding _matchSection(List<MatchFeedCard> cards) => SliverPadding(
  key: const ValueKey('feed_match_section'),
  padding: const EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.sm,
    AppSpacing.lg,
    0,
  ),
  sliver: SliverList.separated(
    itemCount: cards.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
    itemBuilder: (context, index) {
      final card = cards[index];
      return FeedCardRenderer(key: ValueKey(card.cardId), card: card);
    },
  ),
);

SliverPadding _contentSection(List<ContentFeedCard> cards) => SliverPadding(
  key: const ValueKey('feed_content_section'),
  padding: const EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.sm,
    AppSpacing.lg,
    0,
  ),
  sliver: SliverList.separated(
    itemCount: (cards.length + 1) ~/ 2,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
    itemBuilder: (context, rowIndex) {
      final left = cards[rowIndex * 2];
      final rightIndex = rowIndex * 2 + 1;
      final right = rightIndex < cards.length ? cards[rightIndex] : null;
      return Row(
        key: ValueKey(
          right == null
              ? 'feed_row_${left.cardId}'
              : 'feed_row_${left.cardId}_${right.cardId}',
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FeedCardRenderer(key: ValueKey(left.cardId), card: left),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: right == null
                ? const SizedBox()
                : FeedCardRenderer(key: ValueKey(right.cardId), card: right),
          ),
        ],
      );
    },
  ),
);

SliverPadding _compatibilitySection(List<UnknownFeedCard> cards) =>
    SliverPadding(
      key: const ValueKey('feed_compatibility_section'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      sliver: SliverList.separated(
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final card = cards[index];
          return FeedCardRenderer(key: ValueKey(card.cardId), card: card);
        },
      ),
    );

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSearch, required this.onPublish});
  final VoidCallback onSearch;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      0,
    ),
    child: Row(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.brand,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xs),
            child: Icon(Icons.sports_soccer_rounded, color: Colors.white),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text('南看台', style: Theme.of(context).textTheme.headlineSmall),
        ),
        IconButton.filledTonal(
          key: const ValueKey('home_search'),
          tooltip: '搜索',
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded),
        ),
        const SizedBox(width: AppSpacing.xs),
        FilledButton.icon(
          key: const ValueKey('home_publish'),
          onPressed: onPublish,
          icon: const Icon(Icons.add_rounded),
          label: const Text('发布'),
        ),
      ],
    ),
  );
}

String _emptyTitle(FeedFilter filter, int? teamId) {
  if (teamId != null) return '该球队暂时没有相关内容';
  return switch (filter) {
    FeedFilter.recommend => '暂时没有推荐内容',
    FeedFilter.news => '暂时没有资讯',
    FeedFilter.following => '关注流暂时为空',
  };
}
