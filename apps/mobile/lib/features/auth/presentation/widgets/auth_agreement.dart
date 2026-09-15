import 'package:flutter/material.dart';

import '../../../../shared/design_system/app_design_tokens.dart';

Future<bool> presentAuthAgreement(BuildContext context) async {
  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => SingleChildScrollView(
      key: const ValueKey('auth_agreement_sheet'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('请确认协议', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const Text('请阅读并同意用户协议和隐私政策后继续。'),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('auth_agreement_decline'),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('不同意'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('auth_agreement_accept'),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('同意并继续'),
                ),
              ),
            ],
          ),
        ],
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
      } else {
        if (await presentAuthAgreement(context)) onChanged(true);
      }
    },
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          key: const ValueKey('auth_agreement_checkbox'),
          value: value,
          onChanged: (checked) => onChanged(checked == true),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('我已阅读并同意《用户协议》和《隐私政策》'),
          ),
        ),
      ],
    ),
  );
}
