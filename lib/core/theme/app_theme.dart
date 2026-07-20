// lib/core/theme/app_theme.dart
// Recall 主题：对齐 web 端 v3.7.2 编辑级风格
// 暖纸背景 + 海军蓝/深蓝/琥珀 + Noto Serif SC 衬线标题 + 毛玻璃卡片

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    glassBg: AppColors.glassBgLight,
    glassBorder: AppColors.glassBorderLight,
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
    glassBg: AppColors.glassBgDark,
    glassBorder: AppColors.glassBorderDark,
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
    required Color glassBg,
    required Color glassBorder,
  }) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary500,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: bgSecondary,
      onSurface: text,
      background: bg,
      onBackground: text,
    );

    // 标题用衬线（对齐 web），正文留系统无衬线保可读性
    TextStyle serif({
      double fontSize = AppFonts.base,
      FontWeight fontWeight = FontWeight.w400,
      Color color = Colors.transparent,
      double height = AppFonts.normal,
    }) =>
        GoogleFonts.notoSerifSc(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: bg,
      cardColor: bgSecondary,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: glassBg,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: serif(
          fontSize: AppFonts.lg,
          fontWeight: FontWeight.w700,
          color: text,
          height: AppFonts.tight,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: serif(
            fontSize: AppFonts.xxl, fontWeight: FontWeight.w700, color: text, height: AppFonts.tight),
        displayMedium: serif(
            fontSize: AppFonts.xl, fontWeight: FontWeight.w700, color: text, height: AppFonts.tight),
        headlineSmall: serif(
            fontSize: AppFonts.lg, fontWeight: FontWeight.w600, color: text, height: AppFonts.tight),
        titleLarge: serif(
            fontSize: AppFonts.md, fontWeight: FontWeight.w600, color: text, height: AppFonts.tight),
        titleMedium: TextStyle(
            fontSize: AppFonts.base, fontWeight: FontWeight.w600, color: text, height: AppFonts.normal),
        bodyLarge: TextStyle(fontSize: AppFonts.base, color: text, height: AppFonts.normal),
        bodyMedium: TextStyle(fontSize: AppFonts.sm, color: textSecondary, height: AppFonts.normal),
        bodySmall: TextStyle(fontSize: AppFonts.xs, color: textTertiary, height: AppFonts.normal),
        labelLarge: TextStyle(
            fontSize: AppFonts.base, color: text, fontWeight: FontWeight.w600),
      ),
      iconTheme: IconThemeData(color: text, size: 22),
      cardTheme: CardThemeData(
        color: glassBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSecondary,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary500, width: 1.5),
        ),
        hintStyle: TextStyle(color: textTertiary, fontSize: AppFonts.base),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primary500.withOpacity(0.5);
            }
            return AppColors.primary500;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
              horizontal: AppSpacing.s5, vertical: AppSpacing.s3 + 2)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          )),
          textStyle: WidgetStateProperty.all(const TextStyle(
              fontSize: AppFonts.base, fontWeight: FontWeight.w600)),
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary500),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4, vertical: AppSpacing.s2)),
          textStyle: WidgetStateProperty.all(const TextStyle(
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? AppColors.lightTextPrimary : AppColors.darkBgTertiary,
        contentTextStyle: TextStyle(
            color: isLight ? Colors.white : AppColors.darkTextPrimary,
            fontSize: AppFonts.base),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }
}
