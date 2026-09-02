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
  late final Map<String, SearchEntity> _selected;

  @override
  void initState() {
    super.initState();
    final keyword = ref.read(globalSearchControllerProvider).state.keyword;
    _textController = TextEditingController(text: keyword);
    _selected = {
      for (final entity in widget.initialSelection) entity.stableKey: entity,
    };
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      unawaited(ref.read(globalSearchControllerProvider).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(globalSearchControllerProvider);
    final state = controller.state;
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
              onPressed: () => context.pop(_selected.values.toList()),
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
                onChanged: (value) {
                  if (value.trim().isEmpty && state.keyword.isNotEmpty) {
                    unawaited(controller.search(''));
                  }
                },
                onSubmitted: controller.search,
                decoration: InputDecoration(
                  hintText: '搜索球队、球员、比赛或内容',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    key: const ValueKey('global_search_submit'),
                    tooltip: '搜索',
                    onPressed: () =>
                        unawaited(controller.search(_textController.text)),
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
                    onSelected: () => unawaited(controller.selectType(null)),
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
                      onSelected: () => unawaited(controller.selectType(type)),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: switch (state.status) {
                GlobalSearchStatus.idle => const AppStateView(
                  key: ValueKey('search_idle'),
                  kind: AppStateKind.empty,
                  title: '查找你关心的足球内容',
                  message: '输入关键词后开始搜索。',
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
                  onRetry: controller.retry,
                ),
                GlobalSearchStatus.failure => AppStateView(
                  key: const ValueKey('search_error'),
                  kind: AppStateKind.error,
                  title: '搜索失败',
                  message: state.message ?? '请稍后重试。',
                  onRetry: controller.retry,
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
                        onRetry: controller.loadMore,
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
  if (id == null) return null;
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
