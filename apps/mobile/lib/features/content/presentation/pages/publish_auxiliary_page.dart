import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../shared/widgets/app_content_image.dart';
import '../../../../app/config/app_config.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../domain/publish_subject.dart';
import '../controllers/publish_subject_controller.dart';

class PublishAuxiliaryPage extends ConsumerStatefulWidget {
  const PublishAuxiliaryPage({required this.kind, super.key});

  final PublishAuxiliaryKind kind;

  @override
  ConsumerState<PublishAuxiliaryPage> createState() =>
      _PublishAuxiliaryPageState();
}

class _PublishAuxiliaryPageState extends ConsumerState<PublishAuxiliaryPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  PublishAuxiliaryItem? _selected;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMoreIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(publishSubjectControllerProvider(widget.kind)).loadInitial();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _loadMoreIfNeeded() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 240) {
      ref.read(publishSubjectControllerProvider(widget.kind)).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(publishSubjectControllerProvider(widget.kind));
    final state = controller.state;
    final isTopic = widget.kind == PublishAuxiliaryKind.topic;
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isTopic ? '选择话题' : '热点事件'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(_selected),
        ),
      ),
      body: SafeArea(
        child: ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            isTopic ? 0 : AppSpacing.sm,
            AppSpacing.lg,
            24,
          ),
          itemCount: state.records.length + (isTopic ? 3 : 1),
          itemBuilder: (context, index) {
            if (isTopic && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: TextField(
                  key: ValueKey(
                    isTopic ? 'publish_topic_search' : 'publish_hotspot_search',
                  ),
                  controller: _search,
                  onChanged: controller.search,
                  decoration: InputDecoration(
                    hintText: isTopic ? '输入关键词搜索或创建一个新话题' : '搜索热点事件',
                    prefixIcon: isTopic
                        ? const Padding(
                            padding: EdgeInsets.only(left: 14, right: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  key: ValueKey('publish_topic_search_icon'),
                                  color: AppColors.inkMuted,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '#',
                                  key: ValueKey('publish_topic_search_hash'),
                                  style: TextStyle(
                                    color: AppColors.brand,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Icon(
                            Icons.search_rounded,
                            color: AppColors.inkMuted,
                          ),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            }
            if (isTopic && index == 1) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  isTopic ? '热门话题' : '',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }
            final recordsStart = isTopic ? 2 : 0;
            if (index == state.records.length + recordsStart) {
              if (state.status == PublishSubjectStatus.loading ||
                  state.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state.status == PublishSubjectStatus.failure) {
                return Column(
                  children: [
                    Text(state.message ?? '加载失败'),
                    TextButton(
                      onPressed: controller.retry,
                      child: const Text('重试'),
                    ),
                  ],
                );
              }
              if (state.records.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Center(child: Text('没有找到匹配内容')),
                );
              }
              return const SizedBox.shrink();
            }
            final item = state.records[index - recordsStart];
            return isTopic
                ? _TopicRow(
                    item: item,
                    rank: index - 1,
                    selected: _selected?.stableKey == item.stableKey,
                    onTap: () => setState(() => _selected = item),
                  )
                : _HotspotRow(
                    item: item,
                    config: config,
                    selected: _selected?.stableKey == item.stableKey,
                    onTap: () => setState(() => _selected = item),
                  );
          },
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.item,
    required this.rank,
    required this.selected,
    required this.onTap,
  });
  final PublishAuxiliaryItem item;
  final int rank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('${item.kind.name}_${item.id}'),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 18,
                color: rank <= 3 ? const Color(0xFFE63D3D) : AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '#${item.name}#',
              style: TextStyle(
                fontSize: 17,
                color: rank <= 3 ? const Color(0xFFE63D3D) : AppColors.ink,
              ),
            ),
          ),
          Text(
            '${item.count}讨论',
            style: const TextStyle(fontSize: 15, color: AppColors.inkMuted),
          ),
          if (selected) const Icon(Icons.check, color: AppColors.brand),
        ],
      ),
    ),
  );
}

class _HotspotRow extends StatelessWidget {
  const _HotspotRow({
    required this.item,
    required this.config,
    required this.selected,
    required this.onTap,
  });
  final PublishAuxiliaryItem item;
  final AppConfig config;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('${item.kind.name}_${item.id}'),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 78,
              height: 78,
              child: AppContentImage(
                imageUrl: resolveMediaUrl(config, item.coverUrl),
                aspectRatio: 1,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: selected ? const Color(0xFFE63D3D) : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.summary ?? '暂无事件摘要',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    color: AppColors.inkMuted,
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
