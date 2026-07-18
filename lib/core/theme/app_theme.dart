// lib/core/theme/app_theme.dart
// Recall 主题：light + dark 两套 Material 3 主题

import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light = _build(
    brightness: Brightness.light,
    bg: AppColors.lightBgPrimary,
    bgSecondary: AppColors.lightBgSecondary,
    bgTertiary: AppColors.lightBgTertiary,
    text: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textTertiary: AppColors.lightTextTertiary,
    border: AppColors.lightBorder,
  );

  static ThemeData dark = _build(
    brightness: Brightness.dark,
    bg: AppColors.darkBgPrimary,
    bgSecondary: AppColors.darkBgSecondary,
    bgTertiary: AppColors.darkBgTertiary,
    text: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: AppColors.darkTextTertiary,
    border: AppColors.darkBorder,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color bgSecondary,
    required Color bgTertiary,
    required Color text,
    required Color textSecondary,
    required Color textTertiary,
    required Color border,
  }) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary500,
      onPrimary: Colors.white,
      secondary: AppColors.primary100,
      onSecondary: AppColors.primary700,
      error: AppColors.danger,
      onError: Colors.white,
      surface: bg,
      onSurface: text,
      background: bg,
      onBackground: text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: bgSecondary,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: AppFonts.lg,
          fontWeight: FontWeight.w600,
          height: AppFonts.tight,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
            fontSize: AppFonts.xxl,
            fontWeight: FontWeight.w700,
            color: text,
            height: AppFonts.tight),
        displayMedium: TextStyle(
            fontSize: AppFonts.xl,
            fontWeight: FontWeight.w700,
            color: text,
            height: AppFonts.tight),
        headlineSmall: TextStyle(
            fontSize: AppFonts.lg,
            fontWeight: FontWeight.w600,
            color: text,
            height: AppFonts.tight),
        titleLarge: TextStyle(
            fontSize: AppFonts.md,
            fontWeight: FontWeight.w600,
            color: text,
            height: AppFonts.tight),
        titleMedium: TextStyle(
            fontSize: AppFonts.base,
            fontWeight: FontWeight.w500,
            color: text,
            height: AppFonts.normal),
        bodyLarge: TextStyle(
            fontSize: AppFonts.base, color: text, height: AppFonts.normal),
        bodyMedium: TextStyle(
            fontSize: AppFonts.sm, color: textSecondary, height: AppFonts.normal),
        bodySmall: TextStyle(
            fontSize: AppFonts.xs, color: textTertiary, height: AppFonts.normal),
        labelLarge: TextStyle(
            fontSize: AppFonts.base,
            color: text,
            fontWeight: FontWeight.w500),
      ),
      iconTheme: IconThemeData(color: text, size: 22),
      cardTheme: CardThemeData(
        color: bgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSecondary,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary500, width: 1.5),
        ),
        hintStyle: TextStyle(color: textTertiary, fontSize: AppFonts.base),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled)) {
              return AppColors.primary500.withOpacity(0.5);
            }
            return AppColors.primary500;
          }),
          foregroundColor: MaterialStateProperty.all(Colors.white),
          elevation: MaterialStateProperty.all(0),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(
              horizontal: AppSpacing.s5, vertical: AppSpacing.s3 + 2)),
          shape: MaterialStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          )),
          textStyle: MaterialStateProperty.all(const TextStyle(
              fontSize: AppFonts.base, fontWeight: FontWeight.w600)),
          minimumSize: MaterialStateProperty.all(const Size(0, 48)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(AppColors.primary500),
          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4, vertical: AppSpacing.s2)),
          textStyle: MaterialStateProperty.all(const TextStyle(
              fontSize: AppFonts.base, fontWeight: FontWeight.w500)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgSecondary,
        selectedColor: AppColors.primary50,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: text, fontSize: AppFonts.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s2, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? AppColors.lightTextPrimary : AppColors.darkBgTertiary,
        contentTextStyle: TextStyle(
            color: isLight ? Colors.white : AppColors.darkTextPrimary,
            fontSize: AppFonts.base),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
