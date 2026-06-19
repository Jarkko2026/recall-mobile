// lib/core/router/app_router.dart
// 路由配置 - go_router
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/pages/home_shell.dart';
import '../../presentation/pages/timeline_page.dart';
import '../../presentation/pages/topics_page.dart';
import '../../presentation/pages/search_page.dart';
import '../../presentation/pages/settings_page.dart';
import '../../presentation/pages/onboarding_page.dart';
import '../../presentation/pages/add_page.dart';
import '../../presentation/pages/item_detail_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../services/auth_service.dart';
import '../../data/repositories/item_repository.dart';

/// router 用 Provider 暴露，依赖 auth 状态自动 rebuild
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.onDispose(notifier.dispose);

  // 监听 auth 变化，触发 router 刷新
  ref.listen<AsyncValue<AuthSession?>>(authControllerProvider, (_, __) {
    notifier.value++;
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (ctx, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.uri.toString();
      final isAuthRoute = loc == '/login' || loc == '/onboarding' || loc == '/splash';
      // 还在恢复登录态
      if (auth.isLoading && loc != '/splash') return '/splash';
      if (auth.hasValue) {
        final session = auth.value;
        if (session == null && !isAuthRoute) return '/login';
        if (session == null && loc == '/splash') return '/login';
        if (session != null && (loc == '/login' || loc == '/splash')) {
          // 登录成功后预拉一次数据
          Future.microtask(() => ref.read(itemsControllerProvider.notifier).refresh());
          return '/timeline';
        }
      }
      if (auth.hasError && !isAuthRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/timeline', builder: (_, __) => const TimelinePage()),
          GoRoute(path: '/topics', builder: (_, __) => const TopicsPage()),
          GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
      GoRoute(path: '/add', builder: (_, __) => const AddPage()),
      GoRoute(
        path: '/item/:id',
        builder: (_, state) => ItemDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/topic/:domainId/:topicId',
        builder: (_, state) => TopicDetailPage(
          domainId: state.pathParameters['domainId']!,
          topicId: state.pathParameters['topicId']!,
        ),
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
