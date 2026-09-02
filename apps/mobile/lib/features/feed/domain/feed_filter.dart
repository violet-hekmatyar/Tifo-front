import '../../../core/network/backend_v1_contract.dart';

enum FeedFilter {
  recommend('推荐', FeedTab.recommend),
  news('资讯', FeedTab.news),
  following('关注', FeedTab.following);

  const FeedFilter(this.label, this.tab);

  final String label;
  final FeedTab tab;
}
