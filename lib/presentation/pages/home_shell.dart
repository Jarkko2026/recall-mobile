// lib/presentation/pages/home_shell.dart
// 主页面 Shell - 底部 5 Tab（含中间 + 按钮）
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/common.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({Key? key, required this.child}) : super(key: key);

  int _indexFromLocation(String loc) {
    if (loc.startsWith('/topics')) return 1;
    if (loc.startsWith('/search')) return 2;
    if (loc.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final idx = _indexFromLocation(loc);
    return Scaffold(
      body: child,
      bottomNavigationBar: RecallBottomTabBar(
        currentIndex: idx,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/timeline'); break;
            case 1: context.go('/topics'); break;
            case 2: context.go('/search'); break;
            case 3: context.go('/settings'); break;
            case 4: context.push('/add'); break;
          }
        },
      ),
    );
  }
}
