import 'dart:math';
import 'package:flutter/material.dart';

import '/common/common.dart';

Paint _stroke(Color color, double strokeWidth) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = strokeWidth
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.miter;

double _inscribedSide(Size size) => size.shortestSide * sqrt1_2;

class DS3CirclePainter extends CustomPainter {
  const DS3CirclePainter({
    this.color = const Color(0xFFE04646),
    this.strokeWidth = 2.5,
    this.padding = const EdgeInsets.all(2),
  });

  final Color color;
  final EdgeInsets padding;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paddedSize = Size(
      size.width - padding.horizontal,
      size.height - padding.vertical,
    );

    canvas.drawCircle(
      paddedSize.center(Offset(padding.left, padding.top)),
      (paddedSize.shortestSide - strokeWidth) / 2,
      _stroke(color, strokeWidth),
    );
  }

  @override
  bool shouldRepaint(DS3CirclePainter o) =>
      o.color != color || o.strokeWidth != strokeWidth;
}

class DS3CrossPainter extends CustomPainter {
  const DS3CrossPainter({
    this.color = const Color(0xFF5A7FD4),
    this.strokeWidth = 2.5,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final arm = (_inscribedSide(size) - strokeWidth) / 2;
    final c = size.center(Offset.zero);
    final p = _stroke(color, strokeWidth);

    canvas
      ..drawLine(c + Offset(-arm, -arm), c + Offset(arm, arm), p)
      ..drawLine(c + Offset(arm, -arm), c + Offset(-arm, arm), p);
  }

  @override
  bool shouldRepaint(DS3CrossPainter o) =>
      o.color != color || o.strokeWidth != strokeWidth;
}

class DS3SquarePainter extends CustomPainter {
  const DS3SquarePainter({
    this.color = const Color(0xFFD050C8),
    this.strokeWidth = 2.5,
    this.cornerRadiusFraction = 0.06,
  });

  final Color color;
  final double strokeWidth;
  final double cornerRadiusFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final side = _inscribedSide(size) - strokeWidth;
    final ox = (size.width - side) / 2;
    final oy = (size.height - side) / 2;

    canvas.drawRRect(
      RRect.fromLTRBR(ox, oy, ox + side, oy + side, .zero),
      _stroke(color, strokeWidth),
    );
  }

  @override
  bool shouldRepaint(DS3SquarePainter o) =>
      o.color != color ||
      o.strokeWidth != strokeWidth ||
      o.cornerRadiusFraction != cornerRadiusFraction;
}

class DS3TrianglePainter extends CustomPainter {
  const DS3TrianglePainter({
    this.color = const Color(0xFF1FA37E),
    this.strokeWidth = 2.5,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final a = _inscribedSide(size) - strokeWidth;
    final h = a * sqrt(3) / 2;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final top = cy - h * 2 / 3;
    final bottom = cy + h / 3;

    final path = Path()
      ..moveTo(cx, top)
      ..lineTo(cx + a / 2, bottom)
      ..lineTo(cx - a / 2, bottom)
      ..close();

    canvas.drawPath(path, _stroke(color, strokeWidth));
  }

  @override
  bool shouldRepaint(DS3TrianglePainter o) =>
      o.color != color || o.strokeWidth != strokeWidth;
}

Paint _fill(Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.fill;

class DS3DirectionPainter extends CustomPainter {
  const DS3DirectionPainter({
    required this.color,
    required this.borderColor,
    required this.direction,
    this.borderWidth = 1.0,
    this.radius = 4.0,
  });

  final Color color;
  final Color borderColor;
  final double borderWidth;
  final DS3Direction direction;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(switch (direction) {
      DS3Direction.right => 0.0,
      DS3Direction.down => pi / 2,
      DS3Direction.left => pi,
      DS3Direction.up => -pi / 2,
    });
    canvas.translate(-size.width / 2, -size.height / 2);

    final pts = [
      Offset(0, size.height - 4),
      Offset(0, 4),
      Offset(size.width / 1.4, 4),
      Offset(size.width, size.height / 2),
      Offset(size.width / 1.4, size.height - 4),
    ];

    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      final prev = pts[(i - 1 + pts.length) % pts.length];
      final curr = pts[i];
      final next = pts[(i + 1) % pts.length];
      final p1 = curr - (curr - prev) / (curr - prev).distance * radius;
      final p2 = curr + (next - curr) / (next - curr).distance * radius;
      i == 0 ? path.moveTo(p1.dx, p1.dy) : path.lineTo(p1.dx, p1.dy);
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
    path.close();

    canvas.drawPath(path, _fill(color));
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(DS3DirectionPainter old) =>
      old.color != color ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.direction != direction ||
      old.radius != radius;
}

enum DS3Direction { up, down, left, right }
