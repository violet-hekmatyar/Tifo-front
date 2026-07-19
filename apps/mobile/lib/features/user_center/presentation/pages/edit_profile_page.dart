import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/app_design_tokens.dart';
import '../../data/user_center_repository.dart';
import '../../domain/user_center_models.dart';
import '../controllers/user_center_controllers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({required this.summary, super.key});
  final MySummary summary;

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nickname;
  late final TextEditingController _bio;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(text: widget.summary.nickname);
    _bio = TextEditingController(text: widget.summary.bio ?? '');
  }

  @override
  void dispose() {
    _nickname.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nickname = _nickname.text.trim();
    final bio = _bio.text.trim();
    if (nickname.isEmpty || nickname.length > 30 || bio.length > 200) {
      setState(() => _message = '昵称需为 1–30 字，简介最多 200 字。');
      return;
    }
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref
          .read(userCenterRepositoryProvider)
          .updateProfile(nickname: nickname, bio: bio);
      ref.invalidate(mySummaryProvider);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = '保存失败，表单内容已保留，请重试。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('编辑资料')),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        TextField(
          controller: _nickname,
          maxLength: 30,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: '昵称'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _bio,
          maxLength: 200,
          maxLines: 5,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: '简介',
            alignLabelWithHint: true,
          ),
        ),
        if (_message case final message?)
          Text(message, style: const TextStyle(color: AppColors.error)),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: _busy ? null : _save,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_busy ? '保存中' : '保存'),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          '用户名、角色、主队和头像不在本表单中修改。',
          style: TextStyle(color: AppColors.inkMuted),
        ),
      ],
    ),
  );
}
