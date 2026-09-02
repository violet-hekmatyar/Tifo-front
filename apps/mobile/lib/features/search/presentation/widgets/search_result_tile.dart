import 'package:flutter/material.dart';

import '../../../../app/config/app_config.dart';
import '../../../../core/network/backend_v1_contract.dart';
import '../../../../core/network/media_url_resolver.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/search_models.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    required this.entity,
    required this.config,
    required this.onTap,
    this.selected = false,
    super.key,
  });

  final SearchEntity entity;
  final AppConfig config;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.brandSoft : AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            _leading(),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entity.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _TypeBadge(type: entity.type),
                    ],
                  ),
                  if (_subtitle case final subtitle?) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? AppColors.brand : AppColors.inkMuted,
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _leading() {
    final image = resolveMediaUrl(config, entity.logoUrl ?? entity.avatarUrl);
    return switch (entity.type) {
      SearchEntityType.team => AppTeamLogo(
        identity: entity.stableKey,
        name: entity.name,
        imageUrl: image,
        size: 48,
      ),
      SearchEntityType.player => AppPlayerAvatar(
        identity: entity.stableKey,
        name: entity.name,
        imageUrl: image,
        size: 48,
      ),
      SearchEntityType.match => AppEntityAvatar(
        identity: entity.stableKey,
        semanticLabel: '${entity.name}比赛',
        fallbackIcon: Icons.sports_soccer_rounded,
        size: 48,
      ),
      SearchEntityType.content => AppEntityAvatar(
        identity: entity.stableKey,
        semanticLabel: '${entity.name}内容封面',
        fallbackIcon: Icons.article_outlined,
        imageUrl: image,
        size: 48,
        circular: false,
      ),
      SearchEntityType.unknown => AppEntityAvatar(
        identity: entity.stableKey,
        semanticLabel: '未知搜索结果',
        fallbackIcon: Icons.help_outline_rounded,
        size: 48,
      ),
    };
  }

  String? get _subtitle {
    final text = entity.subtitle?.trim();
    if (text?.isNotEmpty == true) return text;
    final english = entity.nameEn?.trim();
    return english?.isNotEmpty == true ? english : null;
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final SearchEntityType type;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: AppColors.brandSoft,
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Text(
      switch (type) {
        SearchEntityType.team => '球队',
        SearchEntityType.player => '球员',
        SearchEntityType.match => '比赛',
        SearchEntityType.content => '内容',
        SearchEntityType.unknown => '未知',
      },
      style: const TextStyle(
        color: AppColors.brandDark,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
