import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../interaction/data/interaction_repository.dart';
import '../../data/content_repository.dart';
import '../../domain/content_detail.dart';

enum DetailStatus { loading, ready, failure, notFound }

final class ContentDetailState {
  const ContentDetailState({
    required this.status,
    this.detail,
    this.message,
    this.likeBusy = false,
    this.favoriteBusy = false,
  });
  final DetailStatus status;
  final ContentDetail? detail;
  final String? message;
  final bool likeBusy;
  final bool favoriteBusy;
}

final contentDetailControllerProvider = ChangeNotifierProvider.autoDispose
    .family<ContentDetailController, int>(
      (ref, id) => ContentDetailController(
        id,
        ref.watch(contentRepositoryProvider),
        ref.watch(interactionRepositoryProvider),
      )..load(),
    );

final class ContentDetailController extends ChangeNotifier {
  ContentDetailController(this.id, this.contentRepository, this.interactions);
  final int id;
  final ContentRepositoryContract contentRepository;
  final InteractionRepositoryContract interactions;
  ContentDetailState state = const ContentDetailState(
    status: DetailStatus.loading,
  );
  bool _disposed = false;
  Future<void> load() async {
    if (id <= 0) {
      state = const ContentDetailState(
        status: DetailStatus.notFound,
        message: '内容编号无效',
      );
      notifyListeners();
      return;
    }
    state = ContentDetailState(
      status: DetailStatus.loading,
      detail: state.detail,
    );
    notifyListeners();
    try {
      final value = await contentRepository.detail(id);
      if (_disposed) return;
      state = ContentDetailState(status: DetailStatus.ready, detail: value);
      notifyListeners();
    } on BusinessException catch (e) {
      if (_disposed) return;
      state = ContentDetailState(
        status: e.code == 40401 ? DetailStatus.notFound : DetailStatus.failure,
        message: e.code == 40401 ? '内容不存在或已下架' : e.message,
      );
      notifyListeners();
    } on AppNetworkException {
      if (_disposed) return;
      state = const ContentDetailState(
        status: DetailStatus.failure,
        message: '内容加载失败，请重试。',
      );
      notifyListeners();
    }
  }

  Future<bool> toggleLike() async {
    final d = state.detail;
    if (d == null || state.likeBusy) return false;
    state = ContentDetailState(
      status: state.status,
      detail: d.interactionCopy(
        liked: !d.liked,
        likeCount: (d.likeCount + (d.liked ? -1 : 1)).clamp(0, 1 << 31),
      ),
      message: state.message,
      likeBusy: true,
      favoriteBusy: state.favoriteBusy,
    );
    notifyListeners();
    try {
      final result = await interactions.toggleLike(id);
      await load();
      return result.active;
    } on AppNetworkException catch (e) {
      if (_disposed) return false;
      state = ContentDetailState(
        status: DetailStatus.ready,
        detail: d,
        message: e.message,
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleFavorite() async {
    final d = state.detail;
    if (d == null || state.favoriteBusy) return false;
    state = ContentDetailState(
      status: state.status,
      detail: d.interactionCopy(
        favorited: !d.favorited,
        favoriteCount: (d.favoriteCount + (d.favorited ? -1 : 1)).clamp(
          0,
          1 << 31,
        ),
      ),
      message: state.message,
      likeBusy: state.likeBusy,
      favoriteBusy: true,
    );
    notifyListeners();
    try {
      final result = await interactions.toggleFavorite(id);
      await load();
      return result.active;
    } on AppNetworkException catch (e) {
      if (_disposed) return false;
      state = ContentDetailState(
        status: DetailStatus.ready,
        detail: d,
        message: e.message,
      );
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
