import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFF97316);
  static const Color green = Color(0xFF22C55E);
  static const Color yellow = Color(0xFFFACC15);
  static const Color background = Color(0xFFFFF8F0);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color white = Color(0xFFFFFFFF);
  static const Color brown = Color(0xFF5A3A22);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);
  static const Color star = Color(0xFFFACC15);
  static const Color overlay = Color(0x80000000);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
