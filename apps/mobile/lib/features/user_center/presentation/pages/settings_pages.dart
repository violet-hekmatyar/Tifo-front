import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/account_security_repository.dart';

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
                                onTap: () =>
                                    context.push('/settings/account/phone'),
                              ),
                              _SecurityEntry(
                                key: const ValueKey('account_password'),
                                label: '修改密码',
                                onTap: () => context.push(
                                  '/settings/account/password',
                                ),
                              ),
                              _SecurityEntry(
                                key: const ValueKey('account_delete'),
                                label: '注销账号',
                                onTap: () => context.push(
                                  '/settings/account/deactivate',
                                ),
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

class _AccountSubPage extends StatelessWidget {
  const _AccountSubPage({
    required this.title,
    required this.body,
    this.headerKey,
    this.backKey = 'account_sub_back',
  });
  final String title;
  final Widget body;
  final Key? headerKey;
  final String backKey;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: _settingsSystemUiStyle,
    child: Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(title: title, backKey: backKey, key: headerKey),
            Expanded(child: body),
          ],
        ),
      ),
    ),
  );
}

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _current.text;
    final next = _next.text;
    if (current.isEmpty || next.isEmpty) {
      setState(() => _message = '请填写当前密码和新密码。');
      return;
    }
    if (next.length < 6 || next.length > 64) {
      setState(() => _message = '新密码需为 6–64 位。');
      return;
    }
    if (next != _confirm.text) {
      setState(() => _message = '两次输入的新密码不一致。');
      return;
    }
    if (next == current) {
      setState(() => _message = '新密码不能与当前密码相同。');
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref
          .read(accountSecurityRepositoryProvider)
          .changePassword(oldPassword: current, newPassword: next);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('密码已修改')));
      context.pop();
    } on AppNetworkException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = '修改失败，请稍后重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => _AccountSubPage(
    title: '修改密码',
    headerKey: const ValueKey('change_password_header'),
    backKey: 'change_password_back',
    body: ListView(
      padding: const EdgeInsets.fromLTRB(10, 26, 10, 32),
      children: [
        TextField(
          key: const ValueKey('change_password_current'),
          controller: _current,
          obscureText: true,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: '当前密码'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('change_password_new'),
          controller: _next,
          obscureText: true,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: '新密码',
            helperText: '6–64 位',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('change_password_confirm'),
          controller: _confirm,
          obscureText: true,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: '确认新密码'),
        ),
        if (_message case final message?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              message,
              key: const ValueKey('change_password_message'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const ValueKey('change_password_submit'),
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? '提交中' : '确认修改'),
        ),
      ],
    ),
  );
}

class ChangePhonePage extends ConsumerStatefulWidget {
  const ChangePhonePage({required this.authController, super.key});
  final AuthController authController;

  @override
  ConsumerState<ChangePhonePage> createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends ConsumerState<ChangePhonePage> {
  final TextEditingController _phone = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      setState(() => _message = '请输入新的手机号。');
      return;
    }
    if (phone.length > 32) {
      setState(() => _message = '手机号长度不能超过 32 位。');
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(accountSecurityRepositoryProvider).changePhone(phone);
      await widget.authController.refreshAfterOnboarding();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('手机号已更新')));
      // refreshAfterOnboarding 会触发 refreshListenable 的整轮路由重算，
      // 同一帧内 pop 会被吞掉，需等下一帧再返回。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    } on AppNetworkException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = '更新失败，请稍后重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current =
        widget.authController.state.user?.phoneMasked ?? '未绑定';
    return _AccountSubPage(
      title: '手机号',
      headerKey: const ValueKey('change_phone_header'),
      backKey: 'change_phone_back',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 26, 10, 32),
        children: [
          Container(
            key: const ValueKey('change_phone_current'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Text(
                  '当前手机号',
                  style: TextStyle(color: AppColors.ink, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  current,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const ValueKey('change_phone_input'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: '新手机号',
              helperText: '当前版本通过人工校验，不支持短信验证码',
            ),
          ),
          if (_message case final message?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                message,
                key: const ValueKey('change_phone_message'),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: const ValueKey('change_phone_submit'),
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? '提交中' : '确认更换'),
          ),
        ],
      ),
    );
  }
}

class DeactivateAccountPage extends ConsumerStatefulWidget {
  const DeactivateAccountPage({required this.authController, super.key});
  final AuthController authController;

  @override
  ConsumerState<DeactivateAccountPage> createState() =>
      _DeactivateAccountPageState();
}

class _DeactivateAccountPageState extends ConsumerState<DeactivateAccountPage> {
  bool _acknowledged = false;
  bool _busy = false;
  String? _message;

  Future<void> _submit() async {
    if (!_acknowledged || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认注销账号？'),
        content: const Text('注销后账号无法登录，且此操作不可撤销。'),
        actions: [
          TextButton(
            key: const ValueKey('deactivate_cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('再想想'),
          ),
          FilledButton(
            key: const ValueKey('deactivate_confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认注销'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(accountSecurityRepositoryProvider).deactivateAccount();
      await widget.authController.logout();
    } on AppNetworkException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = '注销失败，请稍后重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => _AccountSubPage(
    title: '注销账号',
    headerKey: const ValueKey('deactivate_header'),
    backKey: 'deactivate_back',
    body: ListView(
      padding: const EdgeInsets.fromLTRB(10, 26, 10, 32),
      children: [
        const Text(
          '注销后会发生什么',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          '· 昵称将变为「账号已注销」，头像和简介会被清空\n'
          '· 你发布的内容、评论和点赞记录会保留，但不再显示你的资料\n'
          '· 账号无法再次登录，手机号与用户名将被释放',
          style: TextStyle(color: AppColors.inkMuted, height: 1.7),
        ),
        const SizedBox(height: AppSpacing.lg),
        CheckboxListTile(
          key: const ValueKey('deactivate_acknowledge'),
          value: _acknowledged,
          onChanged: _busy
              ? null
              : (value) => setState(() => _acknowledged = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('我已了解以上影响，确认注销账号'),
        ),
        if (_message case final message?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              message,
              key: const ValueKey('deactivate_message'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const ValueKey('deactivate_submit'),
          onPressed: _acknowledged && !_busy ? _submit : null,
          child: Text(_busy ? '注销中' : '注销账号'),
        ),
      ],
    ),
  );
}
