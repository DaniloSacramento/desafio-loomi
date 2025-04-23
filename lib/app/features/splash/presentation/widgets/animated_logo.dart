import 'dart:math';

import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:flutter/material.dart';

class AnimatedLogo extends StatefulWidget {
  final double size;

  const AnimatedLogo({super.key, this.size = 200});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _rotation;
  late Animation<double> _opacity;
  late Animation<Color?> _color;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..forward();

    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOutCubic),
      ),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _color = ColorTween(
      begin: AppColors.primary.withOpacity(0),
      end: AppColors.primary,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0),
      ),
    );
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
        return Transform.scale(
          scale: _scale.value,
          child: Transform.rotate(
            angle: _rotation.value,
            child: Opacity(
              opacity: _opacity.value,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _LogoPainter(
                  color: _color.value ?? AppColors.primary,
                  progress: _controller.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  final double progress;

  _LogoPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    // Desenha os arcos animados
    final arc1Start = -pi / 2;
    final arc1End = arc1Start + 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      arc1Start,
      arc1End - arc1Start,
      false,
      paint,
    );

    // Arco interno
    final innerPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 8;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.6),
      arc1Start + pi / 4,
      (arc1End - arc1Start) * 1.5,
      false,
      innerPaint,
    );

    // Círculo central pulsante
    final pulseProgress = sin(progress * pi * 4) * 0.5 + 0.5;
    final centerPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      center,
      radius * 0.2 * (0.5 + pulseProgress * 0.5),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => true;
}
