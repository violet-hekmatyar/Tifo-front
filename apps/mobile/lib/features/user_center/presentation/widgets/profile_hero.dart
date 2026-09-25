import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../domain/user_center_models.dart';

final class ProfileHeroAction {
  const ProfileHeroAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.busy = false,
    this.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;
  final Key? key;
}

class UserProfileHero extends ConsumerWidget {
  const UserProfileHero({
    required this.userId,
    required this.nickname,
    required this.username,
    required this.avatarUrl,
    required this.bio,
    required this.mainTeam,
    required this.contentCount,
    required this.followingCount,
    required this.followerCount,
    required this.likeReceivedCount,
    required this.actions,
    this.relationLabel,
    this.onBack,
    this.onSettings,
    this.onRefresh,
    this.followAction,
    this.followBusy = false,
    super.key,
  });

  final int userId;
  final String nickname;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final EntityBrief? mainTeam;
  final int contentCount;
  final int followingCount;
  final int followerCount;
  final int likeReceivedCount;
  final List<ProfileHeroAction> actions;
  final String? relationLabel;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final VoidCallback? onRefresh;
  final ProfileHeroAction? followAction;
  final bool followBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final initial = nickname.trim().isEmpty ? '我' : nickname.characters.first;
    final team = mainTeam;
    const profileDeepTeal = Color(0xFF143A3B);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        key: const ValueKey('profile_hero_container'),
        constraints: const BoxConstraints(minHeight: 268),
        decoration: const BoxDecoration(color: profileDeepTeal),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/ui/profile/cover-stadium.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: ColoredBox(color: profileDeepTeal.withValues(alpha: .88)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          if (onBack != null)
                            IconButton(
                              key: const ValueKey('profile_hero_back'),
                              onPressed: onBack,
                              color: Colors.white,
                              icon: const Icon(Icons.arrow_back_rounded),
                            )
                          else
                            const SizedBox(width: 48),
                          const Spacer(),
                          if (onSettings != null)
                            IconButton(
                              key: const ValueKey('profile_hero_settings'),
                              onPressed: onSettings,
                              color: Colors.white,
                              icon: const Icon(Icons.settings_outlined),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AppEntityAvatar(
                              key: const ValueKey('profile_hero_avatar'),
                              identity: 'user:$userId',
                              semanticLabel: '$nickname头像',
                              fallbackIcon: Icons.person_outline_rounded,
                              fallbackText: initial,
                              fallbackAsset: 'assets/ui/profile/user-demo.png',
                              imageUrl: resolveMediaUrl(config, avatarUrl),
                              size: 75,
                            ),
                            if (team case final mainTeam?)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: AppEntityAvatar(
                                  identity: 'team:${mainTeam.id}',
                                  semanticLabel: '${mainTeam.name}队徽',
                                  fallbackIcon: Icons.shield_outlined,
                                  imageUrl: resolveMediaUrl(
                                    config,
                                    mainTeam.imageUrl,
                                  ),
                                  size: 27,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            key: const ValueKey('profile_hero_identity'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                width: double.infinity,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    key: const ValueKey('profile_hero_stats'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _Stat(
                                        key: const ValueKey(
                                          'profile_stat_following',
                                        ),
                                        value: followingCount,
                                        label: '关注',
                                        onTap: actions.length > 1
                                            ? actions[1].onPressed
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      _Stat(
                                        key: const ValueKey(
                                          'profile_stat_followers',
                                        ),
                                        value: followerCount,
                                        label: '粉丝',
                                        onTap: actions.length > 2
                                            ? actions[2].onPressed
                                            : null,
                                      ),
                                      const SizedBox(width: 14),
                                      _Stat(
                                        key: const ValueKey(
                                          'profile_stat_likes',
                                        ),
                                        value: likeReceivedCount,
                                        label: '获赞',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (relationLabel case final label?)
                      SizedBox(
                        width: 0,
                        height: 0,
                        child: Opacity(opacity: 0, child: Text(label)),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        bio?.trim().isNotEmpty == true ? bio! : '点击这里，填写简介',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.xs),
                          Expanded(child: _ActionButton(action: actions[i])),
                        ],
                      ],
                    ),
                    if (followAction case final follow?) ...[
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const ValueKey('public_user_follow'),
                          onPressed: followBusy ? null : follow.onPressed,
                          icon: followBusy
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(follow.icon),
                          label: Text(followBusy ? '处理中' : follow.label),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: .18,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.onTap,
    super.key,
  });
  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});
  final ProfileHeroAction action;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: FilledButton.icon(
      key: action.key,
      onPressed: action.busy ? null : action.onPressed,
      icon: action.busy
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(action.icon, size: 19),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(action.label, maxLines: 1),
      ),
      style: FilledButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: .18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
  );
}
