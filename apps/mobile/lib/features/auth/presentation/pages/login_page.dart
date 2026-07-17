import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/auth_brand_header.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final username = ref.read(authControllerProvider).state.registeredUsername;
    if (_usernameController.text.isEmpty && username != null) {
      _usernameController.text = username;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authControllerProvider)
        .login(
          username: _usernameController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider).state;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthBrandHeader(title: '欢迎回来', subtitle: '登录后继续关注你热爱的球队与球员'),
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
                              '账号登录',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AppTextField(
                              controller: _usernameController,
                              label: '用户名',
                              prefixIcon: Icons.person_outline_rounded,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? '请输入用户名'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _passwordController,
                              label: '密码',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              autofillHints: const [AutofillHints.password],
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? '请输入密码'
                                  : null,
                            ),
                            if (state.message != null) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: Text(
                                  state.message!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            AppPrimaryButton(
                              label: '登录',
                              icon: Icons.login_rounded,
                              loading: state.isSubmitting,
                              onPressed: _submit,
                            ),
                            TextButton(
                              onPressed: state.isSubmitting
                                  ? null
                                  : () => context.go('/register'),
                              child: const Text('没有账号？立即注册'),
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
