enum FeedFilter {
  recommend('推荐', 'recommend'),
  news('资讯', 'news'),
  following('关注', 'following');

  const FeedFilter(this.label, this.backendTab);

  final String label;
  final String backendTab;
}
