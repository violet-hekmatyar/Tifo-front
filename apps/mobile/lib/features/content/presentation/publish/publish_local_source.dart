import 'package:flutter/foundation.dart';

enum PublishAuxiliaryKind { topic, hotspot }

@immutable
final class PublishAuxiliaryItem {
  const PublishAuxiliaryItem({
    required this.id,
    required this.name,
    required this.count,
    required this.kind,
  });

  final String id;
  final String name;
  final int count;
  final PublishAuxiliaryKind kind;
}

/// Presentation-only fixtures for the publish prototype.
/// These values never enter a createPost request.
abstract final class PublishLocalSource {
  static const topics = <PublishAuxiliaryItem>[
    PublishAuxiliaryItem(
      id: 'topic-premier-league',
      name: '英超焦点',
      count: 12800,
      kind: PublishAuxiliaryKind.topic,
    ),
    PublishAuxiliaryItem(
      id: 'topic-champions-league',
      name: '欧冠联赛',
      count: 9600,
      kind: PublishAuxiliaryKind.topic,
    ),
    PublishAuxiliaryItem(
      id: 'topic-transfer-window',
      name: '转会市场',
      count: 7300,
      kind: PublishAuxiliaryKind.topic,
    ),
    PublishAuxiliaryItem(
      id: 'topic-national-team',
      name: '国家队赛事',
      count: 5100,
      kind: PublishAuxiliaryKind.topic,
    ),
  ];

  static const hotspots = <PublishAuxiliaryItem>[
    PublishAuxiliaryItem(
      id: 'hotspot-matchday',
      name: '本轮焦点战',
      count: 8600,
      kind: PublishAuxiliaryKind.hotspot,
    ),
    PublishAuxiliaryItem(
      id: 'hotspot-final',
      name: '决赛前瞻',
      count: 6400,
      kind: PublishAuxiliaryKind.hotspot,
    ),
    PublishAuxiliaryItem(
      id: 'hotspot-lineup',
      name: '首发阵容猜想',
      count: 4200,
      kind: PublishAuxiliaryKind.hotspot,
    ),
  ];

  static List<PublishAuxiliaryItem> filter(
    PublishAuxiliaryKind kind,
    String keyword,
  ) {
    final source = kind == PublishAuxiliaryKind.topic ? topics : hotspots;
    final query = keyword.trim().toLowerCase();
    if (query.isEmpty) return source;
    return source
        .where((item) => item.name.toLowerCase().contains(query))
        .toList(growable: false);
  }
}
