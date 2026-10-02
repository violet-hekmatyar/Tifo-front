import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_agreement.dart';

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
  bool _agreed = false;
  Future<bool>? _agreementRequest;

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
    if (!_agreed) {
      final request = _agreementRequest ??= presentAuthAgreement(context);
      final accepted = await request;
      _agreementRequest = null;
      if (!accepted || !mounted) return;
      setState(() => _agreed = true);
    }
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.page,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.brand,
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final panelTop = constraints.maxHeight * .51;
            final statusBar = MediaQuery.paddingOf(context).top;
            return Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(
                  child: _LoginBrandBackground(
                    key: ValueKey('login_green_header'),
                  ),
                ),
                SizedBox(
                  height: panelTop,
                  child: Padding(
                    padding: EdgeInsets.only(top: statusBar),
                    child: _LoginBrandContent(
                      height: (panelTop - statusBar).clamp(0, double.infinity),
                    ),
                  ),
                ),
                Positioned(
                  top: panelTop,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    key: const ValueKey('login_white_panel'),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, panelConstraints) {
                        final bottomInset = MediaQuery.viewInsetsOf(
                          context,
                        ).bottom;
                        final contentPadding = EdgeInsets.fromLTRB(
                          24,
                          26,
                          24,
                          24 + bottomInset,
                        );
                        final minContentHeight =
                            (panelConstraints.maxHeight -
                                    contentPadding.vertical)
                                .clamp(0.0, double.infinity);
                        return SingleChildScrollView(
                          key: const PageStorageKey('login_form_scroll'),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: contentPadding,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: minContentHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AppTextField(
                                      key: const ValueKey('login_username'),
                                      controller: _usernameController,
                                      label: '用户名',
                                      prefixIcon: Icons.person_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                      ],
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                          ? '请输入用户名'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    AppTextField(
                                      key: const ValueKey('login_password'),
                                      controller: _passwordController,
                                      label: '密码',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? '显示密码'
                                            : '隐藏密码',
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
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
                                      const SizedBox(height: 10),
                                      Container(
                                        key: const ValueKey('login_error'),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(
                                            alpha: .08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
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
                                    const SizedBox(height: 10),
                                    _LoginButton(
                                      key: const ValueKey('login_submit'),
                                      loading: state.isSubmitting,
                                      onPressed: _submit,
                                    ),
                                    const SizedBox(height: 2),
                                    TextButton(
                                      key: const ValueKey('login_to_register'),
                                      onPressed: state.isSubmitting
                                          ? null
                                          : () => context.go('/register'),
                                      child: const Text('没有账号？立即注册'),
                                    ),
                                    const Spacer(),
                                    KeyedSubtree(
                                      key: const ValueKey(
                                        'login_agreement_footer',
                                      ),
                                      child: AuthAgreement(
                                        value: _agreed,
                                        onChanged: (value) =>
                                            setState(() => _agreed = value),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginBrandContent extends StatelessWidget {
  const _LoginBrandContent({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            key: const ValueKey('login_brand_icon'),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.sports_soccer_rounded,
              color: AppColors.ink,
              size: 38,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            '欢迎使用南看台',
            key: ValueKey('login_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Welcome to the South Stand',
            key: ValueKey('login_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LoginBrandBackground extends StatelessWidget {
  const _LoginBrandBackground({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.brandDark, AppColors.brand, AppColors.accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: CustomPaint(painter: _LoginTexturePainter()),
  );
}

class _LoginTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const tile = 72.0;
    for (var row = 0; row * tile < size.height; row++) {
      for (var column = 0; column * tile < size.width; column++) {
        if ((row + column) % 3 != 0) continue;
        paint.color = Colors.white.withValues(
          alpha: (row + column).isEven ? .035 : .02,
        );
        canvas.drawRect(
          Rect.fromLTWH(column * tile, row * tile, tile, tile),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.loading,
    required this.onPressed,
    super.key,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('登录'),
    ),
  );
}
