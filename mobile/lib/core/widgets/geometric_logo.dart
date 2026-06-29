import 'package:flutter/material.dart';

class GeometricLogo extends StatelessWidget {
  final double size;
  final Color color;
  const GeometricLogo({super.key, this.size = 72, this.color = const Color(0xFF555555)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GeoPainter(color: color)),
    );
  }
}

class _GeoPainter extends CustomPainter {
  final Color color;
  _GeoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.46;

    final pts = List.generate(6, (i) {
      final angle = (i * 60 - 30) * 3.14159 / 180;
      return Offset(cx + r * cos(angle), cy + r * sin(angle));
    });

    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);

    final inner = r * 0.52;
    final ipts = List.generate(3, (i) {
      final angle = (i * 120 + 90) * 3.14159 / 180;
      return Offset(cx + inner * cos(angle), cy + inner * sin(angle));
    });
    canvas.drawLine(ipts[0], ipts[1], paint);
    canvas.drawLine(ipts[1], ipts[2], paint);
    canvas.drawLine(ipts[2], ipts[0], paint);

    canvas.drawLine(pts[0], ipts[0], paint);
    canvas.drawLine(pts[2], ipts[1], paint);
    canvas.drawLine(pts[4], ipts[2], paint);
  }

  double cos(double r) => r < 0 ? -_cos(-r) : _cos(r);
  double sin(double r) => r < 0 ? -_sin(-r) : _sin(r);

  double _cos(double r) {
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= -r * r / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  double _sin(double r) {
    double result = r;
    double term = r;
    for (int i = 1; i <= 10; i++) {
      term *= -r * r / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
