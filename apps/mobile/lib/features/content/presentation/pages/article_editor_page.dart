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
import '../controllers/article_editor_controller.dart';
import 'publish_post_page.dart';

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
        appBar: AppBar(
          title: Text(widget.contentId == null ? '撰写文章' : '编辑文章'),
          actions: [
            if (state.status == ArticleEditorStatus.ready)
              TextButton(
                key: const ValueKey('article_submit'),
                onPressed: state.submitting ? null : () => _submit(controller),
                child: Text(
                  state.submitting
                      ? '保存中…'
                      : widget.contentId == null
                      ? '发布'
                      : '保存',
                  style: const TextStyle(color: Colors.white),
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
          maxLength: 200,
          onChanged: (_) => controller.markDirty(),
          decoration: const InputDecoration(labelText: '标题'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const ValueKey('article_summary'),
          controller: _summary,
          maxLines: 3,
          onChanged: (_) => controller.markDirty(),
          decoration: const InputDecoration(
            labelText: '摘要（可选）',
            alignLabelWithHint: true,
          ),
        ),
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
        if (state.cover case final cover?) ...[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: cover.file != null
                ? Image.file(
                    File(cover.file!.path),
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 120,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  )
                : AppContentImage(
                    imageUrl: resolveMediaUrl(config, cover.existingUrl),
                    aspectRatio: 16 / 9,
                  ),
          ),
        ],
        const Divider(height: AppSpacing.xxl),
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
            onTextChanged: (value) =>
                controller.updateText(state.blocks[index].key, value),
            onRemove: () => controller.removeBlock(state.blocks[index].key),
            onMove: (direction) => controller.moveBlock(index, direction),
          ),
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
                  label: Text('${_relationLabel(relation)} · ${relation.name}'),
                  onDeleted: state.submitting
                      ? null
                      : () => controller.removeRelation(relation),
                ),
            ],
          ),
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

  @override
  Widget build(BuildContext context) => Card(
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
