import 'dart:math';

import 'package:flutter/material.dart';
import 'package:desafio_loomi/app/core/themes/app_colors.dart';

class CustomCircleWidget extends StatefulWidget {
  final double circleSize;
  final double lineThickness;
  final double innerCircleSize;

  const CustomCircleWidget({
    super.key,
    required this.circleSize,
    required this.lineThickness,
    required this.innerCircleSize,
  });

  @override
  State<CustomCircleWidget> createState() => _CustomCircleWidgetState();
}

class _CustomCircleWidgetState extends State<CustomCircleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _topCircle;
  late Animation<double> _bottomCircle;
  late Animation<double> _innerCircle;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _topCircle = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _bottomCircle = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _innerCircle = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _scale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
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
          child: CustomPaint(
            size: Size(widget.circleSize, widget.circleSize),
            painter: _CirclePainter(
              topProgress: _topCircle.value,
              bottomProgress: _bottomCircle.value,
              innerProgress: _innerCircle.value,
              lineThickness: widget.lineThickness,
              innerCircleSize: widget.innerCircleSize,
            ),
          ),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double topProgress;
  final double bottomProgress;
  final double innerProgress;
  final double lineThickness;
  final double innerCircleSize;

  _CirclePainter({
    required this.topProgress,
    required this.bottomProgress,
    required this.innerProgress,
    required this.lineThickness,
    required this.innerCircleSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..color = AppColors.white;

    // Desenha o círculo branco completo (será recortado)
    canvas.drawCircle(center, radius, paint);

    // Desenha a linha horizontal central
    final linePaint = Paint()
      ..color = AppColors.black
      ..strokeWidth = lineThickness
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      linePaint,
    );

    // Desenha o círculo preto central animado
    final innerPaint = Paint()..color = AppColors.black;
    canvas.drawCircle(
      center,
      (innerCircleSize / 2) * innerProgress,
      innerPaint,
    );

    // Recorta para criar os semicírculos
    final clipPath = Path()
      ..moveTo(0, center.dy)
      ..lineTo(0, center.dy - (radius * topProgress))
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        pi,
        -pi * topProgress,
        false,
      )
      ..lineTo(size.width, center.dy)
      ..moveTo(size.width, center.dy)
      ..lineTo(size.width, center.dy + (radius * bottomProgress))
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        0,
        pi * bottomProgress,
        false,
      )
      ..lineTo(0, center.dy)
      ..close();

    canvas.clipPath(clipPath);
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) => true;
}
