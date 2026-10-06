import 'package:flutter/material.dart';

import 'app_entity_avatar.dart';

/// 球员头像：有真实照片（`imageUrl`，来自 TheSportsDB）时显示照片，
/// 没有就是本地生成的首字母头像（首字母 + 按 id 稳定的配色，无需任何图片资源）。
class AppPlayerAvatar extends StatelessWidget {
  const AppPlayerAvatar({
    required this.identity,
    required this.name,
    this.imageUrl,
    this.size = 48,
    super.key,
  });

  final String identity;
  final String name;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) => AppEntityAvatar(
    identity: identity,
    semanticLabel: '$name 球员头像',
    fallbackIcon: Icons.person_outline_rounded,
    fallbackText: playerInitials(name),
    imageUrl: imageUrl,
    // 真实照片顶部对齐：卡片多是「宽大于高」，居中裁会切掉头顶、只剩半张脸
    imageAlignment: Alignment.topCenter,
    size: size,
  );
}

/// 本地生成的首字母：拉丁名取「名首字母 + 姓首字母」（Bukayo Saka -> BS），
/// 单字名取首字（林远航 -> 林），取不到返回 null（由组件退化成图标）。
String? playerInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final parts = trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return null;
  }
  if (parts.length >= 2) {
    final first = parts.first.characters.firstOrNull;
    final last = parts.last.characters.firstOrNull;
    if (first == null || last == null) {
      return null;
    }
    return '$first$last'.toUpperCase();
  }
  return parts.first.characters.firstOrNull?.toUpperCase();
}
