import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_state_view.dart';

class KnockoutTreePlaceholderPage extends StatelessWidget {
  const KnockoutTreePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('淘汰树'),
      leading: IconButton(
        tooltip: '返回',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: const AppStateView(
      key: ValueKey('knockout_tree_placeholder'),
      kind: AppStateKind.empty,
      title: '淘汰树正在开发',
      message: '当前版本暂不展示淘汰树对阵，返回赛事页面继续浏览。',
    ),
  );
}
