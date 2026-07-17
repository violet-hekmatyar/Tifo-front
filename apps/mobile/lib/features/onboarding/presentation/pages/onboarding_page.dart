import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../domain/onboarding_models.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  @override
  void initState() {
    super.initState();
    unawaited(ref.read(onboardingControllerProvider).load());
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(onboardingControllerProvider);
    final state = controller.state;
    return Scaffold(
      appBar: AppBar(title: const Text('设置我的看台')),
      body: switch (state.status) {
        OnboardingLoadStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        OnboardingLoadStatus.empty || OnboardingLoadStatus.failure => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_outlined, size: 56),
                const SizedBox(height: 12),
                Text(state.message ?? '选项加载失败。'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.load,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
        OnboardingLoadStatus.ready => _OnboardingContent(
          controller: controller,
        ),
      },
    );
  }
}

class _OnboardingContent extends ConsumerWidget {
  const _OnboardingContent({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = controller.state;
    final options = state.options!;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text(
            '1. 选择我的主队',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text('主队为必选项，也会自动加入关注球队。'),
          const SizedBox(height: 12),
          ...options.teams.map(
            (team) => _TeamTile(
              team: team,
              selected: state.mainTeamId == team.id,
              onTap: () => controller.selectMainTeam(team.id),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '2. 关注球队',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text('可多选，当前不限制数量。'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.teams
                .map(
                  (team) => FilterChip(
                    label: Text(team.name),
                    selected: state.followTeamIds.contains(team.id),
                    onSelected: state.mainTeamId == team.id
                        ? null
                        : (_) => controller.toggleTeam(team.id),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            '3. 关注球员',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text('可多选，也可以暂不选择。'),
          const SizedBox(height: 10),
          ...options.players.map(
            (player) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: state.followPlayerIds.contains(player.id),
              onChanged: (_) => controller.togglePlayer(player.id),
              title: Text(player.name),
              subtitle: Text(
                [player.teamName, player.position]
                    .whereType<String>()
                    .where((value) => value.isNotEmpty)
                    .join(' · '),
              ),
              secondary: _RemoteAvatar(
                url: player.avatarUrl,
                fallback: Icons.person_outline,
              ),
            ),
          ),
          if (state.message != null) ...[
            const SizedBox(height: 12),
            Text(
              state.message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: state.isSubmitting ? null : controller.submit,
            child: state.isSubmitting
                ? const CircularProgressIndicator()
                : const Text('完成首次设置'),
          ),
        ],
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.team,
    required this.selected,
    required this.onTap,
  });
  final TeamOption team;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
    child: ListTile(
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      title: Text(team.name),
      subtitle: Text(
        [
          team.leagueName,
          team.country,
        ].whereType<String>().where((value) => value.isNotEmpty).join(' · '),
      ),
      trailing: _RemoteAvatar(
        url: team.logoUrl,
        fallback: Icons.shield_outlined,
      ),
    ),
  );
}

class _RemoteAvatar extends ConsumerWidget {
  const _RemoteAvatar({required this.url, required this.fallback});
  final String? url;
  final IconData fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = resolveMediaUrl(ref.watch(appConfigProvider), url);
    if (resolved == null) return CircleAvatar(child: Icon(fallback));
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundImage: NetworkImage(resolved),
      onForegroundImageError: (_, _) {},
      child: Icon(fallback),
    );
  }
}
