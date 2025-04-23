import 'dart:math';

import 'package:desafio_loomi/app/core/themes/app_colors.dart';
import 'package:flutter/material.dart';

class HalfCircleWithLine extends StatelessWidget {
  final double size; // Tamanho base do logo
  final double
      lineThicknessRatio; // Proporção da espessura da linha (0.0 a 1.0)
  final double innerCircleRatio; // Proporção do círculo interno (0.0 a 1.0)

  const HalfCircleWithLine({
    super.key,
    required this.size,
    this.lineThicknessRatio = 0.15, // 15% do tamanho total
    this.innerCircleRatio = 0.46, // 46% do tamanho total
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HalfCircleWithLinePainter(
          lineThickness: size * lineThicknessRatio,
          innerCircleSize: size * innerCircleRatio,
        ),
      ),
    );
  }
}

class _HalfCircleWithLinePainter extends CustomPainter {
  final double lineThickness;
  final double innerCircleSize;

  _HalfCircleWithLinePainter({
    required this.lineThickness,
    required this.innerCircleSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..color = AppColors.white;

    // Desenha o círculo branco completo
    canvas.drawCircle(center, radius, paint);

    // Linha horizontal central
    final linePaint = Paint()
      ..color = AppColors.black
      ..strokeWidth = lineThickness
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      linePaint,
    );

    // Círculo preto central
    final innerPaint = Paint()..color = AppColors.black;
    canvas.drawCircle(center, innerCircleSize / 2, innerPaint);

    // Recorta para criar os semicírculos
    final clipPath = Path()
      ..moveTo(0, center.dy)
      ..lineTo(0, 0)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), pi, -pi, false)
      ..lineTo(size.width, center.dy)
      ..close();

    canvas.clipPath(clipPath);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
