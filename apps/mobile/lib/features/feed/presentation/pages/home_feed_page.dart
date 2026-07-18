import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/feed_card.dart';
import '../../domain/feed_filter.dart';
import '../controllers/feed_controller.dart';
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
              onPublish: () => context.push('/publish'),
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
    required this.loadMore,
  });

  final List<FeedCard> cards;
  final ScrollController controller;
  final Widget loadMore;

  @override
  Widget build(BuildContext context) {
    final blocks = _blocks(cards);
    return CustomScrollView(
      key: const PageStorageKey('home_feed_scroll'),
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverList.separated(
            itemCount: blocks.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => blocks[index],
          ),
        ),
        SliverToBoxAdapter(child: loadMore),
      ],
    );
  }
}

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

List<Widget> _blocks(List<FeedCard> cards) {
  final result = <Widget>[];
  var index = 0;
  while (index < cards.length) {
    final card = cards[index];
    if (card is ContentFeedCard) {
      final next = index + 1 < cards.length ? cards[index + 1] : null;
      if (next is ContentFeedCard) {
        result.add(
          Row(
            key: ValueKey('feed_row_${card.cardId}_${next.cardId}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FeedCardRenderer(key: ValueKey(card.cardId), card: card),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FeedCardRenderer(key: ValueKey(next.cardId), card: next),
              ),
            ],
          ),
        );
        index += 2;
        continue;
      }
      result.add(
        Row(
          key: ValueKey('feed_row_${card.cardId}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FeedCardRenderer(key: ValueKey(card.cardId), card: card),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: SizedBox()),
          ],
        ),
      );
    } else {
      result.add(FeedCardRenderer(key: ValueKey(card.cardId), card: card));
    }
    index++;
  }
  return result;
}

String _emptyTitle(FeedFilter filter, int? teamId) {
  if (teamId != null) return '该球队暂时没有相关内容';
  return switch (filter) {
    FeedFilter.recommend => '暂时没有推荐内容',
    FeedFilter.news => '暂时没有资讯',
    FeedFilter.following => '关注流暂时为空',
  };
}
