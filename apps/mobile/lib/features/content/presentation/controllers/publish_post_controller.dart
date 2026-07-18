import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import '../../../file_upload/data/file_upload_repository.dart';
import '../../../file_upload/domain/uploaded_file.dart';
import '../../data/content_repository.dart';

enum UploadStatus { waiting, uploading, success, failure }

final class PublishImage {
  const PublishImage({
    required this.file,
    required this.status,
    this.uploaded,
    this.message,
  });
  final XFile file;
  final UploadStatus status;
  final UploadedFile? uploaded;
  final String? message;
  PublishImage copy({
    UploadStatus? status,
    UploadedFile? uploaded,
    String? message,
  }) => PublishImage(
    file: file,
    status: status ?? this.status,
    uploaded: uploaded ?? this.uploaded,
    message: message,
  );
}

final class PublishState {
  const PublishState({
    this.images = const [],
    this.submitting = false,
    this.message,
  });
  final List<PublishImage> images;
  final bool submitting;
  final String? message;
  bool get hasDraft => images.isNotEmpty;
}

final publishPostControllerProvider =
    ChangeNotifierProvider.autoDispose<PublishPostController>(
      (ref) => PublishPostController(
        ref.watch(contentRepositoryProvider),
        ref.watch(fileUploadRepositoryProvider),
        const DeviceGalleryPicker(),
      ),
    );

final class PublishPostController extends ChangeNotifier {
  PublishPostController(this.contents, this.files, this.picker);
  final ContentRepositoryContract contents;
  final FileUploadRepositoryContract files;
  final GalleryPicker picker;
  PublishState state = const PublishState();
  bool _disposed = false;
  Future<void> pickImages() async {
    final picked = await picker.pickImages();
    if (_disposed) return;
    final existing = {for (final image in state.images) image.file.path: image};
    for (final file in picked) {
      if (existing.length >= 9) break;
      final ext = file.name.split('.').last.toLowerCase();
      final size = await file.length();
      if (!{'jpg', 'jpeg', 'png', 'webp', 'gif'}.contains(ext) ||
          size > 10 * 1024 * 1024) {
        continue;
      }
      existing.putIfAbsent(
        file.path,
        () => PublishImage(file: file, status: UploadStatus.waiting),
      );
    }
    state = PublishState(
      images: existing.values.toList(),
      message: picked.length > 9 ? '最多选择 9 张图片' : null,
    );
    notifyListeners();
  }

  Future<void> remove(PublishImage image) async {
    if (image.uploaded != null) {
      try {
        await files.delete(image.uploaded!.fileId);
      } catch (_) {}
    }
    if (_disposed) return;
    state = PublishState(
      images: state.images
          .where((x) => x.file.path != image.file.path)
          .toList(),
      message: state.message,
    );
    notifyListeners();
  }

  Future<void> cleanupDraft() async {
    final uploaded = state.images
        .where((image) => image.uploaded != null)
        .map((image) => image.uploaded!.fileId)
        .toList();
    for (final fileId in uploaded) {
      try {
        await files.delete(fileId);
      } catch (_) {
        // Best effort: the backend also owns lifecycle cleanup for orphan files.
      }
    }
    if (_disposed) return;
    state = const PublishState();
    notifyListeners();
  }

  Future<void> upload(PublishImage image) async {
    if (image.status == UploadStatus.uploading ||
        image.status == UploadStatus.success) {
      return;
    }
    _replace(image, image.copy(status: UploadStatus.uploading));
    try {
      final uploaded = await files.upload(image.file.path, image.file.name);
      if (_disposed) return;
      _replace(
        image,
        image.copy(status: UploadStatus.success, uploaded: uploaded),
      );
    } catch (e) {
      if (_disposed) return;
      _replace(
        image,
        image.copy(status: UploadStatus.failure, message: '上传失败，请重试'),
      );
    }
  }

  Future<int?> publish(String title, String body) async {
    if (state.submitting) return null;
    final t = title.trim(), b = body.trim();
    if (t.isEmpty ||
        t.length > 255 ||
        b.length > 2000 ||
        (b.isEmpty && state.images.isEmpty)) {
      state = PublishState(images: state.images, message: '请填写标题，并输入正文或选择图片');
      notifyListeners();
      return null;
    }
    state = PublishState(images: state.images, submitting: true);
    notifyListeners();
    for (final image in List.of(state.images)) {
      if (image.status != UploadStatus.success) await upload(image);
    }
    if (state.images.any((x) => x.status != UploadStatus.success)) {
      state = PublishState(images: state.images, message: '部分图片上传失败');
      notifyListeners();
      return null;
    }
    try {
      final post = await contents.createPost(
        title: t,
        body: b,
        mediaFileIds: state.images.map((x) => x.uploaded!.fileId).toList(),
      );
      if (_disposed) return null;
      state = const PublishState();
      notifyListeners();
      return post.contentId;
    } catch (e) {
      if (_disposed) return null;
      state = PublishState(images: state.images, message: '发布失败，内容已保留');
      notifyListeners();
      return null;
    }
  }

  void _replace(PublishImage old, PublishImage next) {
    state = PublishState(
      images: [
        for (final x in state.images)
          if (x.file.path == old.file.path) next else x,
      ],
      submitting: state.submitting,
      message: state.message,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

abstract interface class GalleryPicker {
  Future<List<XFile>> pickImages();
}

final class DeviceGalleryPicker implements GalleryPicker {
  const DeviceGalleryPicker();
  @override
  Future<List<XFile>> pickImages() =>
      ImagePicker().pickMultiImage(limit: 9, imageQuality: null);
}
