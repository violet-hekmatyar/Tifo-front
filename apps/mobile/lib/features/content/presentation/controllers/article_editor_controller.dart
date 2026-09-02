import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../file_upload/data/file_upload_repository.dart';
import '../../../file_upload/domain/uploaded_file.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../search/domain/search_models.dart';
import '../../data/content_repository.dart';
import '../../domain/content_detail.dart';
import 'publish_post_controller.dart';

enum ArticleEditorStatus { loading, ready, failure }

final class ArticleDraftAsset {
  const ArticleDraftAsset({
    this.file,
    this.uploaded,
    this.existingFileId,
    this.existingUrl,
  });

  final XFile? file;
  final UploadedFile? uploaded;
  final int? existingFileId;
  final String? existingUrl;

  int? get fileId => uploaded?.fileId ?? existingFileId;
}

final class ArticleDraftBlock {
  const ArticleDraftBlock({
    required this.key,
    required this.rawType,
    this.text,
    this.image,
  });

  final int key;
  final String rawType;
  final String? text;
  final ArticleDraftAsset? image;

  ArticleBlockType get type => ArticleBlockType.fromWire(rawType);

  ArticleDraftBlock copy({String? text, ArticleDraftAsset? image}) =>
      ArticleDraftBlock(
        key: key,
        rawType: rawType,
        text: text ?? this.text,
        image: image ?? this.image,
      );
}

final class ArticleEditorState {
  const ArticleEditorState({
    required this.status,
    this.title = '',
    this.summary = '',
    this.cover,
    this.blocks = const [],
    this.relations = const [],
    this.submitting = false,
    this.dirty = false,
    this.message,
  });

  final ArticleEditorStatus status;
  final String title;
  final String summary;
  final ArticleDraftAsset? cover;
  final List<ArticleDraftBlock> blocks;
  final List<SearchEntity> relations;
  final bool submitting;
  final bool dirty;
  final String? message;

  bool get hasDraft => dirty;
}

final articleEditorControllerProvider = ChangeNotifierProvider.autoDispose
    .family<ArticleEditorController, int?>((ref, contentId) {
      final controller = ArticleEditorController(
        contentId: contentId,
        currentUserId: ref.watch(authControllerProvider).state.user?.id,
        contents: ref.watch(contentRepositoryProvider),
        files: ref.watch(fileUploadRepositoryProvider),
        picker: const DeviceGalleryPicker(),
      );
      if (contentId != null) controller.load();
      return controller;
    });

final class ArticleEditorController extends ChangeNotifier {
  ArticleEditorController({
    required this.contentId,
    this.currentUserId,
    required this.contents,
    required this.files,
    required this.picker,
  }) : state = contentId == null
           ? const ArticleEditorState(
               status: ArticleEditorStatus.ready,
               blocks: [ArticleDraftBlock(key: 1, rawType: 'TEXT')],
             )
           : const ArticleEditorState(status: ArticleEditorStatus.loading);

  final int? contentId;
  final int? currentUserId;
  final ContentRepositoryContract contents;
  final FileUploadRepositoryContract files;
  final GalleryPicker picker;
  ArticleEditorState state;
  int _nextKey = 2;
  bool _disposed = false;
  bool _mayReuseExistingFiles = false;

  Future<void> load() async {
    final id = contentId;
    if (id == null) return;
    _setState(const ArticleEditorState(status: ArticleEditorStatus.loading));
    try {
      final detail = await contents.detail(id);
      if (_disposed) return;
      if (detail.contentType != 'ARTICLE') {
        _setState(
          const ArticleEditorState(
            status: ArticleEditorStatus.failure,
            message: '该内容不是可编辑的文章。',
          ),
        );
        return;
      }
      _mayReuseExistingFiles = detail.author.userId == currentUserId;
      final blocks = <ArticleDraftBlock>[];
      for (final block in detail.blocks) {
        blocks.add(
          ArticleDraftBlock(
            key: _nextKey++,
            rawType: block.rawType,
            text: block.text,
            image: block.type == ArticleBlockType.image
                ? ArticleDraftAsset(
                    existingFileId: _mayReuseExistingFiles
                        ? block.mediaFileId ?? _publicFileId(block.mediaUrl)
                        : null,
                    existingUrl: block.mediaUrl,
                  )
                : null,
          ),
        );
      }
      if (blocks.isEmpty) {
        blocks.add(
          ArticleDraftBlock(
            key: _nextKey++,
            rawType: 'TEXT',
            text: detail.body,
          ),
        );
      }
      _setState(
        ArticleEditorState(
          status: ArticleEditorStatus.ready,
          title: detail.title,
          summary: detail.summary ?? '',
          cover: detail.coverUrl == null
              ? null
              : ArticleDraftAsset(
                  existingFileId: _mayReuseExistingFiles
                      ? _publicFileId(detail.coverUrl)
                      : null,
                  existingUrl: detail.coverUrl,
                ),
          blocks: blocks,
          relations: detail.relations
              .map(
                (relation) => SearchEntity(
                  type: SearchEntityType.fromWire(relation.type),
                  rawType: relation.type,
                  entityId: relation.id,
                  name: relation.name,
                ),
              )
              .toList(growable: false),
        ),
      );
    } on AppNetworkException catch (error) {
      if (_disposed) return;
      _setState(
        ArticleEditorState(
          status: ArticleEditorStatus.failure,
          message: error.message,
        ),
      );
    }
  }

  void markDirty() {
    if (!state.dirty) _copy(dirty: true, clearMessage: true);
  }

  void addTextBlock() {
    _copy(
      blocks: [
        ...state.blocks,
        ArticleDraftBlock(key: _nextKey++, rawType: 'TEXT'),
      ],
      dirty: true,
      clearMessage: true,
    );
  }

  Future<void> addImageBlocks() async {
    final picked = await picker.pickImages();
    if (_disposed || picked.isEmpty) return;
    _copy(
      blocks: [
        ...state.blocks,
        for (final file in picked)
          ArticleDraftBlock(
            key: _nextKey++,
            rawType: 'IMAGE',
            image: ArticleDraftAsset(file: file),
          ),
      ],
      dirty: true,
      clearMessage: true,
    );
  }

  Future<void> pickCover() async {
    final picked = await picker.pickImages();
    if (_disposed || picked.isEmpty) return;
    if (state.cover?.uploaded case final uploaded?) {
      try {
        await files.delete(uploaded.fileId);
      } catch (_) {}
      if (_disposed) return;
    }
    _copy(
      cover: ArticleDraftAsset(file: picked.first),
      dirty: true,
      clearMessage: true,
    );
  }

  void updateText(int key, String value) {
    _copy(
      blocks: [
        for (final block in state.blocks)
          if (block.key == key) block.copy(text: value) else block,
      ],
      dirty: true,
      clearMessage: true,
    );
  }

  Future<void> removeBlock(int key) async {
    final block = state.blocks.where((item) => item.key == key).firstOrNull;
    if (block?.image?.uploaded case final uploaded?) {
      try {
        await files.delete(uploaded.fileId);
      } catch (_) {}
    }
    if (_disposed) return;
    _copy(
      blocks: state.blocks.where((item) => item.key != key).toList(),
      dirty: true,
      clearMessage: true,
    );
  }

  void moveBlock(int index, int direction) {
    final target = index + direction;
    if (target < 0 || target >= state.blocks.length) return;
    final blocks = List<ArticleDraftBlock>.of(state.blocks);
    final value = blocks.removeAt(index);
    blocks.insert(target, value);
    _copy(blocks: blocks, dirty: true, clearMessage: true);
  }

  void setRelations(List<SearchEntity> relations) {
    final unique = <String, SearchEntity>{};
    for (final relation in relations) {
      if (relation.entityId == null ||
          !const {
            SearchEntityType.team,
            SearchEntityType.player,
            SearchEntityType.match,
          }.contains(relation.type)) {
        continue;
      }
      unique[relation.stableKey] = relation;
      if (unique.length == 10) break;
    }
    _copy(
      relations: unique.values.toList(growable: false),
      dirty: true,
      clearMessage: true,
    );
  }

  void removeRelation(SearchEntity relation) {
    setRelations(
      state.relations
          .where((item) => item.stableKey != relation.stableKey)
          .toList(),
    );
  }

  Future<int?> submit(String title, String summary) async {
    if (state.submitting) return null;
    final normalizedTitle = title.trim();
    final normalizedSummary = summary.trim();
    if (normalizedTitle.isEmpty || normalizedTitle.length > 200) {
      _copy(message: '请填写不超过 200 字的文章标题。');
      return null;
    }
    if (state.blocks.any((block) => block.type == ArticleBlockType.unknown)) {
      _copy(message: '文章包含暂不支持的段落，请删除后再保存。');
      return null;
    }
    _copy(submitting: true, clearMessage: true);
    try {
      var cover = state.cover;
      if (cover?.file == null &&
          cover?.uploaded == null &&
          cover?.existingFileId == null &&
          cover?.existingUrl != null) {
        final uploaded = await _retainUpload(
          files.copyRemoteImage(cover!.existingUrl!),
        );
        if (uploaded == null) return null;
        cover = ArticleDraftAsset(
          existingUrl: cover.existingUrl,
          uploaded: uploaded,
        );
        _copy(cover: cover, submitting: true);
      }
      if (cover?.file != null && cover?.uploaded == null) {
        final uploaded = await _retainUpload(
          files.upload(cover!.file!.path, cover.file!.name),
        );
        if (uploaded == null) return null;
        cover = ArticleDraftAsset(file: cover.file, uploaded: uploaded);
        _copy(cover: cover, submitting: true);
      }
      var uploadedBlocks = List<ArticleDraftBlock>.of(state.blocks);
      for (final block in state.blocks) {
        var current = block;
        if (block.type == ArticleBlockType.image &&
            block.image?.file == null &&
            block.image?.uploaded == null &&
            block.image?.existingFileId == null &&
            block.image?.existingUrl != null) {
          final uploaded = await _retainUpload(
            files.copyRemoteImage(block.image!.existingUrl!),
          );
          if (uploaded == null) return null;
          current = block.copy(
            image: ArticleDraftAsset(
              existingUrl: block.image!.existingUrl,
              uploaded: uploaded,
            ),
          );
          uploadedBlocks = [
            for (final candidate in uploadedBlocks)
              if (candidate.key == current.key) current else candidate,
          ];
          _copy(blocks: uploadedBlocks, submitting: true);
        }
        if (block.type == ArticleBlockType.image &&
            block.image?.file != null &&
            block.image?.uploaded == null) {
          final file = block.image!.file!;
          final uploaded = await _retainUpload(
            files.upload(file.path, file.name),
          );
          if (uploaded == null) return null;
          current = block.copy(
            image: ArticleDraftAsset(file: file, uploaded: uploaded),
          );
          uploadedBlocks = [
            for (final candidate in uploadedBlocks)
              if (candidate.key == current.key) current else candidate,
          ];
          _copy(blocks: uploadedBlocks, submitting: true);
        }
      }
      if (_disposed) return null;
      _copy(cover: cover, blocks: uploadedBlocks, submitting: true);
      final inputs = <ArticleBlockInput>[];
      for (var index = 0; index < uploadedBlocks.length; index++) {
        final block = uploadedBlocks[index];
        final text = block.text?.trim();
        if (block.type == ArticleBlockType.text && text?.isNotEmpty != true) {
          continue;
        }
        if (block.type == ArticleBlockType.image &&
            block.image?.fileId == null) {
          continue;
        }
        inputs.add(
          ArticleBlockInput(
            blockType: block.rawType,
            text: text,
            mediaFileId: block.image?.fileId,
            sortOrder: inputs.length + 1,
          ),
        );
      }
      if (inputs.isEmpty) {
        _copy(submitting: false, message: '请至少添加一个文字或图片段落。');
        return null;
      }
      final request = ArticleRequest(
        title: normalizedTitle,
        summary: normalizedSummary.isEmpty ? null : normalizedSummary,
        coverFileId: cover?.fileId,
        blocks: inputs,
        relations: state.relations
            .where((entity) => entity.entityId != null)
            .map(
              (entity) => ContentRelationInput(
                type: entity.type.wireValue,
                id: entity.entityId!,
              ),
            )
            .toList(growable: false),
      );
      final id = contentId;
      final result = id == null
          ? await contents
                .createArticle(request)
                .then((value) => value.contentId)
          : await contents
                .updateArticle(id, request)
                .then((value) => value.contentId);
      if (_disposed) return null;
      _setState(const ArticleEditorState(status: ArticleEditorStatus.ready));
      return result;
    } on AppNetworkException catch (error) {
      if (_disposed) return null;
      _copy(submitting: false, message: error.message);
      return null;
    } catch (_) {
      if (_disposed) return null;
      _copy(submitting: false, message: '文章保存失败，草稿已保留。');
      return null;
    }
  }

  Future<void> cleanupDraft() async {
    final ids = <int>{
      if (state.cover?.uploaded case final uploaded?) uploaded.fileId,
      for (final block in state.blocks)
        if (block.image?.uploaded case final uploaded?) uploaded.fileId,
    };
    for (final id in ids) {
      try {
        await files.delete(id);
      } catch (_) {}
    }
  }

  Future<UploadedFile?> _retainUpload(Future<UploadedFile> pending) async {
    final uploaded = await pending;
    if (!_disposed) return uploaded;
    try {
      await files.delete(uploaded.fileId);
    } catch (_) {}
    return null;
  }

  void _copy({
    ArticleDraftAsset? cover,
    List<ArticleDraftBlock>? blocks,
    List<SearchEntity>? relations,
    bool? submitting,
    bool? dirty,
    String? message,
    bool clearMessage = false,
  }) {
    _setState(
      ArticleEditorState(
        status: state.status,
        title: state.title,
        summary: state.summary,
        cover: cover ?? state.cover,
        blocks: blocks ?? state.blocks,
        relations: relations ?? state.relations,
        submitting: submitting ?? state.submitting,
        dirty: dirty ?? state.dirty,
        message: clearMessage ? null : message ?? state.message,
      ),
    );
  }

  void _setState(ArticleEditorState value) {
    state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

int? _publicFileId(String? value) {
  final segments = Uri.tryParse(value ?? '')?.pathSegments;
  if (segments == null ||
      segments.length < 4 ||
      segments[segments.length - 4] != 'api' ||
      segments[segments.length - 3] != 'public' ||
      segments[segments.length - 2] != 'files') {
    return null;
  }
  return int.tryParse(segments.last);
}
