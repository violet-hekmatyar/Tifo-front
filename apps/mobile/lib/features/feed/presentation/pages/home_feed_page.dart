import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  final _scrollViewKey = GlobalKey();
  final Map<String, GlobalKey> _cardKeys = {};
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    ref.listenManual(feedRefreshRequestProvider, (previous, next) {
      if (next == null) return;
      ref.read(feedRefreshRequestProvider.notifier).state = null;
      unawaited(_refreshPreservingAnchor());
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
    final direction = _scrollController.position.userScrollDirection;
    final shouldShow =
        _scrollController.offset > 240 && direction == ScrollDirection.forward;
    final shouldHide =
        _scrollController.offset <= 240 || direction == ScrollDirection.reverse;
    if (shouldShow && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (shouldHide && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
    if (_scrollController.position.extentAfter < 500) {
      unawaited(ref.read(feedControllerProvider).loadMore());
    }
  }

  Future<void> _refreshPreservingAnchor() async {
    final anchor = _captureAnchor();
    await ref.read(feedControllerProvider).refresh();
    if (!mounted || anchor == null) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scrollController.hasClients) return;
    final context = _cardKeys[anchor.key]?.currentContext;
    final box = context?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final currentY = box.localToGlobal(Offset.zero).dy;
    final target = (_scrollController.offset + currentY - anchor.screenY).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(target);
  }

  ({String key, double screenY})? _captureAnchor() {
    if (!_scrollController.hasClients) return null;
    final viewport =
        _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.attached) return null;
    final top = viewport.localToGlobal(Offset.zero).dy;
    ({String key, double screenY})? result;
    for (final entry in _cardKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      if (y + box.size.height < top) continue;
      if (result == null || y < result.screenY) {
        result = (key: entry.key, screenY: y);
      }
    }
    return result;
  }

  GlobalKey _cardKey(FeedCard card) =>
      _cardKeys.putIfAbsent(feedCardStableKey(card), GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(feedControllerProvider);
    final state = controller.state;
    return Scaffold(
      floatingActionButton: IgnorePointer(
        ignoring: !_showBackToTop,
        child: AnimatedScale(
          scale: _showBackToTop ? 1 : 0.82,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            key: const ValueKey('feed_back_to_top_visibility'),
            opacity: _showBackToTop ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: FloatingActionButton.small(
              key: const ValueKey('feed_back_to_top'),
              tooltip: '返回顶部',
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
              ),
              child: const Icon(Icons.vertical_align_top_rounded),
            ),
          ),
        ),
      ),
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
              onOpenTeam: (teamId) => context.push('/teams/$teamId'),
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
        onRefresh: _refreshPreservingAnchor,
        child: _ReadyFeed(
          cards: state.cards,
          controller: _scrollController,
          scrollViewKey: _scrollViewKey,
          cardKey: _cardKey,
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
    required this.scrollViewKey,
    required this.cardKey,
    required this.refreshMessage,
    required this.onRetryRefresh,
    required this.loadMore,
  });

  final List<FeedCard> cards;
  final ScrollController controller;
  final GlobalKey scrollViewKey;
  final GlobalKey Function(FeedCard card) cardKey;
  final String? refreshMessage;
  final Future<void> Function() onRetryRefresh;
  final Widget loadMore;

  @override
  Widget build(BuildContext context) {
    final sections = FeedDisplaySections.fromCards(cards);
    return CustomScrollView(
      key: scrollViewKey,
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
        SliverPadding(
          key: const ValueKey('feed_ordered_section'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverList.separated(
            itemCount: sections.entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _entry(sections.entries[index], cardKey),
          ),
        ),
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

Widget _entry(
  FeedDisplayEntry entry,
  GlobalKey Function(FeedCard card) cardKey,
) => switch (entry) {
  FeedSingleEntry(:final card) => FeedCardRenderer(
    key: cardKey(card),
    card: card,
  ),
  FeedContentRowEntry(:final left, :final right) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FeedCardRenderer(key: cardKey(left), card: left),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: right == null
              ? const SizedBox()
              : FeedCardRenderer(key: cardKey(right), card: right),
        ),
      ],
    ),
  ),
};

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
