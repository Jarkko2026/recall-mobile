// lib/core/theme/design_tokens.dart
// Recall 设计系统 · 设计 Token（对齐 web 端 v3.7.2 编辑级风格）
// 暖纸 paper / 海军蓝 ink / 深蓝 brand / 琥珀 accent / 衬线 + 毛玻璃

import 'package:flutter/material.dart';

// ============== 颜色 ==============
class AppColors {
  AppColors._();

  // —— 主色板（brand = 深编辑蓝 #1f4ea8）——
  static const primary50 = Color(0xFFE8EEF9);
  static const primary100 = Color(0xFFC5D5F0);
  static const primary500 = Color(0xFF1F4EA8); // brand
  static const primary600 = Color(0xFF163D8A); // brand-2
  static const primary700 = Color(0xFF0F2D6B);

  // 琥珀强调色
  static const accent = Color(0xFFD97706);
  static const accentLight = Color(0xFFFEF3E2);

  // —— 中性色（Light：暖纸感）——
  static const lightBgPrimary = Color(0xFFFBFAF6); // paper
  static const lightBgSecondary = Color(0xFFF3EEE2); // paper-2 暖
  static const lightBgTertiary = Color(0xFFE8E2D4);
  static const lightTextPrimary = Color(0xFF1A1F2E); // ink 海军蓝
  static const lightTextSecondary = Color(0xFF475467); // ink-soft
  static const lightTextTertiary = Color(0xFF7A8499);
  static const lightBorder = Color(0xFFDCDFE7);

  // —— 中性色（Dark：深海军蓝）——
  static const darkBgPrimary = Color(0xFF0F1729); // paper dark
  static const darkBgSecondary = Color(0xFF182238); // paper-2 dark
  static const darkBgTertiary = Color(0xFF232F4A);
  static const darkTextPrimary = Color(0xFFF3F6FF);
  static const darkTextSecondary = Color(0xFFA8B1C9);
  static const darkTextTertiary = Color(0xFF6B7693);
  static const darkBorder = Color(0xFF2A3553);

  // —— 毛玻璃 ——
  static const glassBgLight = Color(0xB8FFFDF8); // rgba(255,253,248,.72)
  static const glassBorderLight = Color(0x241F4EA8); // rgba(31,78,168,.14)
  static const glassBgDark = Color(0x8C141C30); // rgba(20,28,48,.55)
  static const glassBorderDark = Color(0x14FFFFFF); // rgba(255,255,255,.08)

  // —— 渐变背景端点色 ——
  static const gradLight1 = Color(0xFFFFFDF8);
  static const gradLight2 = Color(0xFFF0EBDF);
  static const gradLight3 = Color(0xFFEEF4FF);
  static const gradDark1 = Color(0xFF0C1422);
  static const gradDark2 = Color(0xFF121A30);
  static const gradDark3 = Color(0xFF1A2440);

  // —— 语义色（对齐 web）——
  static const success = Color(0xFF10804F); // green
  static const warning = Color(0xFFD97706); // 复用琥珀
  static const danger = Color(0xFFB42318); // red
  static const info = Color(0xFF1F4EA8); // 链接色 = brand
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

// ============== 圆角（对齐 web：input 14 / 卡片 18-22）==============
class AppRadius {
  AppRadius._();

  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const xl = 18.0;
  static const xxl = 22.0;
  static const full = 9999.0;
}

// ============== 阴影（对齐 web 大柔影 0 24px 60px）==============
class AppShadows {
  AppShadows._();

  static const sm = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const md = [
    BoxShadow(color: Color(0x1A0F1E3C), offset: Offset(0, 6), blurRadius: 18),
  ];
  static const lg = [
    BoxShadow(color: Color(0x1A0F1E3C), offset: Offset(0, 24), blurRadius: 60),
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
