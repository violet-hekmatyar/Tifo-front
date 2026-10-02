import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AppStateIllustrationType {
  searchEmpty,
  networkError,
  noFollowing,
  noFollowingTeams,
  noHistory,
  noComments,
  noFavorites,
  noData,
  noMessages,
}

extension AppStateIllustrationTypeLabel on AppStateIllustrationType {
  String get label => switch (this) {
    AppStateIllustrationType.searchEmpty => '搜索无结果',
    AppStateIllustrationType.networkError => '网络故障',
    AppStateIllustrationType.noFollowing => '暂无关注',
    AppStateIllustrationType.noFollowingTeams => '暂无关注球队',
    AppStateIllustrationType.noHistory => '暂无浏览记录',
    AppStateIllustrationType.noComments => '暂无评论',
    AppStateIllustrationType.noFavorites => '暂无收藏',
    AppStateIllustrationType.noData => '暂无数据',
    AppStateIllustrationType.noMessages => '暂无消息',
  };
}

class AppStateIllustration extends StatelessWidget {
  const AppStateIllustration({required this.type, this.size = 128, super.key});

  final AppStateIllustrationType type;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: type.label,
    image: true,
    child: SizedBox.square(
      key: ValueKey('app_state_illustration_${type.name}'),
      dimension: size,
      child: CustomPaint(painter: _AppStateIllustrationPainter(type)),
    ),
  );
}

class _AppStateIllustrationPainter extends CustomPainter {
  _AppStateIllustrationPainter(this.type);

  final AppStateIllustrationType type;

  static const _green = Color(0xff12c878);
  static const _greenDark = Color(0xff08b66d);
  static const _shadow = Color(0xff474b4d);
  static const _guide = Color(0xff676b6d);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 64;
    canvas.save();
    canvas.scale(scale, scale);
    _drawRays(canvas);
    switch (type) {
      case AppStateIllustrationType.searchEmpty:
        _drawSearch(canvas);
      case AppStateIllustrationType.networkError:
        _drawNetwork(canvas);
      case AppStateIllustrationType.noFollowing:
        _drawPerson(canvas);
      case AppStateIllustrationType.noFollowingTeams:
        _drawShield(canvas);
      case AppStateIllustrationType.noHistory:
        _drawClock(canvas);
      case AppStateIllustrationType.noComments:
        _drawComments(canvas);
      case AppStateIllustrationType.noFavorites:
        _drawStar(canvas);
      case AppStateIllustrationType.noData:
        _drawPie(canvas);
      case AppStateIllustrationType.noMessages:
        _drawBell(canvas);
    }
    canvas.restore();
  }

  void _drawRays(Canvas canvas) {
    final paint = Paint()
      ..color = _green
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(25, 12), const Offset(22, 6), paint);
    canvas.drawLine(const Offset(32, 11), const Offset(32, 5), paint);
    canvas.drawLine(const Offset(39, 12), const Offset(42, 6), paint);
  }

  Paint _fill(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  void _shadowed(Canvas canvas, VoidCallback draw) {
    canvas.save();
    canvas.translate(5, 4);
    draw();
    canvas.restore();
  }

  void _drawGuideCircle(Canvas canvas, Offset center, double radius) {
    final paint = _stroke(_guide.withValues(alpha: .75), .8);
    for (var i = 0; i < 28; i++) {
      final angle = (math.pi * 2 * i) / 28;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(point, .65, paint..style = PaintingStyle.fill);
    }
  }

  void _drawSearch(Canvas canvas) {
    _drawGuideCircle(canvas, const Offset(28, 32), 19);
    _shadowed(canvas, () {
      canvas.drawCircle(const Offset(28, 32), 13, _fill(_shadow));
      canvas.drawLine(
        const Offset(38, 42),
        const Offset(50, 54),
        _stroke(_shadow, 7),
      );
    });
    canvas.drawCircle(const Offset(27, 31), 13, _stroke(_green, 6));
    canvas.drawLine(
      const Offset(37, 41),
      const Offset(49, 53),
      _stroke(_green, 7),
    );
  }

  void _drawNetwork(Canvas canvas) {
    _shadowed(canvas, () {
      final paint = _stroke(_shadow, 5);
      canvas.drawArc(
        const Rect.fromLTWH(15, 17, 38, 26),
        math.pi * 1.1,
        math.pi * .8,
        false,
        paint,
      );
      canvas.drawArc(
        const Rect.fromLTWH(22, 25, 24, 18),
        math.pi * 1.1,
        math.pi * .8,
        false,
        paint,
      );
      canvas.drawCircle(const Offset(34, 49), 2.5, _fill(_shadow));
    });
    final paint = _stroke(_green, 5);
    canvas.drawArc(
      const Rect.fromLTWH(13, 15, 38, 26),
      math.pi * 1.1,
      math.pi * .8,
      false,
      paint,
    );
    canvas.drawArc(
      const Rect.fromLTWH(20, 23, 24, 18),
      math.pi * 1.1,
      math.pi * .8,
      false,
      paint,
    );
    canvas.drawCircle(const Offset(32, 47), 6, _fill(_green));
    canvas.drawLine(
      const Offset(29.5, 44.5),
      const Offset(34.5, 49.5),
      _stroke(Colors.white, 2.4),
    );
    canvas.drawLine(
      const Offset(34.5, 44.5),
      const Offset(29.5, 49.5),
      _stroke(Colors.white, 2.4),
    );
  }

  void _drawPerson(Canvas canvas) {
    _shadowed(canvas, () {
      canvas.drawCircle(const Offset(33, 29), 10, _fill(_shadow));
      canvas.drawOval(const Rect.fromLTWH(17, 39, 34, 18), _fill(_shadow));
    });
    canvas.drawCircle(const Offset(27, 28), 10, _fill(_green));
    canvas.drawOval(const Rect.fromLTWH(11, 38, 34, 18), _fill(_green));
    canvas.drawArc(
      const Rect.fromLTWH(14, 39, 36, 17),
      math.pi,
      math.pi,
      false,
      _stroke(_greenDark, 1.2),
    );
    canvas.drawCircle(const Offset(28, 28), 10, _stroke(_green, 1.2));
  }

  Path _shieldPath({double offsetX = 0, double offsetY = 0}) => Path()
    ..moveTo(31 + offsetX, 17 + offsetY)
    ..lineTo(49 + offsetX, 23 + offsetY)
    ..lineTo(48 + offsetX, 41 + offsetY)
    ..cubicTo(
      46 + offsetX,
      49 + offsetY,
      38 + offsetX,
      54 + offsetY,
      31 + offsetX,
      57 + offsetY,
    )
    ..cubicTo(
      24 + offsetX,
      54 + offsetY,
      16 + offsetX,
      49 + offsetY,
      14 + offsetX,
      41 + offsetY,
    )
    ..lineTo(13 + offsetX, 23 + offsetY)
    ..close();

  void _drawShield(Canvas canvas) {
    canvas.drawPath(_shieldPath(offsetX: 5, offsetY: 4), _fill(_shadow));
    canvas.drawPath(_shieldPath(), _fill(_green));
    final star = Path()..moveTo(31, 25);
    for (var i = 1; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isOdd ? 10.5 : 4.5;
      star.lineTo(31 + math.cos(angle) * radius, 36 + math.sin(angle) * radius);
    }
    star.close();
    canvas.drawPath(star, _fill(Colors.white));
  }

  void _drawClock(Canvas canvas) {
    _shadowed(canvas, () {
      canvas.drawCircle(const Offset(33, 36), 16, _fill(_shadow));
    });
    canvas.drawCircle(const Offset(28, 32), 16, _fill(_green));
    canvas.drawLine(
      const Offset(28, 21),
      const Offset(28, 33),
      _stroke(Colors.white, 4),
    );
    canvas.drawLine(
      const Offset(28, 33),
      const Offset(36, 41),
      _stroke(Colors.white, 4),
    );
    _drawGuideCircle(canvas, const Offset(28, 32), 19);
  }

  void _drawComments(Canvas canvas) {
    _shadowed(canvas, () {
      final bubble = RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 24, 34, 24),
        const Radius.circular(7),
      );
      canvas.drawRRect(bubble, _fill(_shadow));
      canvas.drawPath(
        Path()
          ..moveTo(42, 48)
          ..lineTo(48, 55)
          ..lineTo(49, 47)
          ..close(),
        _fill(_shadow),
      );
    });
    final bubble = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 18, 38, 28),
      const Radius.circular(7),
    );
    canvas.drawRRect(bubble, _fill(_green));
    canvas.drawPath(
      Path()
        ..moveTo(20, 46)
        ..lineTo(16, 54)
        ..lineTo(29, 46)
        ..close(),
      _fill(_green),
    );
    for (final x in [21.0, 29.0, 37.0]) {
      canvas.drawCircle(Offset(x, 32), 2.5, _fill(Colors.white));
    }
  }

  Path _starPath({double dx = 0, double dy = 0}) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? 18.0 : 8.5;
      final point = Offset(
        29 + dx + math.cos(angle) * radius,
        34 + dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  void _drawStar(Canvas canvas) {
    canvas.drawPath(_starPath(dx: 5, dy: 4), _fill(_shadow));
    canvas.drawPath(_starPath(), _fill(_green));
  }

  void _drawPie(Canvas canvas) {
    _shadowed(canvas, () {
      canvas.drawCircle(const Offset(34, 35), 17, _fill(_shadow));
    });
    canvas.drawCircle(const Offset(28, 30), 17, _fill(_green));
    final wedge = Path()
      ..moveTo(28, 30)
      ..lineTo(28, 13)
      ..arcTo(
        const Rect.fromLTWH(11, 13, 34, 34),
        -math.pi / 2,
        math.pi / 2,
        false,
      )
      ..close();
    canvas.drawPath(wedge, _fill(Colors.white));
    canvas.drawLine(
      const Offset(28, 30),
      const Offset(28, 13),
      _stroke(_greenDark, 1.5),
    );
    canvas.drawLine(
      const Offset(28, 30),
      const Offset(45, 30),
      _stroke(_greenDark, 1.5),
    );
    _drawGuideCircle(canvas, const Offset(28, 30), 20);
  }

  void _drawBell(Canvas canvas) {
    _shadowed(canvas, () {
      final path = _bellPath(dx: 5, dy: 4);
      canvas.drawPath(path, _fill(_shadow));
      canvas.drawCircle(const Offset(37, 56), 3, _fill(_shadow));
    });
    canvas.drawPath(_bellPath(), _fill(_green));
    canvas.drawCircle(const Offset(32, 56), 3, _fill(_green));
    canvas.drawLine(
      const Offset(20, 49),
      const Offset(14, 54),
      _stroke(_green, 4),
    );
  }

  Path _bellPath({double dx = 0, double dy = 0}) => Path()
    ..moveTo(17 + dx, 48 + dy)
    ..cubicTo(20 + dx, 45 + dy, 19 + dx, 42 + dy, 19 + dx, 34 + dy)
    ..cubicTo(19 + dx, 23 + dy, 25 + dx, 17 + dy, 32 + dx, 17 + dy)
    ..cubicTo(40 + dx, 17 + dy, 45 + dx, 24 + dy, 45 + dx, 34 + dy)
    ..cubicTo(45 + dx, 42 + dy, 44 + dx, 45 + dy, 48 + dx, 48 + dy)
    ..lineTo(48 + dx, 51 + dy)
    ..lineTo(16 + dx, 51 + dy)
    ..close();

  @override
  bool shouldRepaint(covariant _AppStateIllustrationPainter oldDelegate) =>
      oldDelegate.type != type;
}
