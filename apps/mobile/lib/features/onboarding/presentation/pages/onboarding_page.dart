import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_player_avatar.dart';
import '../../../../shared/widgets/app_selection_card.dart';
import '../../../../shared/widgets/app_team_logo.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;
  String _mainTeamQuery = '';
  String _followTeamQuery = '';
  String _playerQuery = '';
  final _mainTeamSearchController = TextEditingController();
  final _followTeamSearchController = TextEditingController();
  final _playerSearchController = TextEditingController();
  final _mainTeamScrollController = ScrollController();
  final _followTeamScrollController = ScrollController();
  final _playerScrollController = ScrollController();

  @override
  void dispose() {
    _mainTeamSearchController.dispose();
    _followTeamSearchController.dispose();
    _playerSearchController.dispose();
    _mainTeamScrollController.dispose();
    _followTeamScrollController.dispose();
    _playerScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(ref.read(onboardingControllerProvider).load());
    });
  }

  void _previous() {
    if (_step > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _step--);
    }
  }

  void _next(OnboardingController controller) {
    if (_step == 0 && !controller.requireMainTeam()) return;
    if (_step < 2) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(onboardingControllerProvider);
    final state = controller.state;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.white,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScope(
        canPop: _step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _previous();
        },
        child: Scaffold(
          backgroundColor: AppColors.brandDark,
          body: switch (state.status) {
            OnboardingLoadStatus.loading => _buildStateShell(
              key: const ValueKey('onboarding_loading'),
              icon: const CircularProgressIndicator(color: Colors.white),
              title: '正在准备选择',
              message: '正在加载球队与球员信息…',
            ),
            OnboardingLoadStatus.empty => _buildStateShell(
              key: const ValueKey('onboarding_empty'),
              icon: const Icon(
                Icons.inbox_outlined,
                size: 54,
                color: Colors.white,
              ),
              title: '暂时没有可选内容',
              message: state.message ?? '请稍后重试。',
              onRetry: controller.retry,
            ),
            OnboardingLoadStatus.failure => _buildStateShell(
              key: const ValueKey('onboarding_error'),
              icon: const Icon(
                Icons.cloud_off_rounded,
                size: 54,
                color: Colors.white,
              ),
              title: '加载失败',
              message: state.message ?? '选项加载失败。',
              onRetry: controller.retry,
            ),
            OnboardingLoadStatus.ready => _buildReady(context, controller),
          },
        ),
      ),
    );
  }

  Widget _buildStateShell({
    required Key key,
    required Widget icon,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) => Container(
    key: key,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.brandDark, AppColors.brand],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: AppSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    key: const ValueKey('onboarding_retry'),
                    onPressed: onRetry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('重试'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildReady(BuildContext context, OnboardingController controller) {
    final bottomSystemInset = MediaQuery.viewPaddingOf(context).bottom;
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.brandDark)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomSystemInset > 0 ? bottomSystemInset : 24,
          child: const ColoredBox(color: Colors.white),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  key: const ValueKey('onboarding_results_panel'),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _panelTitle,
                            key: const ValueKey('onboarding_results_title'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: _step,
                          children: [
                            _buildTeamStep(context, controller, mainTeam: true),
                            _buildTeamStep(
                              context,
                              controller,
                              mainTeam: false,
                            ),
                            _buildPlayerStep(context, controller),
                          ],
                        ),
                      ),
                      _buildActions(controller),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _panelTitle => switch (_step) {
    _ => '搜索结果',
  };

  Widget _buildHeader(BuildContext context) {
    final copy = switch (_step) {
      0 => (
        '我的主队',
        '选择您支持的主队，系统会智能优先给您推荐主队的各类消息。头像和主页会优先展示主队信息，每位用户只能选择一个主队哦。',
      ),
      1 => (
        '关注的球队',
        '选择您关注的球队，系统会智能优先给您推荐球队的各类消息，同时会在 APP 主页中显示您关注的球队板块。之后也可以随时添加或取消关注。',
      ),
      _ => ('关注的球员', '点击爱心选择您喜欢的球员，系统会智能优先给您推荐球员的各类消息。之后也可以随时添加或取消喜欢的球员。'),
    };
    final searchController = switch (_step) {
      0 => _mainTeamSearchController,
      1 => _followTeamSearchController,
      _ => _playerSearchController,
    };
    final searchKey = switch (_step) {
      0 => const ValueKey('onboarding_main_team_search'),
      1 => const ValueKey('onboarding_team_search'),
      _ => const ValueKey('onboarding_player_search'),
    };
    return CustomPaint(
      key: const ValueKey('onboarding_green_header'),
      foregroundPainter: _OnboardingPatternPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.brandDark, AppColors.brand],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              copy.$1,
              key: const ValueKey('onboarding_step_title'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              copy.$2,
              key: const ValueKey('onboarding_step_description'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: .82),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 48,
              child: TextField(
                key: searchKey,
                controller: searchController,
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: _step == 2 ? '搜索球员' : '搜索球队',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                  ),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          key: const ValueKey('onboarding_search_clear'),
                          tooltip: '清空搜索',
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              if (_step == 0) _mainTeamQuery = '';
                              if (_step == 1) _followTeamQuery = '';
                              if (_step == 2) _playerQuery = '';
                            });
                          },
                          color: Colors.white,
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .16),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: Colors.white, width: 1),
                  ),
                ),
                onChanged: (value) => setState(() {
                  if (_step == 0) _mainTeamQuery = value;
                  if (_step == 1) _followTeamQuery = value;
                  if (_step == 2) _playerQuery = value;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(OnboardingController controller) {
    final state = controller.state;
    return SafeArea(
      top: false,
      child: Container(
        key: const ValueKey('onboarding_bottom_actions'),
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: _OnboardingSecondaryAction(
                  key: const ValueKey('onboarding_previous'),
                  label: '上一步',
                  onPressed: state.isSubmitting ? null : _previous,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              flex: _step == 0 ? 1 : 2,
              child: _OnboardingPrimaryAction(
                key: ValueKey(
                  _step == 2 ? 'onboarding_submit' : 'onboarding_next',
                ),
                label: '下一步',
                loading: state.isSubmitting,
                onPressed: _step == 2
                    ? controller.submit
                    : () => _next(controller),
              ),
            ),
          ],
        ),
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
      final query = (mainTeam ? _mainTeamQuery : _followTeamQuery)
          .trim()
          .toLowerCase();
      return query.isEmpty ||
          team.name.toLowerCase().contains(query) ||
          (team.leagueName?.toLowerCase().contains(query) ?? false) ||
          (team.country?.toLowerCase().contains(query) ?? false);
    }).toList();
    return ListView(
      key: PageStorageKey(mainTeam ? 'onboarding_step_1' : 'onboarding_step_2'),
      controller: mainTeam
          ? _mainTeamScrollController
          : _followTeamScrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      children: [
        if (teams.isEmpty)
          const Padding(
            key: ValueKey('onboarding_local_empty'),
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Text('没有匹配的球队', textAlign: TextAlign.center),
          )
        else
          for (var index = 0; index < teams.length; index++) ...[
            () {
              final team = teams[index];
              final selected = mainTeam
                  ? state.mainTeamId == team.id
                  : state.followTeamIds.contains(team.id);
              return AppSelectionCard(
                key: ValueKey(
                  '${mainTeam ? 'main' : 'follow'}_team_${team.id}',
                ),
                bodyKey: ValueKey(
                  '${mainTeam ? 'main' : 'follow'}_team_${team.id}_body',
                ),
                title: team.name,
                subtitle: [team.leagueName, team.country]
                    .whereType<String>()
                    .where((value) => value.trim().isNotEmpty)
                    .join(' · '),
                selected: selected,
                selectedIcon: Icons.favorite_rounded,
                unselectedIcon: Icons.favorite_border_rounded,
                selectedFillColor: Colors.white,
                selectedBorderColor: AppColors.border,
                selectedIconColor: AppColors.error,
                unselectedIconColor: AppColors.border,
                onTap: mainTeam
                    ? () => controller.selectMainTeam(team.id)
                    : state.mainTeamId == team.id
                    ? () {}
                    : () => controller.toggleTeam(team.id),
                leading: AppTeamLogo(
                  identity: 'team:${team.id}',
                  name: team.name,
                  imageUrl: resolveMediaUrl(config, team.logoUrl),
                  size: 34,
                ),
                marginBottom: 0,
                borderRadius: 12,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 0,
                ),
                dense: true,
                visualDensity: const VisualDensity(
                  horizontal: -1,
                  vertical: -2,
                ),
                minVerticalPadding: 0,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                subtitleStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                ),
              );
            }(),
            if (index < teams.length - 1) const SizedBox(height: 39),
          ],
        if (state.message != null && (mainTeam || _step == 0)) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.message!,
            key: const ValueKey('onboarding_selection_message'),
            style: const TextStyle(color: AppColors.error),
          ),
        ],
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
          (player.teamName?.toLowerCase().contains(query) ?? false) ||
          (player.position?.toLowerCase().contains(query) ?? false);
    }).toList();
    return ListView(
      key: const PageStorageKey('onboarding_step_3'),
      controller: _playerScrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      children: [
        if (players.isEmpty)
          const Padding(
            key: ValueKey('onboarding_local_empty'),
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Text('没有匹配的球员', textAlign: TextAlign.center),
          )
        else
          for (var index = 0; index < players.length; index++) ...[
            () {
              final player = players[index];
              return AppSelectionCard(
                key: ValueKey('player_${player.id}'),
                bodyKey: ValueKey('player_${player.id}_body'),
                title: player.name,
                subtitle: [player.teamName, player.position]
                    .whereType<String>()
                    .where((value) => value.trim().isNotEmpty)
                    .join(' · '),
                selected: state.followPlayerIds.contains(player.id),
                selectedIcon: Icons.favorite_rounded,
                unselectedIcon: Icons.favorite_border_rounded,
                selectedFillColor: Colors.white,
                selectedBorderColor: AppColors.border,
                selectedIconColor: AppColors.error,
                unselectedIconColor: AppColors.border,
                onTap: () => controller.togglePlayer(player.id),
                leading: AppPlayerAvatar(
                  identity: 'player:${player.id}',
                  name: player.name,
                  imageUrl: resolveMediaUrl(config, player.avatarUrl),
                  size: 34,
                ),
                marginBottom: 0,
                borderRadius: 12,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 0,
                ),
                dense: true,
                visualDensity: const VisualDensity(
                  horizontal: -1,
                  vertical: -2,
                ),
                minVerticalPadding: 0,
                titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                subtitleStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                ),
              );
            }(),
            if (index < players.length - 1) const SizedBox(height: 39),
          ],
        if (state.message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            state.message!,
            key: const ValueKey('onboarding_submit_message'),
            style: const TextStyle(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _OnboardingPrimaryAction extends StatelessWidget {
  const _OnboardingPrimaryAction({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
    ),
  );
}

class _OnboardingSecondaryAction extends StatelessWidget {
  const _OnboardingSecondaryAction({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1)),
    ),
  );
}

class _OnboardingPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .035);
    const cell = 48.0;
    for (var y = 0.0; y < size.height; y += cell) {
      for (var x = 0.0; x < size.width; x += cell) {
        final row = (y / cell).floor();
        final column = (x / cell).floor();
        if ((row + column) % 3 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
