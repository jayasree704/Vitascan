import 'package:flutter/material.dart';

class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final scale = s / 24.0;
    canvas.scale(scale, scale);

    // Official Google 'G' Vector Path geometry (24x24 grid)
    // 1. Red Segment (Top)
    final redPath = Path()
      ..moveTo(12.0, 5.0)
      ..cubicTo(14.5, 5.0, 16.7, 5.9, 18.4, 7.5)
      ..lineTo(21.9, 4.0)
      ..cubicTo(19.3, 1.5, 15.9, 0.0, 12.0, 0.0)
      ..cubicTo(7.3, 0.0, 3.3, 2.7, 1.3, 6.6)
      ..lineTo(5.2, 9.6)
      ..cubicTo(6.1, 6.9, 8.8, 5.0, 12.0, 5.0)
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));

    // 2. Yellow Segment (Left)
    final yellowPath = Path()
      ..moveTo(5.2, 9.6)
      ..cubicTo(4.7, 11.0, 4.5, 12.5, 4.5, 14.0)
      ..cubicTo(4.5, 15.5, 4.7, 17.0, 5.2, 18.4)
      ..lineTo(1.3, 21.4)
      ..cubicTo(0.5, 19.1, 0.0, 16.6, 0.0, 14.0)
      ..cubicTo(0.0, 11.4, 0.5, 8.9, 1.3, 6.6)
      ..lineTo(5.2, 9.6)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));

    // 3. Green Segment (Bottom)
    final greenPath = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(15.8, 23.0, 19.0, 21.7, 21.3, 19.6)
      ..lineTo(17.4, 16.6)
      ..cubicTo(16.0, 17.6, 14.2, 18.2, 12.0, 18.2)
      ..cubicTo(8.8, 18.2, 6.1, 16.3, 5.2, 13.6)
      ..lineTo(1.3, 16.6)
      ..cubicTo(3.3, 20.5, 7.3, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));

    // 4. Blue Segment (Right & Center Bar)
    final bluePath = Path()
      ..moveTo(23.5, 14.3)
      ..cubicTo(23.7, 13.5, 23.8, 12.8, 23.8, 12.0)
      ..cubicTo(23.8, 11.2, 23.7, 10.5, 23.5, 9.7)
      ..lineTo(12.0, 9.7)
      ..lineTo(12.0, 14.3)
      ..lineTo(18.6, 14.3)
      ..cubicTo(17.8, 16.6, 16.0, 18.4, 13.6, 19.2)
      ..lineTo(17.4, 22.2)
      ..cubicTo(21.1, 20.5, 23.5, 17.7, 23.5, 14.3)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}
