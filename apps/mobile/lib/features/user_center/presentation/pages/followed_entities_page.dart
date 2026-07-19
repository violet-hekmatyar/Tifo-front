import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_state_view.dart';
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
  String? _message;
  Future<void> _toggle(EntityBrief item) async {
    if (_busy.contains(item.id)) return;
    setState(() {
      _busy.add(item.id);
      _message = null;
    });
    try {
      await ref
          .read(userCenterRepositoryProvider)
          .toggleEntity(widget.teams ? 'TEAM' : 'PLAYER', item.id);
      ref.invalidate(myStandProvider);
      ref.invalidate(mySummaryProvider);
    } catch (_) {
      setState(() => _message = '操作失败，关注状态已保留，请重试。');
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
          final items = widget.teams ? stand.teams : stand.players;
          if (items.isEmpty) {
            return AppStateView(
              kind: AppStateKind.empty,
              title: '暂无$title',
              message: '你还没有关注任何${widget.teams ? '球队' : '球员'}。',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myStandProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      _message!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                for (final item in items)
                  Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: item.subtitle == null
                          ? null
                          : Text(item.subtitle!),
                      leading: Icon(
                        widget.teams
                            ? Icons.shield_outlined
                            : Icons.person_outline_rounded,
                      ),
                      onTap: () => context.push(
                        widget.teams
                            ? '/teams/${item.id}'
                            : '/players/${item.id}',
                      ),
                      trailing: TextButton(
                        onPressed: _busy.contains(item.id)
                            ? null
                            : () => _toggle(item),
                        child: Text(_busy.contains(item.id) ? '处理中' : '取消关注'),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
