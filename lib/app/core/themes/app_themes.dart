// app/core/themes/app_themes.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart'; // Import text styles

class AppThemes {
  static final ThemeData mainTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.buttonPrimary,
      onPrimary: AppColors.textOnPrimary, // Text color ON primary color
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      background: AppColors.background,
      // Add other colors if needed
    ),
    textTheme: TextTheme(
      // Ensure labelLarge uses the correct style if you intend to use it for buttons
      labelLarge:
          AppTextStyles.primaryButtonText, // Set default button text style
      // ... (keep other text theme definitions)
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      displayLarge: TextStyle(color: AppColors.textPrimary),
      displayMedium: TextStyle(color: AppColors.textPrimary),
      displaySmall: TextStyle(color: AppColors.textPrimary),
      headlineMedium: TextStyle(color: AppColors.textPrimary),
      headlineSmall: TextStyle(color: AppColors.textPrimary),
      titleLarge: TextStyle(color: AppColors.textPrimary),
      titleMedium: TextStyle(color: AppColors.textPrimary),
      titleSmall: TextStyle(color: AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textPrimary),
      labelSmall: TextStyle(color: AppColors.textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonPrimary, // Solid purple background
        foregroundColor: AppColors.textOnPrimary, // Color for text and icons
        minimumSize: const Size(
            double.infinity, 50), // Make button wide and give it height
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 12), // Adjust padding as needed
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              10), // Slightly more rounded corners like the image
        ),
        elevation: 2, // Keep or adjust elevation
        shadowColor: Colors.black.withOpacity(0.2), // Keep or adjust shadow
        textStyle: AppTextStyles
            .primaryButtonText, // Apply the primary button text style
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.formField, // Re-check this color if needed
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), // Match button radius
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12, // Adjust vertical padding for text fields if needed
      ),
      labelStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.7)),
      hintStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.5)),
    ),
    textButtonTheme: TextButtonThemeData(
        // Style for Forgot Password?
        style: TextButton.styleFrom(
            foregroundColor: AppColors.buttonPrimary, // Purple text color
            textStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
    cardTheme: CardTheme(
      color:
          AppColors.formField, // Check if this background is intended for cards
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Match button radius
      ),
    ),
  );
}
