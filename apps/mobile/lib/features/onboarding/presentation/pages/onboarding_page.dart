import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_secondary_button.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_selection_card.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;
  String _teamQuery = '';
  String _playerQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(onboardingControllerProvider).load());
      }
    });
  }

  void _previous() {
    if (_step > 0) setState(() => _step--);
  }

  void _next() {
    if (_step < 2) setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(onboardingControllerProvider);
    final state = controller.state;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _previous();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('设置我的看台'),
          leading: _step == 0
              ? null
              : IconButton(
                  tooltip: '上一步',
                  onPressed: _previous,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
        ),
        body: switch (state.status) {
          OnboardingLoadStatus.loading => const AppStateView(
            key: ValueKey('onboarding_loading'),
            kind: AppStateKind.loading,
            title: '正在准备选择',
            message: '正在加载球队与球员信息…',
          ),
          OnboardingLoadStatus.empty => AppStateView(
            key: const ValueKey('onboarding_empty'),
            kind: AppStateKind.empty,
            title: '暂时没有可选内容',
            message: state.message ?? '请稍后重试。',
            onRetry: controller.load,
          ),
          OnboardingLoadStatus.failure => AppStateView(
            key: const ValueKey('onboarding_error'),
            kind: AppStateKind.error,
            title: '加载失败',
            message: state.message ?? '选项加载失败。',
            onRetry: controller.load,
          ),
          OnboardingLoadStatus.ready => _buildReady(context, controller),
        },
      ),
    );
  }

  Widget _buildReady(BuildContext context, OnboardingController controller) {
    final state = controller.state;
    return SafeArea(
      child: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                Row(
                  children: List.generate(3, (index) {
                    final active = index <= _step;
                    return Expanded(
                      child: Container(
                        height: 5,
                        margin: EdgeInsets.only(
                          right: index == 2 ? 0 : AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: active ? AppColors.brand : AppColors.border,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '步骤 ${_step + 1} / 3',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: AppColors.brand),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _buildTeamStep(context, controller, mainTeam: true),
                _buildTeamStep(context, controller, mainTeam: false),
                _buildPlayerStep(context, controller),
              ],
            ),
          ),
          Container(
            key: const ValueKey('onboarding_bottom_actions'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                if (_step > 0) ...[
                  Expanded(
                    child: AppSecondaryButton(
                      key: const ValueKey('onboarding_previous'),
                      label: '上一步',
                      onPressed: state.isSubmitting ? null : _previous,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  flex: _step == 0 ? 1 : 2,
                  child: AppPrimaryButton(
                    key: ValueKey(
                      _step == 2 ? 'onboarding_submit' : 'onboarding_next',
                    ),
                    label: _step == 2 ? '完成首次设置' : '下一步',
                    icon: _step == 2
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    loading: state.isSubmitting,
                    onPressed: _step == 0 && state.mainTeamId == null
                        ? null
                        : _step == 2
                        ? controller.submit
                        : _next,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStep(
    BuildContext context,
    OnboardingController controller, {
    required bool mainTeam,
  }) {
    final state = controller.state;
    final config = ref.watch(appConfigProvider);
    final teams = state.options!.teams.where((team) {
      final query = _teamQuery.trim().toLowerCase();
      return query.isEmpty ||
          team.name.toLowerCase().contains(query) ||
          (team.country?.toLowerCase().contains(query) ?? false);
    }).toList();
    return ListView(
      key: PageStorageKey(mainTeam ? 'onboarding_step_1' : 'onboarding_step_2'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppSectionHeader(
          title: mainTeam ? '选择我的主队' : '关注球队',
          description: mainTeam
              ? '主队为必选项，也会自动加入关注球队。'
              : '可以关注多支球队，当前已选择 ${state.followTeamIds.length} 支。',
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          decoration: const InputDecoration(
            hintText: '搜索球队',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (value) => setState(() => _teamQuery = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (teams.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Text('没有匹配的球队', textAlign: TextAlign.center),
          )
        else
          ...teams.map((team) {
            final selected = mainTeam
                ? state.mainTeamId == team.id
                : state.followTeamIds.contains(team.id);
            return AppSelectionCard(
              key: ValueKey('${mainTeam ? 'main' : 'follow'}_team_${team.id}'),
              title: team.name,
              subtitle: [team.leagueName, team.country]
                  .whereType<String>()
                  .where((value) => value.isNotEmpty)
                  .join(' · '),
              selected: selected,
              onTap: mainTeam
                  ? () => controller.selectMainTeam(team.id)
                  : state.mainTeamId == team.id
                  ? () {}
                  : () => controller.toggleTeam(team.id),
              leading: AppTeamLogo(
                identity: 'team:${team.id}',
                name: team.name,
                imageUrl: resolveMediaUrl(config, team.logoUrl),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPlayerStep(
    BuildContext context,
    OnboardingController controller,
  ) {
    final state = controller.state;
    final config = ref.watch(appConfigProvider);
    final players = state.options!.players.where((player) {
      final query = _playerQuery.trim().toLowerCase();
      return query.isEmpty ||
          player.name.toLowerCase().contains(query) ||
          (player.teamName?.toLowerCase().contains(query) ?? false);
    }).toList();
    return ListView(
      key: const PageStorageKey('onboarding_step_3'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        AppSectionHeader(
          title: '关注球员',
          description: '按兴趣选择球员，也可以暂不选择。',
          trailing: Chip(label: Text('已选 ${state.followPlayerIds.length}')),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          decoration: const InputDecoration(
            hintText: '搜索球员',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (value) => setState(() => _playerQuery = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (players.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Text('没有匹配的球员', textAlign: TextAlign.center),
          )
        else
          ...players.map(
            (player) => AppSelectionCard(
              key: ValueKey('player_${player.id}'),
              title: player.name,
              subtitle: [player.teamName, player.position]
                  .whereType<String>()
                  .where((value) => value.isNotEmpty)
                  .join(' · '),
              selected: state.followPlayerIds.contains(player.id),
              onTap: () => controller.togglePlayer(player.id),
              leading: AppPlayerAvatar(
                identity: 'player:${player.id}',
                name: player.name,
                imageUrl: resolveMediaUrl(config, player.avatarUrl),
              ),
            ),
          ),
        if (state.message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(state.message!, style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
  }
}
