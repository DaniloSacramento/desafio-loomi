import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    color: AppColors.buttonText,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.normal,
  );
}
