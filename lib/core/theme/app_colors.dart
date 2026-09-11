import 'package:flutter/material.dart';

/// Brand and semantic colors. Light values are the shipping palette.
/// Dark surfaces are Hiraal navy (`#0B1220` / `#111827`), not inverted grey.
class AppColors {
  // Primary (light screens keep this cyan-teal)
  static const Color primary = Color(0xFF03A9B5);
  static const Color primaryDark = Color(0xFF002455);
  static const Color primaryLight = Color(0xFFE0F5F7);
  static const Color primarySurface = Color(0xFFF0FAFB);

  /// Dark-mode button / chip teal – same family, tuned for navy surfaces.
  static const Color primaryOnDark = Color(0xFF0D9494);

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

  // Neutral (light)
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

  // Dark theme tokens (navy, not grey-purple)
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCardBorder = Color(0xFF2A3A52);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF94A3B8);
  static const Color darkInputBackground = Color(0xFF1A2436);
  static const Color darkInputBorder = Color(0xFF334155);
  static const Color darkPrimaryLight = Color(0xFF0E3A40);
  static const Color darkPrimarySurface = Color(0xFF12363C);
  static const Color darkSuccessSoft = Color(0xFF0F2E1C);
  static const Color darkWarningSoft = Color(0xFF3D2A12);
  static const Color darkErrorSoft = Color(0xFF3B1518);
  static const Color darkInfoSoft = Color(0xFF0C2A4A);
  static const Color darkDivider = Color(0xFF1E2A3D);
  static const Color darkShimmerBase = Color(0xFF162033);
  static const Color darkShimmerHighlight = Color(0xFF1E2D45);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ??
        (isDark(context) ? AppPalette.dark : AppPalette.light);
  }

  static Color scaffold(BuildContext context) => of(context).scaffold;

  static Color card(BuildContext context) => of(context).card;

  static Color border(BuildContext context) => of(context).border;

  static Color text(BuildContext context) => of(context).text;

  static Color textMuted(BuildContext context) => of(context).textMuted;

  static Color textFaint(BuildContext context) => of(context).textFaint;

  static Color brandMark(BuildContext context) => of(context).brandMark;

  static Color accentColor(BuildContext context) => of(context).accent;
}

/// Theme-resolved surfaces so screens do not hardcode light tokens.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.scaffold,
    required this.card,
    required this.navBar,
    required this.border,
    required this.divider,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.inputFill,
    required this.inputBorder,
    required this.accent,
    required this.primarySoft,
    required this.primaryMuted,
    required this.successSoft,
    required this.warningSoft,
    required this.errorSoft,
    required this.infoSoft,
    required this.errorFg,
    required this.brandMark,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final Color scaffold;
  final Color card;
  final Color navBar;
  final Color border;
  final Color divider;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color inputFill;
  final Color inputBorder;
  final Color accent;
  final Color primarySoft;
  final Color primaryMuted;
  final Color successSoft;
  final Color warningSoft;
  final Color errorSoft;
  final Color infoSoft;
  final Color errorFg;
  final Color brandMark;
  final Color shimmerBase;
  final Color shimmerHighlight;

  static const light = AppPalette(
    scaffold: AppColors.background,
    card: AppColors.white,
    navBar: AppColors.white,
    border: AppColors.cardBorder,
    divider: AppColors.divider,
    text: AppColors.textPrimary,
    textMuted: AppColors.textSecondary,
    textFaint: AppColors.textTertiary,
    inputFill: AppColors.inputBackground,
    inputBorder: AppColors.inputBorder,
    accent: AppColors.primary,
    primarySoft: AppColors.primaryLight,
    primaryMuted: AppColors.primarySurface,
    successSoft: AppColors.successLight,
    warningSoft: AppColors.warningLight,
    errorSoft: AppColors.errorLight,
    infoSoft: AppColors.infoLight,
    errorFg: Color(0xFFC62828),
    brandMark: AppColors.navy,
    shimmerBase: AppColors.inputBackground,
    shimmerHighlight: AppColors.white,
  );

  static const dark = AppPalette(
    scaffold: AppColors.darkBackground,
    card: AppColors.darkSurface,
    navBar: AppColors.darkSurface,
    border: AppColors.darkCardBorder,
    divider: AppColors.darkDivider,
    text: AppColors.darkTextPrimary,
    textMuted: AppColors.darkTextSecondary,
    textFaint: AppColors.darkTextTertiary,
    inputFill: AppColors.darkInputBackground,
    inputBorder: AppColors.darkInputBorder,
    accent: AppColors.primaryOnDark,
    primarySoft: AppColors.darkPrimaryLight,
    primaryMuted: AppColors.darkPrimarySurface,
    successSoft: AppColors.darkSuccessSoft,
    warningSoft: AppColors.darkWarningSoft,
    errorSoft: AppColors.darkErrorSoft,
    infoSoft: AppColors.darkInfoSoft,
    errorFg: Color(0xFFFFDAD6),
    brandMark: AppColors.darkTextPrimary,
    shimmerBase: AppColors.darkShimmerBase,
    shimmerHighlight: AppColors.darkShimmerHighlight,
  );

  @override
  AppPalette copyWith({
    Color? scaffold,
    Color? card,
    Color? navBar,
    Color? border,
    Color? divider,
    Color? text,
    Color? textMuted,
    Color? textFaint,
    Color? inputFill,
    Color? inputBorder,
    Color? accent,
    Color? primarySoft,
    Color? primaryMuted,
    Color? successSoft,
    Color? warningSoft,
    Color? errorSoft,
    Color? infoSoft,
    Color? errorFg,
    Color? brandMark,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    return AppPalette(
      scaffold: scaffold ?? this.scaffold,
      card: card ?? this.card,
      navBar: navBar ?? this.navBar,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      inputFill: inputFill ?? this.inputFill,
      inputBorder: inputBorder ?? this.inputBorder,
      accent: accent ?? this.accent,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryMuted: primaryMuted ?? this.primaryMuted,
      successSoft: successSoft ?? this.successSoft,
      warningSoft: warningSoft ?? this.warningSoft,
      errorSoft: errorSoft ?? this.errorSoft,
      infoSoft: infoSoft ?? this.infoSoft,
      errorFg: errorFg ?? this.errorFg,
      brandMark: brandMark ?? this.brandMark,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      card: Color.lerp(card, other.card, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryMuted: Color.lerp(primaryMuted, other.primaryMuted, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      errorFg: Color.lerp(errorFg, other.errorFg, t)!,
      brandMark: Color.lerp(brandMark, other.brandMark, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
    );
  }
}
