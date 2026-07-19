import 'package:flutter/material.dart';
import '../../../shared/widgets/app_state_view.dart';

class MessagesUnavailablePage extends StatelessWidget {
  const MessagesUnavailablePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('消息')),
    body: const AppStateView(
      kind: AppStateKind.empty,
      title: '消息能力暂不可用',
      message: '当前后端没有消息、通知或会话接口，因此这里不会展示虚构消息。后端提供正式契约后再接入。',
    ),
  );
}
