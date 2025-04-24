import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const TextStyle primaryButtonText = TextStyle(
    fontSize: 16, // Or 15 as you had initially
    color: AppColors.textOnPrimary, // Use the defined white color
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  // Existing style, maybe rename if it's for secondary buttons now
  static const TextStyle secondaryButtonText = TextStyle(
    fontSize: 16,
    color: AppColors.buttonSecondaryText, // Light purple
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  // Existing bodyText
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.normal,
  );

  // Existing title
  static const TextStyle title = TextStyle(
    fontSize: 20,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
  );

  // Existing inputLabel
  static const TextStyle inputLabel = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    color: AppColors.buttonText,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
}
