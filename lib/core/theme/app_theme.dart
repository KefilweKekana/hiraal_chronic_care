import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static const Color _darkPrimary = AppColors.primaryOnDark;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.white,
      dividerColor: AppColors.divider,
      applyElevationOverlayColor: false,
      extensions: const [AppPalette.light],
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        surfaceTint: Colors.transparent,
        secondary: AppColors.accent,
        onSecondary: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        error: AppColors.error,
        onError: AppColors.white,
        outline: AppColors.cardBorder,
        outlineVariant: AppColors.divider,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primaryDark,
        errorContainer: AppColors.errorLight,
        onErrorContainer: Color(0xFFC62828),
        surfaceContainerLowest: AppColors.background,
        surfaceContainerLow: AppColors.white,
        surfaceContainer: AppColors.white,
        surfaceContainerHigh: AppColors.white,
        surfaceContainerHighest: AppColors.inputBackground,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.1),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, height: 1.1),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.inter(color: AppColors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        textStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.white),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.white,
        hourMinuteTextColor: AppColors.textPrimary,
        dialBackgroundColor: AppColors.primaryLight,
        dayPeriodTextColor: AppColors.primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryLight,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
        secondaryLabelStyle: GoogleFonts.inter(color: AppColors.white, fontSize: 13),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return AppColors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.cardBorder;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        textColor: AppColors.textPrimary,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    const scheme = ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: AppColors.white,
      surfaceTint: Colors.transparent,
      secondary: _darkPrimary,
      onSecondary: AppColors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      error: AppColors.error,
      onError: AppColors.white,
      outline: AppColors.darkCardBorder,
      outlineVariant: AppColors.darkDivider,
      primaryContainer: AppColors.darkPrimaryLight,
      onPrimaryContainer: Color(0xFF99F6E4),
      secondaryContainer: AppColors.darkPrimarySurface,
      onSecondaryContainer: Color(0xFF99F6E4),
      errorContainer: AppColors.darkErrorSoft,
      onErrorContainer: Color(0xFFFFDAD6),
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: Color(0xFF0F172A),
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: Color(0xFF162033),
      surfaceContainerHighest: AppColors.darkInputBackground,
      inverseSurface: Color(0xFFE2E8F0),
      onInverseSurface: AppColors.darkBackground,
      inversePrimary: _darkPrimary,
      tertiary: Color(0xFF38BDF8),
      onTertiary: AppColors.darkBackground,
      scrim: Color(0xCC000000),
      shadow: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: _darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkDivider,
      applyElevationOverlayColor: false,
      extensions: const [AppPalette.dark],
      colorScheme: scheme,
      textTheme: base.copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextTertiary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: _darkPrimary.withValues(alpha: 0.45),
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.8),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: _darkPrimary, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkInputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkInputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.darkTextTertiary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkCardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: _darkPrimary,
        unselectedItemColor: AppColors.darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.1),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, height: 1.1),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.darkTextSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.darkSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.inter(color: AppColors.darkTextPrimary, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        textStyle: GoogleFonts.inter(color: AppColors.darkTextPrimary, fontSize: 14),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.darkSurface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.darkSurface,
        hourMinuteTextColor: AppColors.darkTextPrimary,
        dialBackgroundColor: AppColors.darkPrimaryLight,
        dayPeriodTextColor: _darkPrimary,
        entryModeIconColor: AppColors.darkTextPrimary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkPrimaryLight,
        selectedColor: _darkPrimary,
        labelStyle: GoogleFonts.inter(color: AppColors.darkTextPrimary, fontSize: 13),
        secondaryLabelStyle: GoogleFonts.inter(color: AppColors.white, fontSize: 13),
        side: const BorderSide(color: AppColors.darkCardBorder),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return AppColors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _darkPrimary;
          return AppColors.darkInputBorder;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _darkPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      listTileTheme: const ListTileThemeData(
        iconColor: _darkPrimary,
        textColor: AppColors.darkTextPrimary,
        subtitleTextStyle: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: _darkPrimary,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.darkTextSecondary,
      ),
    );
  }
}
