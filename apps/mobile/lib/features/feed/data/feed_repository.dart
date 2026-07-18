import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/feed_filter.dart';
import '../domain/feed_page.dart';
import 'feed_api.dart';

abstract interface class FeedRepositoryContract {
  Future<FeedPage> loadFeed({
    required FeedFilter filter,
    required int pageNum,
    required int pageSize,
    int? teamId,
  });

  Future<List<FollowedTeam>> loadFollowedTeams();
}

final feedRepositoryProvider = Provider<FeedRepositoryContract>(
  (ref) => FeedRepository(FeedApi(ref.watch(apiClientProvider))),
);

final class FeedRepository implements FeedRepositoryContract {
  const FeedRepository(this._api);

  final FeedApi _api;

  @override
  Future<FeedPage> loadFeed({
    required FeedFilter filter,
    required int pageNum,
    required int pageSize,
    int? teamId,
  }) => _api.feed(
    tab: teamId == null ? filter.backendTab : 'team',
    pageNum: pageNum,
    pageSize: pageSize,
    teamId: teamId,
  );

  @override
  Future<List<FollowedTeam>> loadFollowedTeams() => _api.followedTeams();
}
