import 'package:flutter/material.dart';

abstract final class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x140B3B26), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static const floatingNavigation = <BoxShadow>[
    BoxShadow(color: Color(0x1A0B3B26), blurRadius: 20, offset: Offset(0, 8)),
  ];
}
