import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';

Future<bool> presentAuthAgreement(BuildContext context) async {
  final width = MediaQuery.sizeOf(context).width;
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: width * .14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        key: const ValueKey('auth_agreement_dialog'),
        width: width * .72,
        child: SingleChildScrollView(
          key: const ValueKey('auth_agreement_sheet'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  '服务协议及隐私保护',
                  key: const ValueKey('auth_agreement_title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Text(
                  '为了更好地保障您的合法权益，请阅读并同意以下协议《用户协议》《隐私政策》',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.inkMuted,
                    height: 1.5,
                  ),
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        key: const ValueKey('auth_agreement_decline'),
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: const Text('不同意'),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: TextButton(
                        key: const ValueKey('auth_agreement_accept'),
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brand,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: const Text('同意'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return accepted == true;
}

class AuthAgreement extends StatelessWidget {
  const AuthAgreement({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('auth_agreement'),
    onTap: () async {
      if (value) {
        onChanged(false);
      } else if (await presentAuthAgreement(context)) {
        onChanged(true);
      }
    },
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: 20,
          child: Checkbox(
            key: const ValueKey('auth_agreement_checkbox'),
            value: value,
            onChanged: (checked) => onChanged(checked == true),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: const CircleBorder(),
            side: const BorderSide(color: AppColors.inkMuted, width: 1.5),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.brand;
              }
              return Colors.transparent;
            }),
            checkColor: Colors.white,
          ),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 1),
            child: Text('阅读并同意《用户协议》和《隐私政策》'),
          ),
        ),
      ],
    ),
  );
}
