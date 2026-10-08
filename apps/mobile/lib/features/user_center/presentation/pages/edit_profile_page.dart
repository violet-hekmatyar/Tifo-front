import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/media_url_resolver.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/design_system/app_design_tokens.dart';
import '../../../../shared/widgets/app_entity_avatar.dart';
import '../../data/user_center_repository.dart';
import '../../domain/user_center_models.dart';
import '../controllers/user_center_controllers.dart';

final _usernamePattern = RegExp(r'^[A-Za-z0-9_]+$');

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({required this.summary, super.key});
  final MySummary summary;

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nickname;
  late final TextEditingController _username;
  late final TextEditingController _bio;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _nickname = TextEditingController(text: widget.summary.nickname);
    _username = TextEditingController(text: widget.summary.username);
    _bio = TextEditingController(text: widget.summary.bio ?? '');
  }

  @override
  void dispose() {
    _nickname.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nickname = _nickname.text.trim();
    final username = _username.text.trim();
    final bio = _bio.text.trim();
    if (nickname.isEmpty || nickname.length > 30 || bio.length > 200) {
      setState(() => _message = '昵称需为 1–30 字，简介最多 200 字。');
      return;
    }
    final usernameChanged = username != widget.summary.username;
    if (usernameChanged &&
        (username.length < 3 ||
            username.length > 64 ||
            !_usernamePattern.hasMatch(username))) {
      setState(() => _message = '用户名需为 3–64 位字母、数字或下划线。');
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
          .updateProfile(
            nickname: nickname,
            bio: bio,
            username: usernameChanged ? username : null,
          );
      ref.invalidate(mySummaryProvider);
      ref.invalidate(myProfileControllerProvider);
      if (mounted) context.pop();
    } on BusinessException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _message = error.message;
        });
      }
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
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final avatar = ref.watch(avatarUpdateControllerProvider);
    final avatarUrl = avatar.state.avatarUrl ?? widget.summary.avatarUrl;
    final initial = widget.summary.nickname.trim().isEmpty
        ? '我'
        : widget.summary.nickname.characters.first;
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(title: const Text('编辑资料')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              AppEntityAvatar(
                key: const ValueKey('edit_profile_avatar'),
                identity: 'user:${widget.summary.userId}',
                semanticLabel: '头像',
                fallbackIcon: Icons.person_outline_rounded,
                fallbackText: initial,
                fallbackAsset: 'assets/ui/profile/user-demo.png',
                imageUrl: resolveMediaUrl(config, avatarUrl),
                size: 72,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('edit_profile_change_avatar'),
                  onPressed: avatar.state.busy
                      ? null
                      : avatar.chooseAndUpload,
                  icon: avatar.state.busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_outlined),
                  label: Text(avatar.state.busy ? '上传中' : '更换头像'),
                ),
              ),
            ],
          ),
          if (avatar.state.message case final message?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(message, style: const TextStyle(color: AppColors.error)),
            ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const ValueKey('edit_profile_username'),
            controller: _username,
            maxLength: 64,
            enabled: !_busy,
            decoration: const InputDecoration(
              labelText: '用户名',
              helperText: '3–64 位字母、数字或下划线，修改后用于登录',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey('edit_profile_nickname'),
            controller: _nickname,
            maxLength: 30,
            enabled: !_busy,
            decoration: const InputDecoration(labelText: '昵称'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const ValueKey('edit_profile_bio'),
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
            key: const ValueKey('edit_profile_save'),
            onPressed: _busy ? null : _save,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_busy ? '保存中' : '保存'),
          ),
        ],
      ),
    );
  }
}
