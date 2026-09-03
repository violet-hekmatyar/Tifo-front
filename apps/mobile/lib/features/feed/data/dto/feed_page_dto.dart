import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/json_value.dart';
import '../../../../core/network/page_result.dart';
import '../../domain/feed_card.dart';
import '../../domain/feed_page.dart';
import 'feed_card_dto.dart';

final class FeedPageDto {
  const FeedPageDto(this.page);

  factory FeedPageDto.fromRaw(Object? raw) {
    final map = jsonMap(raw);
    final attribution = RecommendationAttribution(
      algorithmVersion: jsonString(map?['algorithmVersion']),
      modelVersion: jsonString(map?['modelVersion']),
      experimentId: jsonString(map?['experimentId']),
      experimentBucket: jsonString(map?['experimentBucket']),
      requestId: jsonString(map?['requestId']),
    );
    final page = PageResult<FeedCard>.fromRaw(
      raw,
      (item) =>
          FeedCardDto.fromRaw(item, pageAttribution: attribution).toDomain(),
    );
    return FeedPageDto(
      FeedPage(
        cards: page.records,
        total: page.total,
        pageNum: page.pageNum,
        pageSize: page.pageSize,
        pages: page.pages,
        nextCursor: jsonString(map?['nextCursor']),
        attribution: attribution,
      ),
    );
  }

  final FeedPage page;

  FeedPage toDomain() => page;
}
