import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../publish/publish_local_source.dart';

class PublishAuxiliaryPage extends StatefulWidget {
  const PublishAuxiliaryPage({required this.kind, super.key});

  final PublishAuxiliaryKind kind;

  @override
  State<PublishAuxiliaryPage> createState() => _PublishAuxiliaryPageState();
}

class _PublishAuxiliaryPageState extends State<PublishAuxiliaryPage> {
  final _search = TextEditingController();
  String? _selected;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = PublishLocalSource.filter(widget.kind, _search.text);
    final isTopic = widget.kind == PublishAuxiliaryKind.topic;
    return Scaffold(
      appBar: AppBar(
        title: Text(isTopic ? '添加话题' : '关联热点事件'),
        actions: [
          TextButton(
            key: const ValueKey('publish_auxiliary_done'),
            onPressed: () => context.pop(
              items.where((item) => item.id == _selected).firstOrNull,
            ),
            child: const Text('完成', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextField(
              key: ValueKey(
                isTopic ? 'publish_topic_search' : 'publish_hotspot_search',
              ),
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: isTopic ? '搜索话题' : '搜索热点事件',
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isTopic ? '热门话题' : '热点事件',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Center(child: Text('没有找到匹配内容')),
              )
            else
              for (final item in items)
                Card(
                  child: ListTile(
                    key: ValueKey('${item.kind.name}_${item.id}'),
                    title: Text('#${item.name}'),
                    subtitle: Text('${item.count} 人正在讨论'),
                    trailing: _selected == item.id
                        ? const Icon(Icons.check_circle, color: AppColors.brand)
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => setState(() => _selected = item.id),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
