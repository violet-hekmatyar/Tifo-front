import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/auth_brand_header.dart';
import '../controllers/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(authControllerProvider)
        .register(
          username: _username.text,
          phone: _phone.text,
          password: _password.text,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('注册成功，请登录。')));
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider).state;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthBrandHeader(
              title: '加入南看台',
              subtitle: '创建账号，建立属于你的足球关注清单',
            ),
            Transform.translate(
              offset: const Offset(0, -AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '创建账号',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AppTextField(
                              controller: _username,
                              label: '用户名',
                              helperText: '3-64 位字母、数字或下划线',
                              prefixIcon: Icons.person_add_alt_rounded,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                return RegExp(
                                      r'^[A-Za-z0-9_]{3,64}$',
                                    ).hasMatch(text)
                                    ? null
                                    : '请输入 3-64 位字母、数字或下划线';
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _phone,
                              label: '手机号',
                              prefixIcon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return '请输入手机号';
                                return text.length > 32
                                    ? '手机号长度不能超过 32 位'
                                    : null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _password,
                              label: '密码',
                              helperText: '6-64 位',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.next,
                              suffixIcon: IconButton(
                                tooltip: _obscure ? '显示密码' : '隐藏密码',
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                              validator: (value) {
                                final length = value?.length ?? 0;
                                return length < 6 || length > 64
                                    ? '密码长度必须为 6-64 位'
                                    : null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _confirmation,
                              label: '确认密码',
                              prefixIcon: Icons.verified_user_outlined,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) =>
                                  value != _password.text ? '两次输入的密码不一致' : null,
                            ),
                            if (state.message != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                state.message!,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            AppPrimaryButton(
                              label: '注册',
                              icon: Icons.person_add_rounded,
                              loading: state.isSubmitting,
                              onPressed: _submit,
                            ),
                            TextButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => context.go('/login'),
                              child: const Text('已有账号？返回登录'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
