import 'package:flutter/material.dart';

import '../../../shared/widgets/app_state_view.dart';

class DataPlaceholderPage extends StatelessWidget {
  const DataPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('数据')),
    body: const AppStateView(
      kind: AppStateKind.empty,
      title: '足球数据入口已建立',
      message: '球队、球员和比赛深度数据将在 F06 开发。',
    ),
  );
}
