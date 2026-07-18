import 'package:flutter/material.dart';

import '../../../shared/widgets/app_state_view.dart';

class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({
    required this.title,
    required this.message,
    this.detail,
    super.key,
  });

  final String title;
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: AppStateView(
      kind: AppStateKind.empty,
      title: message,
      message: detail ?? '当前页面尚未进入实现阶段。',
    ),
  );
}
