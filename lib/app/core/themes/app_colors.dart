import 'package:flutter/material.dart';

class AppColors {
  // Cor de fundo dos botões/cards
  static const Color profileSecondaryText =
      Color(0xFF8E8E93); // Cor cinza para texto secundário (ex: data)
  static const Color subscriptionIconBackground =
      Color(0xFF5856D6); // Roxo para fundo do ícone
  static const Color tagBackground = Color(0xFF3A3A3C);
  static const Color buttonText2 = Color(0xFFFFFFFF);
  static const Color profileOptionBackground = Color(0xFF2C2C2E);
  static const Color profileOptionText = Colors.white;
  static const Color background = Color(0xFF131418);
  static const Color textPrimary = Color(0xFFD9D9D9);
  static const Color buttonPrimary = Color(0xFFBC4CF1);
  static const Color buttonText = Color(0xFFAA73F0);
  static const Color buttonBackground = Color(0x33BC4CF1);
  static const Color appleButton = Color(0xFF333333);
  static const Color formField = Color(0x44455233);
  static const Color grey = Color.fromARGB(68, 205, 208, 202);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  static BoxShadow buttonShadow = BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 8,
    offset: const Offset(0, 4),
  );

  static var primary;
}
