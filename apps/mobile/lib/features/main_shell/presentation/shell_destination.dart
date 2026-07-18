import 'package:flutter/material.dart';

enum ShellDestination {
  home('首页', Icons.home_outlined, Icons.home_rounded),
  data('数据', Icons.sports_soccer_outlined, Icons.sports_soccer_rounded),
  messages('消息', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
  profile('我的', Icons.person_outline_rounded, Icons.person_rounded);

  const ShellDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
