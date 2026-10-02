import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_state_illustration.dart';
import '../../data/user_center_repository.dart';
import '../../domain/user_center_models.dart';
import '../controllers/user_center_controllers.dart';

class FollowedEntitiesPage extends ConsumerStatefulWidget {
  const FollowedEntitiesPage({required this.teams, super.key});
  final bool teams;

  @override
  ConsumerState<FollowedEntitiesPage> createState() =>
      _FollowedEntitiesPageState();
}

class _FollowedEntitiesPageState extends ConsumerState<FollowedEntitiesPage> {
  final Set<int> _busy = {};
  final Set<int> _removed = {};
  String? _message;

  Future<void> _toggle(EntityBrief item) async {
    if (item.id <= 0 || _busy.contains(item.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认取消关注'),
        content: Text('确认取消关注 ${item.name}？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy.add(item.id);
      _removed.add(item.id);
      _message = null;
    });
    try {
      final followed = await ref
          .read(userCenterRepositoryProvider)
          .toggleEntity(widget.teams ? 'TEAM' : 'PLAYER', item.id);
      if (followed) {
        if (mounted) {
          setState(() {
            _removed.remove(item.id);
            _message = '${item.name} 仍处于关注状态。';
          });
        }
      } else {
        ref.invalidate(myStandProvider);
        ref.invalidate(mySummaryProvider);
        ref.invalidate(myProfileControllerProvider);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _removed.remove(item.id);
          _message = '操作失败，关注状态已保留，请重试。';
        });
      }
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(myStandProvider);
    final title = widget.teams ? '关注的球队' : '关注的球员';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: value.when(
        loading: () => AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载$title',
          message: '正在读取真实关注关系。',
        ),
        error: (_, _) => AppStateView(
          kind: AppStateKind.error,
          title: '$title加载失败',
          message: '请检查网络后重试。',
          onRetry: () => ref.invalidate(myStandProvider),
        ),
        data: (stand) {
          final all = widget.teams ? stand.teams : stand.players;
          final items = all
              .where((item) => !_removed.contains(item.id))
              .toList();
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(myStandProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 500,
                    child: AppStateView(
                      kind: AppStateKind.empty,
                      title: '暂无$title',
                      message: '你还没有关注任何${widget.teams ? '球队' : '球员'}。',
                      illustration: widget.teams
                          ? AppStateIllustrationType.noFollowingTeams
                          : AppStateIllustrationType.noFollowing,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myStandProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      _message!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                for (final item in items) _row(item),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(EntityBrief item) {
    final config = ref.read(appConfigProvider);
    final busy = _busy.contains(item.id);
    return Card(
      key: ValueKey('${widget.teams ? 'team' : 'player'}-followed-${item.id}'),
      child: ListTile(
        leading: AppEntityAvatar(
          identity: '${widget.teams ? 'team' : 'player'}:${item.id}',
          semanticLabel: '${item.name}图片',
          fallbackIcon: widget.teams
              ? Icons.shield_outlined
              : Icons.person_outline_rounded,
          fallbackText: item.name,
          imageUrl: resolveMediaUrl(config, item.imageUrl),
          size: 48,
        ),
        title: Text(item.name),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
        onTap: item.id > 0
            ? () => context.push(
                widget.teams ? '/teams/${item.id}' : '/players/${item.id}',
              )
            : null,
        trailing: TextButton(
          key: ValueKey(
            '${widget.teams ? 'team' : 'player'}-unfollow-${item.id}',
          ),
          onPressed: busy ? null : () => _toggle(item),
          child: Text(busy ? '处理中' : '取消关注'),
        ),
      ),
    );
  }
}
