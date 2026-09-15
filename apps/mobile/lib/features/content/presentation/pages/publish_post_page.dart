import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../controllers/publish_post_controller.dart';
import '../publish/publish_local_source.dart';
import '../widgets/publish_mode_bar.dart';

class PublishPostPage extends ConsumerStatefulWidget {
  const PublishPostPage({super.key});

  @override
  ConsumerState<PublishPostPage> createState() => _PublishPostPageState();
}

class _PublishPostPageState extends ConsumerState<PublishPostPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  PublishAuxiliaryItem? _topic;
  PublishAuxiliaryItem? _hotspot;
  bool _published = false;
  bool _discarding = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool _isDirty(PublishState state) =>
      _title.text.trim().isNotEmpty ||
      _body.text.trim().isNotEmpty ||
      state.images.isNotEmpty ||
      _topic != null ||
      _hotspot != null;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(publishPostControllerProvider);
    final state = controller.state;
    final dirty = _isDirty(state);
    return PopScope(
      canPop: _published || _discarding || (!state.submitting && !dirty),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (state.submitting) {
          _showMessage('正在发布，请稍候。');
          return;
        }
        if (await _confirmDiscard(context)) await _discard(controller);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.ink,
          leading: TextButton(
            key: const ValueKey('publish_cancel'),
            onPressed: state.submitting ? null : () => _cancel(controller),
            child: const Text('取消'),
          ),
          title: const Text('发布帖子'),
          actions: [
            FilledButton(
              key: const ValueKey('publish_submit'),
              onPressed: state.submitting ? null : () => _submit(controller),
              child: Text(state.submitting ? '发布中…' : '发布'),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              TextField(
                key: const ValueKey('publish_title'),
                controller: _title,
                enabled: !state.submitting,
                maxLength: 255,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '给帖子一个清晰标题',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const ValueKey('publish_body'),
                controller: _body,
                enabled: !state.submitting,
                maxLength: 2000,
                minLines: 8,
                maxLines: 16,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: '正文',
                  hintText: '分享你的足球观点…',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SelectedAuxiliary(
                key: const ValueKey('publish_selected_auxiliary'),
                topic: _topic,
                hotspot: _hotspot,
                enabled: !state.submitting,
                onRemoveTopic: () => setState(() => _topic = null),
                onRemoveHotspot: () => setState(() => _hotspot = null),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text(
                    '图片 ${state.images.length}/9',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    key: const ValueKey('publish_images'),
                    onPressed: state.submitting || state.images.length >= 9
                        ? null
                        : controller.pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('添加图片'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.images.isEmpty)
                const Text(
                  '可发布纯文字帖子；单张图片不超过 10MB。',
                  style: TextStyle(color: AppColors.inkMuted),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: state.images.length,
                  itemBuilder: (context, index) => _PostImageTile(
                    image: state.images[index],
                    enabled: !state.submitting,
                    onRetry: () => controller.upload(state.images[index]),
                    onRemove: () => controller.remove(state.images[index]),
                  ),
                ),
              if (state.message case final message?)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    message,
                    key: const ValueKey('publish_message'),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: PublishModeBar(
          mode: PublishMode.post,
          enabled: !state.submitting,
          onModeSelected: (mode) => _switchMode(mode, controller),
          tools: [
            _ToolButton(
              key: const ValueKey('publish_topic'),
              icon: Icons.tag,
              label: '话题',
              enabled: !state.submitting,
              onPressed: () => _selectAuxiliary(PublishAuxiliaryKind.topic),
            ),
            _ToolButton(
              key: const ValueKey('publish_hotspot'),
              icon: Icons.local_fire_department_outlined,
              label: '热点',
              enabled: !state.submitting,
              onPressed: () => _selectAuxiliary(PublishAuxiliaryKind.hotspot),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(PublishPostController controller) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final id = await controller.publish(_title.text, _body.text);
    if (id == null || !mounted) return;
    setState(() => _published = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.pushReplacement(
        '/contents/$id',
        extra: const PublishedContentNavigation(),
      );
    });
  }

  Future<void> _switchMode(
    PublishMode mode,
    PublishPostController controller,
  ) async {
    if (mode == PublishMode.post) return;
    if (_isDirty(controller.state)) {
      if (!await _confirmDiscard(context)) return;
      await _discard(controller, pop: false);
      if (!mounted) return;
    }
    context.pushReplacement('/publish/article');
  }

  Future<void> _selectAuxiliary(PublishAuxiliaryKind kind) async {
    final item = await context.push<PublishAuxiliaryItem>(
      kind == PublishAuxiliaryKind.topic ? '/publish/topic' : '/publish/hotspot',
    );
    if (!mounted || item == null) return;
    setState(() {
      if (kind == PublishAuxiliaryKind.topic) {
        _topic = item;
      } else {
        _hotspot = item;
      }
    });
  }

  Future<bool> _confirmDiscard(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('放弃未发布内容？'),
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

  Future<void> _cancel(PublishPostController controller) async {
    if (!_isDirty(controller.state)) {
      if (mounted) context.pop();
      return;
    }
    if (await _confirmDiscard(context)) await _discard(controller);
  }

  Future<void> _discard(
    PublishPostController controller, {
    bool pop = true,
  }) async {
    setState(() => _discarding = true);
    await controller.cleanupDraft();
    if (pop && mounted) context.pop();
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: enabled ? onPressed : null,
    icon: Icon(icon),
  );
}

class _SelectedAuxiliary extends StatelessWidget {
  const _SelectedAuxiliary({
    required this.topic,
    required this.hotspot,
    required this.enabled,
    required this.onRemoveTopic,
    required this.onRemoveHotspot,
    super.key,
  });
  final PublishAuxiliaryItem? topic;
  final PublishAuxiliaryItem? hotspot;
  final bool enabled;
  final VoidCallback onRemoveTopic;
  final VoidCallback onRemoveHotspot;

  @override
  Widget build(BuildContext context) {
    if (topic == null && hotspot == null) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (topic case final value?)
          InputChip(
            key: const ValueKey('publish_topic_chip'),
            label: Text('#${value.name}'),
            onDeleted: enabled ? onRemoveTopic : null,
          ),
        if (hotspot case final value?)
          InputChip(
            key: const ValueKey('publish_hotspot_chip'),
            label: Text('热点 · ${value.name}'),
            onDeleted: enabled ? onRemoveHotspot : null,
          ),
      ],
    );
  }
}

class _PostImageTile extends StatelessWidget {
  const _PostImageTile({
    required this.image,
    required this.enabled,
    required this.onRetry,
    required this.onRemove,
  });
  final PublishImage image;
  final bool enabled;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.file(
          File(image.file.path),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: AppColors.surfaceMuted,
            child: Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
      if (image.status == UploadStatus.uploading)
        const ColoredBox(
          color: Color(0x66000000),
          child: Center(child: CircularProgressIndicator()),
        ),
      if (image.status == UploadStatus.failure)
        ColoredBox(
          color: const Color(0x88000000),
          child: Center(
            child: TextButton(
              onPressed: enabled ? onRetry : null,
              child: const Text('重试', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      Positioned(
        top: 0,
        right: 0,
        child: IconButton.filled(
          onPressed: enabled ? onRemove : null,
          icon: const Icon(Icons.close, size: 16),
        ),
      ),
    ],
  );
}

final class PublishedContentNavigation {
  const PublishedContentNavigation();
}
