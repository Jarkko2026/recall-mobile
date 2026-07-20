// lib/presentation/providers/preferences_provider.dart
// 用户偏好：主题模式 / 字体缩放，持久化到 SharedPreferences
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }
  static const _key = 'pref_theme_mode';

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString(_key) ?? 'system';
    state = _fromName(v);
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, _toName(mode));
  }

  static ThemeMode _fromName(String v) =>
      v == 'light' ? ThemeMode.light : v == 'dark' ? ThemeMode.dark : ThemeMode.system;
  static String _toName(ThemeMode m) =>
      m == ThemeMode.light ? 'light' : m == ThemeMode.dark ? 'dark' : 'system';
}

final fontScaleProvider =
    StateNotifierProvider<FontScaleNotifier, double>((ref) => FontScaleNotifier());

class FontScaleNotifier extends StateNotifier<double> {
  FontScaleNotifier() : super(1.0) {
    _load();
  }
  static const _key = 'pref_font_scale';
  static const _small = 0.9;
  static const _normal = 1.0;
  static const _large = 1.15;

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    state = _fromName(sp.getString(_key) ?? 'normal');
  }

  Future<void> setByName(String name) async {
    state = _fromName(name);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, name);
  }

  static double _fromName(String v) =>
      v == 'small' ? _small : v == 'large' ? _large : _normal;
  static String nameOf(double s) =>
      s == _small ? 'small' : s == _large ? 'large' : 'normal';
}
