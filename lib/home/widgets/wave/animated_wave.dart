import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:test_task_beomy_tech/home/widgets/wave/wave_painter.dart';

class AnimatedWave extends StatefulWidget {
  const AnimatedWave({Key? key}) : super(key: key);

  @override
  State<AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<AnimatedWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); 
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double waveOffset = _controller.value * 2 * math.pi;

        return CustomPaint(
          painter: WavePainter(waveOffset),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}
