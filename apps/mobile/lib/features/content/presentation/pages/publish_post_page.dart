import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../controllers/publish_post_controller.dart';

class PublishPostPage extends ConsumerStatefulWidget {
  const PublishPostPage({super.key});
  @override
  ConsumerState<PublishPostPage> createState() => _PublishPostPageState();
}

class _PublishPostPageState extends ConsumerState<PublishPostPage> {
  final title = TextEditingController(), body = TextEditingController();
  bool _published = false;
  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  bool get hasText =>
      title.text.trim().isNotEmpty || body.text.trim().isNotEmpty;
  @override
  Widget build(BuildContext context) {
    final c = ref.watch(publishPostControllerProvider);
    final s = c.state;
    return PopScope(
      canPop: _published || (!hasText && !s.hasDraft),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('放弃未发布内容？'),
            content: const Text('已上传但未绑定的图片会尽力清理。'),
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
          await c.cleanupDraft();
          if (context.mounted) context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('发布帖子'),
          actions: [
            TextButton(
              onPressed: s.submitting
                  ? null
                  : () async {
                      final id = await c.publish(title.text, body.text);
                      if (id != null && context.mounted) {
                        setState(() => _published = true);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!context.mounted) return;
                          context.pushReplacement(
                            '/contents/$id',
                            extra: const PublishedContentNavigation(),
                          );
                        });
                      }
                    },
              child: Text(
                s.submitting ? '发布中…' : '发布',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              controller: title,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '给帖子一个清晰标题',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: body,
              maxLength: 2000,
              minLines: 6,
              maxLines: 14,
              decoration: const InputDecoration(
                labelText: '正文',
                hintText: '说说你的足球观点…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  '图片 ${s.images.length}/9',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: s.images.length >= 9 ? null : c.pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('从相册选择'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (s.images.isEmpty)
              const Text(
                '可发布纯文字帖子；仅支持 jpg/png/webp/gif，单张不超过 10MB。',
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
                itemCount: s.images.length,
                itemBuilder: (context, index) {
                  final image = s.images[index];
                  return Stack(
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
                              onPressed: () => c.upload(image),
                              child: const Text(
                                '重试',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton.filled(
                          onPressed: s.submitting
                              ? null
                              : () => c.remove(image),
                          icon: const Icon(Icons.close, size: 16),
                        ),
                      ),
                    ],
                  );
                },
              ),
            if (s.message != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  s.message!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class PublishedContentNavigation {
  const PublishedContentNavigation();
}
