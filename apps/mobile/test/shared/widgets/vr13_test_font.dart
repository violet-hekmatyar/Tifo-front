import 'dart:io';

import 'package:flutter/services.dart';

const vr13TestFontFamily = 'VR13SimHei';
const vr13TestFontPath = r'C:\Windows\Fonts\simhei.ttf';

Future<void> loadVr13TestFont() {
  return _fontLoad ??= _loadVr13TestFont();
}

Future<void>? _fontLoad;

Future<void> _loadVr13TestFont() async {
  final file = File(vr13TestFontPath);
  if (!file.existsSync()) {
    throw StateError('VR13 CJK test font is missing: $vr13TestFontPath');
  }
  final bytes = await file.readAsBytes();
  final loader = FontLoader(vr13TestFontFamily)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}
