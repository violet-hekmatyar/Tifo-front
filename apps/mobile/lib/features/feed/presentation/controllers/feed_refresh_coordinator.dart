import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final class FeedRefreshRequest {
  const FeedRefreshRequest({required this.contentId, required this.serial});

  final int contentId;
  final int serial;
}

final feedRefreshRequestProvider = StateProvider<FeedRefreshRequest?>(
  (ref) => null,
);

void requestPublishedContentFeedRefresh(WidgetRef ref, int contentId) {
  final previous = ref.read(feedRefreshRequestProvider);
  ref.read(feedRefreshRequestProvider.notifier).state = FeedRefreshRequest(
    contentId: contentId,
    serial: (previous?.serial ?? 0) + 1,
  );
}
