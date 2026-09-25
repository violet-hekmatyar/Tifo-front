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
import '../widgets/content_card.dart';

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
            const SizedBox(height: 2),
            FeedFilterBar(
              selected: state.filter,
              onSelected: (value) => unawaited(controller.selectFilter(value)),
              teams: state.followedTeams,
              selectedTeamId: state.teamId,
              onTeamSelected: (value) =>
                  unawaited(controller.selectTeam(value)),
              onManageTeams: () => context.push('/users/me/followed-teams'),
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
      FeedLoadStatus.empty =>
        state.filter == FeedFilter.following && state.teamId == null
            ? _FollowingEmptyState(
                key: const ValueKey('following_empty'),
                onFindTeams: () => context.push('/search'),
              )
            : AppStateView(
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
          filter: state.filter,
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
    required this.filter,
    required this.controller,
    required this.scrollViewKey,
    required this.cardKey,
    required this.refreshMessage,
    required this.onRetryRefresh,
    required this.loadMore,
  });

  final List<FeedCard> cards;
  final FeedFilter filter;
  final ScrollController controller;
  final GlobalKey scrollViewKey;
  final GlobalKey Function(FeedCard card) cardKey;
  final String? refreshMessage;
  final Future<void> Function() onRetryRefresh;
  final Widget loadMore;

  @override
  Widget build(BuildContext context) {
    final sections = FeedDisplaySections.fromCards(cards);
    final contentLayout = filter == FeedFilter.news
        ? ContentCardLayout.news
        : ContentCardLayout.grid;
    final visualEntries = _visualEntries(
      sections.entries,
      singleColumn: contentLayout == ContentCardLayout.news,
    );
    return CustomScrollView(
      key: scrollViewKey,
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (refreshMessage != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(8, AppSpacing.xs, 8, 0),
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
          padding: const EdgeInsets.fromLTRB(8, AppSpacing.xs, 8, 0),
          sliver: SliverList.separated(
            itemCount: visualEntries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) =>
                _entry(visualEntries[index], cardKey, contentLayout),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            8,
            AppSpacing.xs,
            8,
            AppSpacing.xxl,
          ),
          sliver: SliverToBoxAdapter(child: loadMore),
        ),
      ],
    );
  }
}

List<Object> _visualEntries(
  List<FeedDisplayEntry> entries, {
  bool singleColumn = false,
}) {
  final result = <Object>[];
  if (singleColumn) {
    for (final entry in entries) {
      if (entry is FeedContentRowEntry) {
        result.add(FeedSingleEntry(entry.left));
        if (entry.right case final right?) result.add(FeedSingleEntry(right));
      } else {
        result.add(entry);
      }
    }
    return result;
  }
  final cards = <FeedCard>[];
  for (final entry in entries) {
    if (entry is FeedContentRowEntry) {
      cards.add(entry.left);
      if (entry.right case final right?) cards.add(right);
    } else if (entry is FeedSingleEntry) {
      cards.add(entry.card);
    }
  }
  return cards.isEmpty ? const [] : [_FeedMasonryEntry(cards)];
}

Widget _entry(
  Object entry,
  GlobalKey Function(FeedCard card) cardKey,
  ContentCardLayout contentLayout,
) => switch (entry) {
  FeedSingleEntry(:final card) => FeedCardRenderer(
    key: cardKey(card),
    card: card,
    contentLayout: contentLayout,
  ),
  _FeedMasonryEntry(:final cards) => _FeedMasonry(
    cards: cards,
    cardKey: cardKey,
  ),
  _ => const SizedBox.shrink(),
};

final class _FeedMasonryEntry {
  const _FeedMasonryEntry(this.cards);
  final List<FeedCard> cards;
}

class _FeedMasonry extends StatelessWidget {
  const _FeedMasonry({required this.cards, required this.cardKey});
  final List<FeedCard> cards;
  final GlobalKey Function(FeedCard card) cardKey;

  @override
  Widget build(BuildContext context) {
    final columns = <List<FeedCard>>[[], []];
    for (var index = 0; index < cards.length; index++) {
      columns[index.isEven ? 0 : 1].add(cards[index]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < columns.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (
                  var cardIndex = 0;
                  cardIndex < columns[index].length;
                  cardIndex++
                ) ...[
                  if (cardIndex > 0) const SizedBox(height: 6),
                  FeedCardRenderer(
                    key: cardKey(columns[index][cardIndex]),
                    card: columns[index][cardIndex],
                    contentLayout: ContentCardLayout.grid,
                  ),
                ],
              ],
            ),
          ),
        ],
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
      AppSpacing.sm,
      AppSpacing.sm,
      AppSpacing.sm,
      0,
    ),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey('home_search'),
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Align(
              alignment: Alignment.centerLeft,
              child: Text('搜索球队、球员或内容'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.inkMuted,
              backgroundColor: AppColors.surfaceMuted,
              minimumSize: const Size(0, 44),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        FilledButton.icon(
          key: const ValueKey('home_publish'),
          onPressed: onPublish,
          icon: const Icon(Icons.add_rounded),
          label: const Text('发布'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
        ),
      ],
    ),
  );
}

class _FollowingEmptyState extends StatelessWidget {
  const _FollowingEmptyState({required this.onFindTeams, super.key});

  final VoidCallback onFindTeams;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.page,
    child: Align(
      alignment: const Alignment(0, -0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _FollowingEmptyIllustration(),
            const SizedBox(height: AppSpacing.md),
            Text(
              '暂无关注球队',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                width: constraints.maxWidth * .42,
                height: 42,
                child: FilledButton(
                  onPressed: onFindTeams,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                  ),
                  child: const Text('快去关注'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FollowingEmptyIllustration extends StatelessWidget {
  const _FollowingEmptyIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 86,
    height: 86,
    child: Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.shield_rounded, size: 76, color: AppColors.brand),
        const Icon(Icons.star_rounded, size: 32, color: Colors.white),
        const Positioned(
          top: 0,
          child: Icon(
            Icons.wb_sunny_outlined,
            size: 16,
            color: AppColors.brand,
          ),
        ),
        const Positioned(
          right: 8,
          top: 10,
          child: Icon(Icons.brightness_1, size: 7, color: AppColors.brand),
        ),
        const Positioned(
          left: 7,
          top: 10,
          child: Icon(Icons.brightness_1, size: 7, color: AppColors.brand),
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
