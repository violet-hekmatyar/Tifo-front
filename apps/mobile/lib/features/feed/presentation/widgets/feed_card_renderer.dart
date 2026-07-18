import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../domain/feed_card.dart';
import 'content_card.dart';
import 'match_card.dart';
import 'unknown_card.dart';

class FeedCardRenderer extends ConsumerWidget {
  const FeedCardRenderer({required this.card, super.key});

  final FeedCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return switch (card) {
      ContentFeedCard card => ContentCard(
        card: card,
        coverUrl: resolveMediaUrl(config, card.coverUrl),
        authorAvatarUrl: resolveMediaUrl(config, card.author?.avatarUrl),
        onTap: () =>
            context.push('/contents/${card.contentId}', extra: card.title),
      ),
      MatchFeedCard card => MatchCard(
        card: card,
        homeLogoUrl: resolveMediaUrl(config, card.homeTeam.logoUrl),
        awayLogoUrl: resolveMediaUrl(config, card.awayTeam.logoUrl),
        onTap: () => context.push('/match/${card.matchId}'),
      ),
      UnknownFeedCard card => UnknownCard(card: card),
    };
  }
}
