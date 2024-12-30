import 'dart:math' as math;
import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final double waveOffset;

  WavePainter(this.waveOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent.withAlpha((0.3 * 255).toInt())
      ..style = PaintingStyle.fill;

    const double amplitude = 20;
    final double baseHeight = size.height * 0.5;

    final path = Path();
    path.moveTo(0, baseHeight);

    for (double x = 0; x <= size.width; x++) {
      final y =
          amplitude * math.sin((x / size.width * 2 * math.pi) + waveOffset) +
              baseHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return true;
  }
}
