import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../controllers/publish_post_controller.dart';
import '../../domain/publish_subject.dart';
import '../widgets/publish_mode_bar.dart';

class PublishPostPage extends ConsumerStatefulWidget {
  const PublishPostPage({super.key});

  @override
  ConsumerState<PublishPostPage> createState() => _PublishPostPageState();
}

class _PublishPostPageState extends ConsumerState<PublishPostPage> {
  final _title = TextEditingController();
  final _body = TextEditingController();
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
      state.hasDraft;

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
          toolbarHeight: 76,
          leadingWidth: 96,
          title: null,
          leading: TextButton(
            key: const ValueKey('publish_cancel'),
            onPressed: state.submitting ? null : () => _cancel(controller),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('取消', maxLines: 1, softWrap: false),
            ),
          ),
          actions: [
            FilledButton(
              key: const ValueKey('publish_submit'),
              onPressed: state.submitting ? null : () => _submit(controller),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: const StadiumBorder(),
              ),
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
              0,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              TextField(
                key: const ValueKey('publish_title'),
                controller: _title,
                enabled: !state.submitting,
                maxLength: 20,
                style: const TextStyle(fontSize: 20, color: AppColors.ink),
                onChanged: (_) => setState(() {}),
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
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const ValueKey('publish_body'),
                controller: _body,
                enabled: !state.submitting,
                maxLength: 2000,
                minLines: _body.text.trim().isEmpty ? 1 : 2,
                maxLines: 12,
                style: const TextStyle(fontSize: 18, height: 1.55),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '请输入帖子内容',
                  hintStyle: TextStyle(fontSize: 18, color: Color(0xFFC8CDD4)),
                  alignLabelWithHint: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.only(top: 18),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final image in state.images)
                    _PostImageTile(
                      image: image,
                      enabled: !state.submitting,
                      onRetry: () => controller.upload(image),
                      onRemove: () => controller.remove(image),
                    ),
                  _ImageAddTile(
                    key: const ValueKey('publish_images'),
                    enabled: !state.submitting && state.images.length < 9,
                    onPressed: controller.pickImages,
                  ),
                ],
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
              key: const ValueKey('publish_add_image_tool'),
              icon: Icons.add_photo_alternate_outlined,
              label: '图片',
              enabled: !state.submitting,
              onPressed: controller.pickImages,
            ),
          ],
          auxiliary: [
            _SelectedAuxiliary(
              key: const ValueKey('publish_selected_auxiliary'),
              topic: state.topic,
              hotspot: state.hotspot,
              enabled: !state.submitting,
              onRemoveTopic: () =>
                  controller.removeAuxiliary(PublishAuxiliaryKind.topic),
              onRemoveHotspot: () =>
                  controller.removeAuxiliary(PublishAuxiliaryKind.hotspot),
              onSelectTopic: () =>
                  _selectAuxiliary(PublishAuxiliaryKind.topic, controller),
              onSelectHotspot: () =>
                  _selectAuxiliary(PublishAuxiliaryKind.hotspot, controller),
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

  Future<void> _selectAuxiliary(
    PublishAuxiliaryKind kind,
    PublishPostController controller,
  ) async {
    final item = await context.push<PublishAuxiliaryItem>(
      kind == PublishAuxiliaryKind.topic
          ? '/publish/topic'
          : '/publish/hotspot',
    );
    if (!mounted || item == null) return;
    controller.setAuxiliary(item);
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
    required this.onSelectTopic,
    required this.onSelectHotspot,
    super.key,
  });
  final PublishAuxiliaryItem? topic;
  final PublishAuxiliaryItem? hotspot;
  final bool enabled;
  final VoidCallback onRemoveTopic;
  final VoidCallback onRemoveHotspot;
  final VoidCallback onSelectTopic;
  final VoidCallback onSelectHotspot;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (topic case final value?)
          InputChip(
            key: const ValueKey('publish_topic_chip'),
            label: Text('#${value.name}'),
            backgroundColor: AppColors.brandSoft,
            side: BorderSide.none,
            onDeleted: enabled ? onRemoveTopic : null,
          ),
        if (hotspot case final value?)
          InputChip(
            key: const ValueKey('publish_hotspot_chip'),
            label: Text('热点 · ${value.name}'),
            backgroundColor: AppColors.brandSoft,
            side: BorderSide.none,
            onDeleted: enabled ? onRemoveHotspot : null,
          ),
        if (topic == null)
          _AuxiliaryAction(
            icon: Icons.tag,
            label: '添加话题',
            onPressed: onSelectTopic,
          ),
        if (hotspot == null)
          _AuxiliaryAction(
            icon: Icons.local_fire_department_outlined,
            label: '关联热点事件',
            onPressed: onSelectHotspot,
          ),
      ],
    );
  }
}

class _AuxiliaryAction extends StatelessWidget {
  const _AuxiliaryAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ActionChip(
    avatar: Icon(icon, size: 20),
    label: Text(label),
    onPressed: onPressed,
    side: BorderSide.none,
    backgroundColor: AppColors.surfaceMuted,
    labelStyle: const TextStyle(fontSize: 15, color: AppColors.ink),
  );
}

class _ImageAddTile extends StatelessWidget {
  const _ImageAddTile({
    required this.enabled,
    required this.onPressed,
    super.key,
  });
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 80,
    height: 80,
    child: InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F9),
          border: Border.all(color: const Color(0xFFE3E5EA)),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 32, color: Color(0xFFC8CDD4)),
        ),
      ),
    ),
  );
}

class _PostImageTile extends StatefulWidget {
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
  State<_PostImageTile> createState() => _PostImageTileState();
}

class _PostImageTileState extends State<_PostImageTile> {
  late Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.image.file.readAsBytes();
  }

  @override
  void didUpdateWidget(covariant _PostImageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.file.path != widget.image.file.path) {
      _bytes = widget.image.file.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      SizedBox(
        width: 80,
        height: 80,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: FutureBuilder<Uint8List>(
            future: _bytes,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              }
              if (snapshot.hasError) {
                return const ColoredBox(
                  color: AppColors.surfaceMuted,
                  child: Icon(Icons.broken_image_outlined),
                );
              }
              return const ColoredBox(
                color: AppColors.surfaceMuted,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
        ),
      ),
      if (widget.image.status == UploadStatus.uploading)
        const ColoredBox(
          color: Color(0x66000000),
          child: Center(child: CircularProgressIndicator()),
        ),
      if (widget.image.status == UploadStatus.failure)
        ColoredBox(
          color: const Color(0x88000000),
          child: Center(
            child: TextButton(
              onPressed: widget.enabled ? widget.onRetry : null,
              child: const Text('重试', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      Positioned(
        top: -6,
        right: -6,
        child: IconButton(
          onPressed: widget.enabled ? widget.onRemove : null,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            minimumSize: const Size(28, 28),
            padding: EdgeInsets.zero,
          ),
          icon: const Icon(Icons.close, size: 15),
        ),
      ),
    ],
  );
}

final class PublishedContentNavigation {
  const PublishedContentNavigation();
}
