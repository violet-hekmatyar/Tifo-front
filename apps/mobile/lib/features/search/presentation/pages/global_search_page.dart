import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/search_models.dart';
import '../controllers/global_search_controller.dart';
import '../controllers/search_history_store.dart';
import '../widgets/search_result_tile.dart';

class GlobalSearchPage extends ConsumerStatefulWidget {
  const GlobalSearchPage({
    this.selectionMode = false,
    this.initialSelection = const [],
    super.key,
  });

  final bool selectionMode;
  final List<SearchEntity> initialSelection;

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  late final TextEditingController _textController;
  final _scrollController = ScrollController();
  Timer? _debounce;
  late final Map<String, SearchEntity> _selected;

  @override
  void initState() {
    super.initState();
    final keyword = ref
        .read(
          widget.selectionMode
              ? relationSearchControllerProvider
              : globalSearchControllerProvider,
        )
        .state
        .keyword;
    _textController = TextEditingController(text: keyword);
    if (widget.selectionMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final controller = ref.read(relationSearchControllerProvider);
        controller.reset();
        if (_textController.text.isNotEmpty) {
          _textController.clear();
        }
      });
    }
    _selected = {};
    for (final entity in widget.initialSelection) {
      if (_selected.length >= 10 ||
          entity.entityId == null ||
          !const {
            SearchEntityType.team,
            SearchEntityType.player,
            SearchEntityType.match,
          }.contains(entity.type)) {
        continue;
      }
      _selected[entity.stableKey] = entity;
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.extentAfter < 300) {
      unawaited(_controller.loadMore());
    }
  }

  GlobalSearchController get _controller => ref.read(
    widget.selectionMode
        ? relationSearchControllerProvider
        : globalSearchControllerProvider,
  );

  void _onChanged(String value) {
    _debounce?.cancel();
    if (normalizeSearchKeyword(value).isEmpty) {
      unawaited(_controller.search(''));
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 280),
      () => unawaited(_controller.search(value)),
    );
  }

  void _submit() {
    _debounce?.cancel();
    unawaited(_controller.search(_textController.text));
  }

  @override
  Widget build(BuildContext context) {
    final activeController = ref.watch(
      widget.selectionMode
          ? relationSearchControllerProvider
          : globalSearchControllerProvider,
    );
    final state = activeController.state;
    final history = ref.watch(searchHistoryProvider);
    final config = ref.watch(appConfigProvider);
    final records = widget.selectionMode
        ? state.records
              .where(
                (entity) => const {
                  SearchEntityType.team,
                  SearchEntityType.player,
                  SearchEntityType.match,
                }.contains(entity.type),
              )
              .toList(growable: false)
        : state.records;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode ? '选择关联内容' : '全局搜索'),
        actions: [
          if (widget.selectionMode)
            TextButton(
              key: const ValueKey('relation_selection_done'),
              onPressed: () {
                final result = _selected.values.toList()
                  ..sort((a, b) => a.stableKey.compareTo(b.stableKey));
                context.pop(result);
              },
              child: Text(
                '完成 ${_selected.length}/10',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: TextField(
                key: const ValueKey('global_search_input'),
                controller: _textController,
                autofocus: state.keyword.isEmpty,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: '搜索球队、球员、比赛或内容',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    key: const ValueKey('global_search_submit'),
                    tooltip: '搜索',
                    onPressed: _submit,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _FilterChip(
                    key: const ValueKey('search_filter_all'),
                    label: '全部',
                    selected: state.entityType == null,
                    onSelected: () =>
                        unawaited(activeController.selectType(null)),
                  ),
                  for (final type in SearchEntityType.values.where(
                    (value) =>
                        value != SearchEntityType.unknown &&
                        (!widget.selectionMode ||
                            value != SearchEntityType.content),
                  )) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _FilterChip(
                      key: ValueKey('search_filter_${type.wireValue}'),
                      label: _typeLabel(type),
                      selected: state.entityType == type,
                      onSelected: () =>
                          unawaited(activeController.selectType(type)),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: switch (state.status) {
                GlobalSearchStatus.idle => _IdleSearchView(
                  history: history,
                  onUse: (keyword) {
                    _textController.text = keyword;
                    _textController.selection = TextSelection.collapsed(
                      offset: keyword.length,
                    );
                    unawaited(activeController.search(keyword));
                  },
                  onRemove: history.remove,
                  onClear: history.clear,
                ),
                GlobalSearchStatus.loading => const AppStateView(
                  key: ValueKey('search_loading'),
                  kind: AppStateKind.loading,
                  title: '正在搜索',
                  message: '正在查找真实球队、球员、比赛和内容…',
                ),
                GlobalSearchStatus.empty => AppStateView(
                  key: const ValueKey('search_empty'),
                  kind: AppStateKind.empty,
                  title: '没有找到相关结果',
                  message: '可以更换关键词或搜索分类。',
                  onRetry: activeController.retry,
                ),
                GlobalSearchStatus.failure => AppStateView(
                  key: const ValueKey('search_error'),
                  kind: AppStateKind.error,
                  title: '搜索失败',
                  message: state.message ?? '请稍后重试。',
                  onRetry: activeController.retry,
                ),
                GlobalSearchStatus.ready
                    when widget.selectionMode && records.isEmpty =>
                  AppStateView(
                    key: const ValueKey('search_selection_empty'),
                    kind: AppStateKind.empty,
                    title: '没有可关联的实体',
                    message: state.hasMore
                        ? '当前页没有球队、球员或比赛。继续加载更多结果。'
                        : '没有找到可关联的球队、球员或比赛。',
                    onRetry: state.hasMore
                        ? activeController.loadMore
                        : activeController.retry,
                  ),
                GlobalSearchStatus.ready => ListView.separated(
                  key: const PageStorageKey('global_search_results'),
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  itemCount: records.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == records.length) {
                      return _LoadMoreState(
                        state: state,
                        onRetry: activeController.loadMore,
                      );
                    }
                    final entity = records[index];
                    final selected = _selected.containsKey(entity.stableKey);
                    return SearchResultTile(
                      key: ValueKey(entity.stableKey),
                      entity: entity,
                      config: config,
                      selected: selected,
                      onTap: widget.selectionMode
                          ? () => _toggleSelection(entity)
                          : searchEntityLocation(entity) == null
                          ? null
                          : () => context.push(searchEntityLocation(entity)!),
                    );
                  },
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(SearchEntity entity) {
    setState(() {
      if (_selected.remove(entity.stableKey) != null) return;
      if (_selected.length >= 10) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('最多关联 10 项内容')));
        return;
      }
      _selected[entity.stableKey] = entity;
    });
  }
}

class _IdleSearchView extends StatelessWidget {
  const _IdleSearchView({
    required this.history,
    required this.onUse,
    required this.onRemove,
    required this.onClear,
  });

  final SearchHistoryStore history;
  final ValueChanged<String> onUse;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (history.items.isEmpty) {
      return const AppStateView(
        key: ValueKey('search_idle'),
        kind: AppStateKind.empty,
        title: '查找你关心的足球内容',
        message: '输入关键词后开始搜索。',
      );
    }
    return ListView(
      key: const ValueKey('search_idle_history'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Text('搜索历史', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton(
              key: const ValueKey('search_history_clear'),
              onPressed: onClear,
              child: const Text('清空'),
            ),
          ],
        ),
        for (final keyword in history.items)
          ListTile(
            key: ValueKey('search_history_$keyword'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history_rounded),
            title: Text(keyword),
            onTap: () => onUse(keyword),
            trailing: IconButton(
              key: ValueKey('search_history_remove_$keyword'),
              tooltip: '删除 $keyword',
              onPressed: () => onRemove(keyword),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
  );
}

class _LoadMoreState extends StatelessWidget {
  const _LoadMoreState({required this.state, required this.onRetry});

  final GlobalSearchState state;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.appendMessage case final message?) {
      return Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(message),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Text(
          state.hasMore ? '继续上滑加载' : '已经到底了',
          style: const TextStyle(color: AppColors.inkMuted),
        ),
      ),
    );
  }
}

String? searchEntityLocation(SearchEntity entity) {
  final id = entity.entityId;
  if (id == null || id <= 0) return null;
  return switch (entity.type) {
    SearchEntityType.team => '/teams/$id',
    SearchEntityType.player => '/players/$id',
    SearchEntityType.match => '/matches/$id',
    SearchEntityType.content => '/contents/$id',
    SearchEntityType.unknown => null,
  };
}

String _typeLabel(SearchEntityType type) => switch (type) {
  SearchEntityType.team => '球队',
  SearchEntityType.player => '球员',
  SearchEntityType.match => '比赛',
  SearchEntityType.content => '内容',
  SearchEntityType.unknown => '未知',
};
