import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFF03A9B5);
  static const Color primaryDark = Color(0xFF002455);
  static const Color primaryLight = Color(0xFFE0F5F7);
  static const Color primarySurface = Color(0xFFF0FAFB);

  // Brand navy (logo circle / "HIRAAL" wordmark)
  static const Color navy = Color(0xFF002455);

  // Accent
  static const Color accent = Color(0xFF03A9B5);

  // Status
  static const Color success = Color(0xFF34C759);
  static const Color successLight = Color(0xFFE8F9EE);
  static const Color warning = Color(0xFFFF9500);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFFF3B30);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF007AFF);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Risk levels
  static const Color veryHigh = Color(0xFFFF3B30);
  static const Color high = Color(0xFFFF9500);
  static const Color medium = Color(0xFFFFCC00);
  static const Color low = Color(0xFF34C759);

  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE5E9F0);
  static const Color divider = Color(0xFFEEF0F3);
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color iconGrey = Color(0xFF9CA3AF);
  static const Color inputBackground = Color(0xFFF9FAFB);
  static const Color inputBorder = Color(0xFFD1D5DB);

  // Charts
  static const Color chartBlue = Color(0xFF03A9B5);
  static const Color chartGreen = Color(0xFF34C759);
  static const Color chartOrange = Color(0xFFFF9500);
  static const Color chartRed = Color(0xFFFF3B30);
  static const Color chartPurple = Color(0xFF8B5CF6);

  // Badge colors
  static const Color badgeSent = Color(0xFF34C759);
  static const Color badgePending = Color(0xFFFF9500);
  static const Color badgeActive = Color(0xFF34C759);
  static const Color badgeExpired = Color(0xFF9CA3AF);

  // Dark theme tokens (WCAG AA on #121418 / #1C1F26)
  static const Color darkBackground = Color(0xFF121418);
  static const Color darkSurface = Color(0xFF1C1F26);
  static const Color darkCardBorder = Color(0xFF2E3440);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  static const Color darkTextTertiary = Color(0xFF9CA3AF);
  static const Color darkInputBackground = Color(0xFF252A33);
  static const Color darkInputBorder = Color(0xFF3F4654);
  static const Color darkPrimaryLight = Color(0xFF0E3A40);
  static const Color darkPrimarySurface = Color(0xFF12363C);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffold(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color card(BuildContext context) =>
      isDark(context) ? darkSurface : white;

  static Color border(BuildContext context) =>
      isDark(context) ? darkCardBorder : cardBorder;

  static Color text(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;
}
