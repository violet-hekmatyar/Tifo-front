import 'package:flutter/material.dart';

import '../../../shared/widgets/app_state_view.dart';

class MessagesPlaceholderPage extends StatelessWidget {
  const MessagesPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('消息')),
    body: const AppStateView(
      kind: AppStateKind.empty,
      title: '消息入口已建立',
      message: '通知与消息能力将在 F07 开发，本页不展示虚构消息。',
    ),
  );
}
