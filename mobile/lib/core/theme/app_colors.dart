import 'package:flutter/material.dart';
import 'package:meo_traker/data/services/theme_settings_service.dart';

class AppColors {
  static bool get _dark => ThemeSettingsService.instance.isDark;

  static const Color primary = Color(0xFFFFD60A);
  static const Color onPrimary = Color(0xFF1A1A1A);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color protein = Color(0xFFE53935);
  static const Color carb = Color(0xFFFFB300);
  static const Color fat = Color(0xFF1E88E5);

  static Color get background =>
      _dark ? const Color(0xFF14130F) : const Color(0xFFFFFDF5);
  static Color get surface =>
      _dark ? const Color(0xFF1E1C16) : const Color(0xFFFFFFFF);
  static Color get textPrimary =>
      _dark ? const Color(0xFFF5F2E8) : const Color(0xFF1A1A1A);
  static Color get textSecondary =>
      _dark ? const Color(0xFFA8A490) : const Color(0xFF6B6B6B);
  static Color get border =>
      _dark ? const Color(0xFF3A372C) : const Color(0xFFE8E4D4);
}
