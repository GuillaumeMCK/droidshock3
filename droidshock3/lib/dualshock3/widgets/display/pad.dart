import '/common/common.dart';

class Pad extends StatelessWidget {
  final double dimension;

  const Pad({super.key, required this.dimension});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: dimension,
      child: CustomPaint(
        painter: _DS3PadPainter(color: context.colorScheme.ds3Pad),
      ),
    );
  }
}

class _DS3PadPainter extends CustomPainter {
  const _DS3PadPainter({required this.color});

  final Color color;
  static const double armRatio = .38;
  static const double cornerRadius = .05;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final a = side / 2;
    final b = side * armRatio / 2;
    final r = side * cornerRadius;
    final ri = r * 1.2;
    final cx = size.width / 2;
    final cy = size.height / 2;

    final path = Path()
      ..moveTo(cx - b + r, cy - a)
      ..lineTo(cx + b - r, cy - a)
      // outer top-right
      ..quadraticBezierTo(cx + b, cy - a, cx + b, cy - a + r)
      ..lineTo(cx + b, cy - b - ri)
      // inner top-right (concave)
      ..quadraticBezierTo(cx + b, cy - b, cx + b + ri, cy - b)
      ..lineTo(cx + a - r, cy - b)
      // outer right-top
      ..quadraticBezierTo(cx + a, cy - b, cx + a, cy - b + r)
      ..lineTo(cx + a, cy + b - r)
      // outer right-bottom
      ..quadraticBezierTo(cx + a, cy + b, cx + a - r, cy + b)
      ..lineTo(cx + b + ri, cy + b)
      // inner bottom-right (concave)
      ..quadraticBezierTo(cx + b, cy + b, cx + b, cy + b + ri)
      ..lineTo(cx + b, cy + a - r)
      // outer bottom-right
      ..quadraticBezierTo(cx + b, cy + a, cx + b - r, cy + a)
      ..lineTo(cx - b + r, cy + a)
      // outer bottom-left
      ..quadraticBezierTo(cx - b, cy + a, cx - b, cy + a - r)
      ..lineTo(cx - b, cy + b + ri)
      // inner bottom-left (concave)
      ..quadraticBezierTo(cx - b, cy + b, cx - b - ri, cy + b)
      ..lineTo(cx - a + r, cy + b)
      // outer left-bottom
      ..quadraticBezierTo(cx - a, cy + b, cx - a, cy + b - r)
      ..lineTo(cx - a, cy - b + r)
      // outer left-top
      ..quadraticBezierTo(cx - a, cy - b, cx - a + r, cy - b)
      ..lineTo(cx - b - ri, cy - b)
      // inner top-left (concave)
      ..quadraticBezierTo(cx - b, cy - b, cx - b, cy - b - ri)
      ..lineTo(cx - b, cy - a + r)
      // outer top-left
      ..quadraticBezierTo(cx - b, cy - a, cx - b + r, cy - a)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_DS3PadPainter o) => o.color != color;
}
