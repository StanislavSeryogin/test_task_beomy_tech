import 'package:flutter/material.dart';
import 'dart:math' as math;

class SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final sunRadius = math.min(size.width, size.height) / 4;
    final rayLength = sunRadius * 1.5;
    const rayCount = 12;
    final sunPaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(center, sunRadius, sunPaint);

    final rayPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < rayCount; i++) {
      
      final angle = i * (2 * math.pi / rayCount);
      final startX = center.dx + sunRadius * math.cos(angle);
      final startY = center.dy + sunRadius * math.sin(angle);

      final endX = center.dx + rayLength * math.cos(angle);
      final endY = center.dy + rayLength * math.sin(angle);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(SunPainter oldDelegate) => false;
}