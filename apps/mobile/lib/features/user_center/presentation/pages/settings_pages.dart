import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

const _settingsSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: AppColors.page,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: AppColors.page,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarDividerColor: AppColors.page,
  systemNavigationBarContrastEnforced: false,
);

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({required this.authController, super.key});
  final AuthController authController;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _logoutBusy = false;
  String? _message;

  void _showUnavailable(String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title暂未开放'),
          duration: const Duration(milliseconds: 1600),
        ),
      );
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      key: const ValueKey('settings_system_ui'),
      value: _settingsSystemUiStyle,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Column(
            children: [
              const _SettingsHeader(
                title: '设置',
                key: ValueKey('settings_header'),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 26, 10, 32),
                  children: [
                    _SettingsGroup(
                      key: const ValueKey('settings_group'),
                      dividerPrefix: 'settings_divider',
                      children: [
                        _SettingsEntry(
                          key: const ValueKey('settings_account'),
                          icon: Icons.shield_outlined,
                          title: '账号与安全',
                          onTap: () => context.push('/settings/account'),
                        ),
                        _SettingsEntry(
                          key: const ValueKey('settings_general'),
                          icon: Icons.settings_outlined,
                          title: '通用设置',
                          onTap: () => _showUnavailable('通用设置'),
                        ),
                        _SettingsEntry(
                          key: const ValueKey('settings_notifications'),
                          icon: Icons.notifications_none_rounded,
                          title: '通知设置',
                          onTap: () => _showUnavailable('通知设置'),
                        ),
                        _SettingsEntry(
                          key: const ValueKey('settings_language'),
                          icon: Icons.translate_rounded,
                          title: '语言设置',
                          onTap: () => _showUnavailable('语言设置'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _LogoutCard(
                        cardKey: const ValueKey('settings_logout'),
                        busy: _logoutBusy,
                        onTap: _logoutBusy ? null : _logout,
                      ),
                    ),
                    if (_message case final message?)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          message,
                          key: const ValueKey('settings_feedback'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountInfoPage extends StatelessWidget {
  const AccountInfoPage({required this.authController, super.key});
  final AuthController authController;

  void _showUnavailable(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title暂未开放'),
          duration: const Duration(milliseconds: 1600),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = authController.state.user;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      key: const ValueKey('account_system_ui'),
      value: _settingsSystemUiStyle,
      child: Scaffold(
        backgroundColor: AppColors.page,
        body: SafeArea(
          child: Column(
            children: [
              const _SettingsHeader(
                title: '设置',
                backKey: 'account_back',
                key: ValueKey('account_header'),
              ),
              Expanded(
                child: user == null
                    ? const Center(child: Text('账号信息暂不可用'))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(10, 26, 10, 32),
                        children: [
                          _SettingsGroup(
                            key: const ValueKey('account_security_group'),
                            dividerPrefix: 'account_divider',
                            children: [
                              _SecurityEntry(
                                key: const ValueKey('account_phone'),
                                label: '手机号',
                                value: user.phoneMasked ?? '未绑定',
                                onTap: () => _showUnavailable(context, '手机号换绑'),
                              ),
                              _SecurityEntry(
                                key: const ValueKey('account_password'),
                                label: '修改密码',
                                onTap: () => _showUnavailable(context, '修改密码'),
                              ),
                              _SecurityEntry(
                                key: const ValueKey('account_delete'),
                                label: '注销账号',
                                onTap: () => _showUnavailable(context, '注销账号'),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.title,
    this.backKey = 'settings_back',
    super.key,
  });
  final String title;
  final String backKey;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            key: ValueKey(backKey),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            color: AppColors.ink,
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 19.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.children,
    required this.dividerPrefix,
    super.key,
  });
  final List<Widget> children;
  final String dividerPrefix;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.md),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: double.infinity,
      height: children.length * 50,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(children: children),
          for (var index = 1; index < children.length; index++)
            Positioned(
              top: index * 50 - 0.5,
              left: 15,
              right: 0,
              child: SizedBox(
                key: ValueKey('${dividerPrefix}_$index'),
                height: 1,
                child: ColoredBox(color: AppColors.border),
              ),
            ),
        ],
      ),
    ),
  );
}

class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _FixedEntry(
    onTap: onTap,
    leading: Icon(icon, color: AppColors.ink, size: 21),
    label: title,
  );
}

class _SecurityEntry extends StatelessWidget {
  const _SecurityEntry({
    required this.label,
    required this.onTap,
    this.value,
    super.key,
  });
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPhone = key == const ValueKey('account_phone');
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.ink, fontSize: 15),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (value != null)
                      SizedBox(
                        width: 132,
                        child: Text(
                          value!,
                          key: isPhone
                              ? const ValueKey('account_phone_value')
                              : null,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      key: isPhone
                          ? const ValueKey('account_phone_arrow')
                          : null,
                      color: AppColors.inkMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FixedEntry extends StatelessWidget {
  const _FixedEntry({
    required this.onTap,
    required this.label,
    required this.leading,
  });
  final VoidCallback onTap;
  final String label;
  final Widget leading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          const SizedBox(width: 16),
          SizedBox(width: 28, child: Center(child: leading)),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({
    required this.busy,
    required this.onTap,
    required this.cardKey,
  });
  final bool busy;
  final VoidCallback? onTap;
  final Key cardKey;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: cardKey,
    width: double.infinity,
    height: 54,
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Center(
          child: busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  '退出登录',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ),
      ),
    ),
  );
}
