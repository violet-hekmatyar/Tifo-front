import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../../domain/football_models.dart';
import '../controllers/football_detail_providers.dart';
import '../widgets/football_widgets.dart';
import 'team_detail_page.dart';

class PlayerDetailPage extends ConsumerStatefulWidget {
  const PlayerDetailPage({required this.playerId, super.key});
  final int playerId;
  @override
  ConsumerState<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends ConsumerState<PlayerDetailPage> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(playerDetailProvider(widget.playerId));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/app/data'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('球员详情'),
      ),
      body: async.when(
        loading: () => const AppStateView(
          kind: AppStateKind.loading,
          title: '正在加载球员',
          message: '正在读取球员资料…',
        ),
        error: (error, _) => FootballDetailError(
          target: '球员',
          error: error,
          onRetry: () => ref.invalidate(playerDetailProvider(widget.playerId)),
        ),
        data: (player) => Column(
          children: [
            _PlayerHeader(player: player),
            NavigationBar(
              height: 64,
              selectedIndex: _tab,
              onDestinationSelected: (value) => setState(() => _tab = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.info_outline),
                  label: '概览',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  label: '数据',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: '比赛',
                ),
              ],
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  _PlayerOverview(player: player),
                  const SingleChildScrollView(
                    child: CapabilityEmpty(
                      title: '暂无球员统计',
                      message: '当前后端尚未提供球员赛季统计接口。',
                    ),
                  ),
                  const SingleChildScrollView(
                    child: CapabilityEmpty(
                      title: '暂无球员比赛',
                      message: '当前后端尚未提供按球员查询比赛的接口。',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerHeader extends ConsumerWidget {
  const _PlayerHeader({required this.player});
  final PlayerDetail player;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandDark, AppColors.brand],
        ),
      ),
      child: Row(
        children: [
          AppPlayerAvatar(
            identity: 'player:${player.id}',
            name: player.name,
            imageUrl: resolveMediaUrl(config, player.avatarUrl),
            size: 76,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (player.nameEn != null)
                  Text(
                    player.nameEn!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${player.position ?? '位置暂无'} · ${player.retired ? '已退役' : '现役'} · ${player.followed ? '已关注' : '${player.followerCount} 人关注'}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerOverview extends ConsumerWidget {
  const _PlayerOverview({required this.player});
  final PlayerDetail player;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                DetailFact(label: '位置', value: player.position ?? '暂无'),
                DetailFact(label: '国籍', value: player.nationality ?? '暂无'),
                DetailFact(label: '年龄', value: player.age?.toString() ?? '暂无'),
                DetailFact(
                  label: '号码',
                  value: player.shirtNumber?.toString() ?? '暂无',
                ),
                DetailFact(label: '状态', value: player.retired ? '已退役' : '现役'),
              ],
            ),
          ),
        ),
        if (player.team != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('当前球队', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: ListTile(
              onTap: () => context.push('/teams/${player.team!.id}'),
              leading: AppTeamLogo(
                identity: 'team:${player.team!.id}',
                name: player.team!.name,
                imageUrl: resolveMediaUrl(config, player.team!.logoUrl),
                size: 44,
              ),
              title: Text(player.team!.name),
              subtitle: Text(
                [
                  player.team!.position,
                  if (player.team!.shirtNumber != null)
                    '${player.team!.shirtNumber} 号',
                ].whereType<String>().join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ],
    );
  }
}
