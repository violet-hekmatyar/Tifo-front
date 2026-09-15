import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../../auth/domain/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/user_center_models.dart';
import '../controllers/user_center_controllers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({required this.authController, super.key});
  final AuthController authController;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _logoutBusy = false;
  String? _message;

  Future<void> _openEditor() async {
    MySummary? summary = ref.read(mySummaryProvider).value;
    if (summary == null) {
      try {
        summary = await ref.read(mySummaryProvider.future);
      } on AppNetworkException catch (error) {
        if (mounted) {
          setState(() => _message = error.message);
        }
        return;
      } catch (_) {
        if (mounted) setState(() => _message = '资料加载失败，请稍后重试。');
        return;
      }
    }
    if (mounted) context.push('/users/me/edit', extra: summary);
  }

  Future<void> _logout() async {
    if (_logoutBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录？'),
        content: const Text('退出后需要重新登录才能继续使用。'),
        actions: [
          TextButton(
            key: const ValueKey('settings_logout_cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const ValueKey('settings_logout_confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _logoutBusy) return;
    setState(() {
      _logoutBusy = true;
      _message = null;
    });
    try {
      await widget.authController.logout();
      // GoRouter observes AuthController and redirects to /login.
    } on AppNetworkException catch (error) {
      if (mounted) {
        setState(() {
          _logoutBusy = false;
          _message = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _logoutBusy = false;
          _message = '退出失败，请稍后重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(title: const Text('设置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _SettingsGroup(
              children: [
                _SettingsEntry(
                  key: const ValueKey('settings_account'),
                  icon: Icons.account_circle_outlined,
                  title: '账号与安全',
                  subtitle: '查看账号信息',
                  onTap: () => context.push('/settings/account'),
                ),
                _SettingsEntry(
                  key: const ValueKey('settings_edit_profile'),
                  icon: Icons.edit_outlined,
                  title: '编辑资料',
                  subtitle: '修改昵称和简介',
                  onTap: _openEditor,
                ),
                _SettingsEntry(
                  key: const ValueKey('settings_notifications'),
                  icon: Icons.notifications_none_rounded,
                  title: '互动通知',
                  subtitle: '查看点赞、评论、回复和关注',
                  onTap: () => context.push('/settings/notifications'),
                ),
                _SettingsEntry(
                  key: const ValueKey('settings_logout'),
                  icon: Icons.logout_rounded,
                  title: _logoutBusy ? '退出中…' : '退出登录',
                  subtitle: _logoutBusy ? '正在清理本地会话' : null,
                  onTap: _logoutBusy ? null : _logout,
                  destructive: true,
                ),
              ],
            ),
            if (_message case final message?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  message,
                  key: const ValueKey('settings_feedback'),
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AccountInfoPage extends ConsumerWidget {
  const AccountInfoPage({required this.authController, super.key});
  final AuthController authController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = authController.state.user;
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(title: const Text('账号与安全')),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('账号信息暂不可用'))
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _AccountCard(user: user),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    '账号安全相关的敏感信息和操作暂不在当前版本开放。',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon, color: destructive ? AppColors.error : AppColors.brand),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: onTap == null
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.chevron_right_rounded),
  );
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.user});
  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = user.nickname?.trim();
    final initial = nickname == null || nickname.isEmpty
        ? user.username.characters.firstOrNull
        : nickname.characters.first;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                AppEntityAvatar(
                  identity: 'user:${user.id}',
                  semanticLabel: '${nickname ?? user.username}头像',
                  fallbackIcon: Icons.person_outline_rounded,
                  fallbackText: initial,
                  imageUrl: resolveMediaUrl(
                    ref.watch(appConfigProvider),
                    user.avatarUrl,
                  ),
                  size: 56,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    nickname == null || nickname.isEmpty ? '未设置昵称' : nickname,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          if (nickname != null && nickname.isNotEmpty)
            _AccountRow(label: '昵称', value: nickname),
          _AccountRow(label: '用户名', value: user.username),
          _AccountRow(label: '角色', value: user.roleType),
          _AccountRow(label: '账号状态', value: user.status),
          _AccountRow(label: '用户 ID', value: '${user.id}'),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: const TextStyle(color: AppColors.inkMuted)),
        ),
        Expanded(
          child: Text(value, maxLines: 3, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}
