import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';

class PublishEntryPage extends StatelessWidget {
  const PublishEntryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('发布内容')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _PublishTypeCard(
          key: const ValueKey('publish_type_post'),
          icon: Icons.post_add_rounded,
          title: '发布帖子',
          subtitle: '适合快速分享观点和多张图片',
          onTap: () => context.push('/publish/post'),
        ),
        const SizedBox(height: AppSpacing.md),
        _PublishTypeCard(
          key: const ValueKey('publish_type_article'),
          icon: Icons.article_outlined,
          title: '撰写文章',
          subtitle: '按顺序编排文字、图片和关联内容',
          onTap: () => context.push('/publish/article'),
        ),
      ],
    ),
  );
}

class _PublishTypeCard extends StatelessWidget {
  const _PublishTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(AppSpacing.md),
      leading: Icon(icon, color: AppColors.brand, size: 36),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}
