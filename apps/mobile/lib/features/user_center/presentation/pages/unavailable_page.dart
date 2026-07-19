import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_state_view.dart';

class UnavailablePage extends StatelessWidget {
  const UnavailablePage({
    required this.title,
    required this.message,
    super.key,
  });
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: AppStateView(
      kind: AppStateKind.empty,
      title: '$title暂不可用',
      message: message,
    ),
  );
}
