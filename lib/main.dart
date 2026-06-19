// lib/main.dart
// Recall 移动端入口（iOS / Android）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RecallApp()));
}

class RecallApp extends ConsumerStatefulWidget {
  const RecallApp({Key? key}) : super(key: key);
  @override
  ConsumerState<RecallApp> createState() => _RecallAppState();
}

class _RecallAppState extends ConsumerState<RecallApp> {
  late final _router = buildRouter(ref);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Recall · 自动整理你的收藏',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
