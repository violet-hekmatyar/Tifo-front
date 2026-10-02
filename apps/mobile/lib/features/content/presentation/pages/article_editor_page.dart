import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_content_image.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../search/domain/search_models.dart';
import '../../domain/content_detail.dart';
import '../../domain/publish_subject.dart';
import '../controllers/article_editor_controller.dart';
import 'publish_post_page.dart';
import '../widgets/publish_mode_bar.dart';

class ArticleEditorPage extends ConsumerStatefulWidget {
  const ArticleEditorPage({this.contentId, super.key});

  final int? contentId;

  @override
  ConsumerState<ArticleEditorPage> createState() => _ArticleEditorPageState();
}

class _ArticleEditorPageState extends ConsumerState<ArticleEditorPage> {
  final _title = TextEditingController();
  final _summary = TextEditingController();
  bool _hydrated = false;
  bool _saved = false;
  bool _discarding = false;

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(
      articleEditorControllerProvider(widget.contentId),
    );
    final state = controller.state;
    if (state.status == ArticleEditorStatus.ready && !_hydrated) {
      _title.text = state.title;
      _summary.text = state.summary;
      _hydrated = true;
    }
    return PopScope(
      canPop: !state.submitting && (_saved || _discarding || !state.hasDraft),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (state.submitting) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('文章正在保存，请稍候。')));
          return;
        }
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('放弃文章草稿？'),
            content: const Text('尚未发布的修改不会保存，临时上传图片会尽力清理。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('继续编辑'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('放弃'),
              ),
            ],
          ),
        );
        if (leave == true) {
          setState(() => _discarding = true);
          await controller.cleanupDraft();
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          toolbarHeight: 76,
          leadingWidth: 96,
          title: null,
          leading: TextButton(
            key: const ValueKey('article_cancel'),
            onPressed: state.submitting ? null : () => _cancel(controller),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('取消', maxLines: 1, softWrap: false),
            ),
          ),
          actions: [
            if (state.status == ArticleEditorStatus.ready)
              FilledButton(
                key: const ValueKey('article_submit'),
                onPressed: state.submitting ? null : () => _submit(controller),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  state.submitting
                      ? '保存中…'
                      : widget.contentId == null
                      ? '发布'
                      : '保存',
                ),
              ),
          ],
        ),
        body: switch (state.status) {
          ArticleEditorStatus.loading => const AppStateView(
            kind: AppStateKind.loading,
            title: '正在读取文章',
            message: '正在加载正文、图片和关联内容…',
          ),
          ArticleEditorStatus.failure => AppStateView(
            kind: AppStateKind.error,
            title: '文章无法编辑',
            message: state.message ?? '请稍后重试。',
            onRetry: controller.load,
          ),
          ArticleEditorStatus.ready => _editor(controller),
        },
        bottomNavigationBar: state.status == ArticleEditorStatus.ready
            ? PublishModeBar(
                mode: PublishMode.article,
                enabled: !state.submitting,
                onModeSelected: (mode) => _switchMode(mode, controller),
                tools: [
                  if (widget.contentId == null)
                    IconButton(
                      key: const ValueKey('article_select_relations'),
                      tooltip: '关联球队、球员或比赛',
                      onPressed: state.submitting
                          ? null
                          : () => _selectRelations(controller),
                      icon: const Icon(Icons.add_link_rounded),
                    ),
                  IconButton(
                    key: const ValueKey('article_bottom_add_text'),
                    tooltip: '文字',
                    onPressed: state.submitting
                        ? null
                        : controller.addTextBlock,
                    icon: const Icon(Icons.notes_rounded),
                  ),
                  IconButton(
                    key: const ValueKey('article_bottom_add_image'),
                    tooltip: '图片',
                    onPressed: state.submitting
                        ? null
                        : controller.addImageBlocks,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                ],
                auxiliary: [
                  if (widget.contentId == null && state.relations.isNotEmpty)
                    _ArticleRelationBar(
                      relations: state.relations,
                      enabled: !state.submitting,
                      onRemove: controller.removeRelation,
                    ),
                  _ArticleAuxiliaryBar(
                    relations: state.auxiliaryRelations,
                    enabled: !state.submitting,
                    onSelectTopic: () => _selectAuxiliary(
                      controller,
                      PublishAuxiliaryKind.topic,
                    ),
                    onSelectHotspot: () => _selectAuxiliary(
                      controller,
                      PublishAuxiliaryKind.hotspot,
                    ),
                    onRemove: controller.removeAuxiliaryRelation,
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _editor(ArticleEditorController controller) {
    final state = controller.state;
    final config = ref.watch(appConfigProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        TextField(
          key: const ValueKey('article_title'),
          controller: _title,
          enabled: !state.submitting,
          maxLength: 20,
          onChanged: (_) => controller.markDirty(),
          style: const TextStyle(fontSize: 20, color: AppColors.ink),
          decoration: const InputDecoration(
            hintText: '请输入文章标题（20字内）',
            hintStyle: TextStyle(fontSize: 20, color: Color(0xFFC8CDD4)),
            counterText: '',
            contentPadding: EdgeInsets.symmetric(vertical: 18),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE9EBEF)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.brand),
            ),
          ),
        ),
        if (widget.contentId != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const ValueKey('article_summary'),
            controller: _summary,
            enabled: !state.submitting,
            maxLines: 3,
            onChanged: (_) => controller.markDirty(),
            decoration: const InputDecoration(
              labelText: '摘要（可选）',
              alignLabelWithHint: true,
            ),
          ),
        ],
        if (widget.contentId != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('封面', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              OutlinedButton.icon(
                key: const ValueKey('article_pick_cover'),
                onPressed: state.submitting ? null : controller.pickCover,
                icon: const Icon(Icons.image_outlined),
                label: Text(state.cover == null ? '选择封面' : '更换封面'),
              ),
            ],
          ),
        ],
        if (widget.contentId != null)
          if (state.cover case final cover?) ...[
            const SizedBox(height: AppSpacing.sm),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: cover.file != null
                      ? Image.file(
                          File(cover.file!.path),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 120,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        )
                      : AppContentImage(
                          imageUrl: resolveMediaUrl(config, cover.existingUrl),
                          aspectRatio: 16 / 9,
                        ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton.filled(
                    key: const ValueKey('article_remove_cover'),
                    onPressed: state.submitting ? null : controller.removeCover,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              ],
            ),
          ],
        if (widget.contentId != null) const Divider(height: AppSpacing.xxl),
        if (widget.contentId != null)
          Row(
            children: [
              Text('文章段落', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                key: const ValueKey('article_add_text'),
                onPressed: state.submitting ? null : controller.addTextBlock,
                icon: const Icon(Icons.notes_rounded),
                label: const Text('文字'),
              ),
              TextButton.icon(
                key: const ValueKey('article_add_image'),
                onPressed: state.submitting ? null : controller.addImageBlocks,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('图片'),
              ),
            ],
          ),
        if (state.blocks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text('尚未添加段落。', style: TextStyle(color: AppColors.inkMuted)),
          ),
        for (var index = 0; index < state.blocks.length; index++)
          _BlockEditor(
            key: ValueKey('article_block_${state.blocks[index].key}'),
            block: state.blocks[index],
            index: index,
            total: state.blocks.length,
            config: config,
            enabled: !state.submitting,
            compact: widget.contentId == null,
            onTextChanged: (value) =>
                controller.updateText(state.blocks[index].key, value),
            onRemove: () => controller.removeBlock(state.blocks[index].key),
            onMove: (direction) => controller.moveBlock(index, direction),
          ),
        if (widget.contentId != null) ...[
          const Divider(height: AppSpacing.xxl),
          Row(
            children: [
              Text('关联内容', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              OutlinedButton.icon(
                key: const ValueKey('article_select_relations'),
                onPressed: state.submitting
                    ? null
                    : () => _selectRelations(controller),
                icon: const Icon(Icons.add_link_rounded),
                label: Text('${state.relations.length}/10'),
              ),
            ],
          ),
          if (state.relations.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                '可关联球队、球员或比赛。',
                style: TextStyle(color: AppColors.inkMuted),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final relation in state.relations)
                  InputChip(
                    label: Text(
                      '${_relationLabel(relation)} · ${relation.name}',
                    ),
                    onDeleted: state.submitting
                        ? null
                        : () => controller.removeRelation(relation),
                  ),
              ],
            ),
          if (state.auxiliaryRelations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final item in state.auxiliaryRelations)
                    InputChip(
                      label: Text(
                        item.kind == PublishAuxiliaryKind.topic
                            ? '#${item.name}'
                            : '热点 · ${item.name}',
                      ),
                      onDeleted: state.submitting
                          ? null
                          : () => controller.removeAuxiliaryRelation(item.kind),
                    ),
                ],
              ),
            ),
        ],
        if (state.message != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              state.message!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Future<void> _selectRelations(ArticleEditorController controller) async {
    final selected = await context.push<List<SearchEntity>>(
      '/relations/select',
      extra: controller.state.relations,
    );
    if (selected != null) controller.setRelations(selected);
  }

  Future<void> _selectAuxiliary(
    ArticleEditorController controller,
    PublishAuxiliaryKind kind,
  ) async {
    final item = await context.push<PublishAuxiliaryItem>(
      kind == PublishAuxiliaryKind.topic
          ? '/publish/topic'
          : '/publish/hotspot',
    );
    if (!mounted || item == null) return;
    controller.setAuxiliaryRelation(item);
  }

  Future<void> _cancel(ArticleEditorController controller) async {
    if (!controller.state.hasDraft) {
      if (mounted) context.pop();
      return;
    }
    if (await _confirmDiscard()) await _discard(controller);
  }

  Future<void> _switchMode(
    PublishMode mode,
    ArticleEditorController controller,
  ) async {
    if (mode == PublishMode.article) return;
    if (controller.state.hasDraft) {
      if (!await _confirmDiscard()) return;
      await _discard(controller, pop: false);
      if (!mounted) return;
    }
    context.pushReplacement('/publish/post');
  }

  Future<bool> _confirmDiscard() async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('放弃文章草稿？'),
          content: const Text('尚未发布的修改不会保存，临时上传图片会尽力清理。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('继续编辑'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('放弃'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _discard(
    ArticleEditorController controller, {
    bool pop = true,
  }) async {
    setState(() => _discarding = true);
    await controller.cleanupDraft();
    if (pop && mounted) context.pop();
  }

  Future<void> _submit(ArticleEditorController controller) async {
    final id = await controller.submit(_title.text, _summary.text);
    if (id == null || !mounted) return;
    setState(() => _saved = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.contentId == null) {
        context.pushReplacement(
          '/contents/$id',
          extra: const PublishedContentNavigation(),
        );
      } else {
        context.pop(true);
      }
    });
  }
}

class _BlockEditor extends StatelessWidget {
  const _BlockEditor({
    required this.block,
    required this.index,
    required this.total,
    required this.config,
    required this.enabled,
    required this.onTextChanged,
    required this.onRemove,
    required this.onMove,
    required this.compact,
    super.key,
  });

  final ArticleDraftBlock block;
  final int index;
  final int total;
  final AppConfig config;
  final bool enabled;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove;
  final bool compact;

  @override
  Widget build(BuildContext context) =>
      compact && block.type == ArticleBlockType.text
      ? TextFormField(
          key: ValueKey('article_text_${block.key}'),
          initialValue: block.text,
          minLines: 7,
          maxLines: 14,
          enabled: enabled,
          onChanged: onTextChanged,
          style: const TextStyle(fontSize: 18, height: 1.55),
          decoration: const InputDecoration(
            hintText: '请输入文章内容',
            hintStyle: TextStyle(fontSize: 18, color: Color(0xFFC8CDD4)),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.only(top: 18),
          ),
        )
      : Card(
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '段落 ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '上移',
                      onPressed: enabled && index > 0 ? () => onMove(-1) : null,
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                    IconButton(
                      tooltip: '下移',
                      onPressed: enabled && index < total - 1
                          ? () => onMove(1)
                          : null,
                      icon: const Icon(Icons.arrow_downward_rounded),
                    ),
                    IconButton(
                      tooltip: '删除段落',
                      onPressed: enabled ? onRemove : null,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                if (block.type == ArticleBlockType.text)
                  TextFormField(
                    key: ValueKey('article_text_${block.key}'),
                    initialValue: block.text,
                    minLines: 4,
                    maxLines: 12,
                    enabled: enabled,
                    onChanged: onTextChanged,
                    decoration: const InputDecoration(hintText: '输入正文段落…'),
                  )
                else if (block.type == ArticleBlockType.image)
                  _DraftImage(block: block, config: config)
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    color: AppColors.surfaceMuted,
                    child: Text('暂不支持的段落类型：${block.rawType}'),
                  ),
              ],
            ),
          ),
        );
}

class _ArticleRelationBar extends StatelessWidget {
  const _ArticleRelationBar({
    required this.relations,
    required this.enabled,
    required this.onRemove,
  });

  final List<SearchEntity> relations;
  final bool enabled;
  final ValueChanged<SearchEntity> onRemove;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    children: [
      for (final relation in relations)
        InputChip(
          label: Text('${_relationLabel(relation)} · ${relation.name}'),
          backgroundColor: AppColors.surfaceMuted,
          side: BorderSide.none,
          onDeleted: enabled ? () => onRemove(relation) : null,
        ),
    ],
  );
}

class _ArticleAuxiliaryBar extends StatelessWidget {
  const _ArticleAuxiliaryBar({
    required this.relations,
    required this.enabled,
    required this.onSelectTopic,
    required this.onSelectHotspot,
    required this.onRemove,
  });
  final List<PublishAuxiliaryItem> relations;
  final bool enabled;
  final VoidCallback onSelectTopic;
  final VoidCallback onSelectHotspot;
  final ValueChanged<PublishAuxiliaryKind> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        for (final item in relations)
          InputChip(
            label: Text(
              item.kind == PublishAuxiliaryKind.topic
                  ? '#${item.name}'
                  : '热点 · ${item.name}',
            ),
            backgroundColor: AppColors.brandSoft,
            side: BorderSide.none,
            onDeleted: enabled ? () => onRemove(item.kind) : null,
          ),
        if (!relations.any((item) => item.kind == PublishAuxiliaryKind.topic))
          ActionChip(
            avatar: const Icon(Icons.tag, size: 20),
            label: const Text('添加话题'),
            onPressed: enabled ? onSelectTopic : null,
          ),
        if (!relations.any((item) => item.kind == PublishAuxiliaryKind.hotspot))
          ActionChip(
            avatar: const Icon(Icons.local_fire_department_outlined, size: 20),
            label: const Text('关联热点事件'),
            onPressed: enabled ? onSelectHotspot : null,
          ),
      ],
    );
  }
}

class _DraftImage extends StatelessWidget {
  const _DraftImage({required this.block, required this.config});

  final ArticleDraftBlock block;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final file = block.image?.file;
    if (file != null) {
      return Image.file(
        File(file.path),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox(
          height: 120,
          child: Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );
    }
    return AppContentImage(
      imageUrl: resolveMediaUrl(config, block.image?.existingUrl),
      aspectRatio: 16 / 9,
    );
  }
}

String _relationLabel(SearchEntity entity) => switch (entity.type) {
  SearchEntityType.team => '球队',
  SearchEntityType.player => '球员',
  SearchEntityType.match => '比赛',
  _ => '关联',
};
