import 'dart:math';

import 'package:flutter/material.dart';
import 'package:desafio_loomi/app/core/themes/app_colors.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final double lineThickness;
  final double innerCircleSize;
  final String text;
  final TextStyle textStyle;

  const LogoWidget({
    super.key,
    required this.size,
    this.lineThickness = 10,
    this.innerCircleSize = 60,
    required this.text,
    this.textStyle = const TextStyle(
      color: AppColors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoWithTextPainter(
          lineThickness: lineThickness,
          innerCircleSize: innerCircleSize,
          text: text,
          textStyle: textStyle,
        ),
      ),
    );
  }
}

class _LogoWithTextPainter extends CustomPainter {
  final double lineThickness;
  final double innerCircleSize;
  final String text;
  final TextStyle textStyle;

  _LogoWithTextPainter({
    required this.lineThickness,
    required this.innerCircleSize,
    required this.text,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Desenha os semicírculos brancos
    final whitePaint = Paint()..color = AppColors.white;

    // Semicírculo superior
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi,
      pi,
      false,
      whitePaint,
    );

    // Semicírculo inferior
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      pi,
      false,
      whitePaint,
    );

    // 2. Prepara o texto
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // 3. Desenha o texto na linha central
    final lineTextOffset =
        center - Offset(textPainter.width / 2, textPainter.height / 2);
    _drawTextInArea(
      canvas,
      textPainter,
      lineTextOffset,
      Rect.fromCenter(
        center: center,
        width: size.width,
        height: lineThickness,
      ),
    );

    // 4. Desenha o texto no círculo central
    final circleTextOffset =
        center - Offset(textPainter.width / 2, textPainter.height / 2);
    _drawTextInArea(
      canvas,
      textPainter,
      circleTextOffset,
      Rect.fromCircle(center: center, radius: innerCircleSize / 2),
    );

    // 5. Desenha as partes pretas por cima para "cortar" o texto
    final blackPaint = Paint()..color = AppColors.black;

    // Linha central
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      blackPaint
        ..strokeWidth = lineThickness
        ..strokeCap = StrokeCap.round,
    );

    // Círculo central
    canvas.drawCircle(center, innerCircleSize / 2, blackPaint);
  }

  void _drawTextInArea(
      Canvas canvas, TextPainter textPainter, Offset offset, Rect area) {
    canvas.save();
    canvas.clipRect(area);
    textPainter.paint(canvas, offset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoWithTextPainter oldDelegate) =>
      oldDelegate.lineThickness != lineThickness ||
      oldDelegate.innerCircleSize != innerCircleSize ||
      oldDelegate.text != text ||
      oldDelegate.textStyle != textStyle;
}
