// lib/core/theme/design_tokens.dart
// Recall 设计系统 · 设计 Token（颜色/字体/间距/圆角/阴影/动效）
// 详见方案文档 §3.1

import 'package:flutter/material.dart';

// ============== 颜色 ==============
class AppColors {
  AppColors._();

  // 主色板
  static const primary50 = Color(0xFFE8F1FF);
  static const primary100 = Color(0xFFC8DEFF);
  static const primary500 = Color(0xFF3B7FF6);
  static const primary600 = Color(0xFF2E66CC);
  static const primary700 = Color(0xFF244D99);

  // 中性色（Light）
  static const lightBgPrimary = Color(0xFFFFFFFF);
  static const lightBgSecondary = Color(0xFFF7F8FA);
  static const lightBgTertiary = Color(0xFFEFEFF2);
  static const lightTextPrimary = Color(0xFF1A1B1F);
  static const lightTextSecondary = Color(0xFF6B6E76);
  static const lightTextTertiary = Color(0xFF9CA0A8);
  static const lightBorder = Color(0xFFE5E6EB);

  // 中性色（Dark）
  static const darkBgPrimary = Color(0xFF0E0E10);
  static const darkBgSecondary = Color(0xFF1A1B1F);
  static const darkBgTertiary = Color(0xFF26272C);
  static const darkTextPrimary = Color(0xFFF2F2F5);
  static const darkTextSecondary = Color(0xFFA8ABB3);
  static const darkTextTertiary = Color(0xFF6B6E76);
  static const darkBorder = Color(0xFF2E3036);

  // 语义色
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9F0A);
  static const danger = Color(0xFFFF3B30);
  static const info = Color(0xFF5A95FF);
}

// ============== 字体 ==============
class AppFonts {
  AppFonts._();

  static const xs = 11.0;
  static const sm = 13.0;
  static const base = 15.0;
  static const md = 17.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const xxl = 34.0;

  static const tight = 1.2;
  static const normal = 1.4;
  static const loose = 1.6;
}

// ============== 间距（4pt 网格）==============
class AppSpacing {
  AppSpacing._();

  static const s0 = 0.0;
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
  static const s10 = 40.0;
}

// ============== 圆角 ==============
class AppRadius {
  AppRadius._();

  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;
  static const full = 9999.0;
}

// ============== 阴影 ==============
class AppShadows {
  AppShadows._();

  static const sm = [
    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const md = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 2), blurRadius: 8),
  ];
  static const lg = [
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, 8), blurRadius: 24),
  ];
}

// ============== 动效 ==============
class AppMotion {
  AppMotion._();

  static const easeStandard = Cubic(0.4, 0, 0.2, 1);
  static const easeDecelerate = Cubic(0, 0, 0.2, 1);
  static const easeAccelerate = Cubic(0.4, 0, 1, 1);
  static const easeSpring = Cubic(0.34, 1.56, 0.64, 1);

  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}
