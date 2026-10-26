import 'package:flutter/material.dart';

/// Brand palette sampled from the web app's login/register/forgot-password
/// screenshots in `porting documentation/flutter/screenshots/`.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFA07E58);
  static const Color primaryDark = Color(0xFF8B6F47);
  static const Color primaryLight = Color(0xFFF5EFE8);

  static const Color textPrimary = Color(0xFF132026);
  static const Color textSecondary = Color(0xFF6C727F);
  static const Color placeholder = Color(0xFF9CA3AF);

  static const Color background = Color(0xFFF8F8F9);
  static const Color surface = Colors.white;
  static const Color inputBackground = Color(0xFFF9FAFB);
  static const Color inputBorder = Color(0xFFE5E7EB);

  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color disabled = Color(0xFFD1C1AE);
}
