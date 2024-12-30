import 'package:flutter/material.dart';
import 'package:test_task_beomy_tech/home/widgets/sun/sun_painter.dart';

class AnimatedSun extends StatefulWidget {
  const AnimatedSun({super.key});

  @override
  State<AnimatedSun> createState() => _AnimatedSunState();
}

class _AnimatedSunState extends State<AnimatedSun>
    with SingleTickerProviderStateMixin {
  late AnimationController _sunController;

  @override
  void initState() {
    super.initState();
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..repeat();
  }

  @override
  void dispose() {
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sunController,
      builder: (context, child) {
        final angle = _sunController.value * 2;

        return Transform.rotate(
          angle: angle,
          child: CustomPaint(
            painter: SunPainter(),
            size: const Size(200, 200),
          ),
        );
      },
    );
  }
}
