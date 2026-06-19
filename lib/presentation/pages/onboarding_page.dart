// lib/presentation/pages/onboarding_page.dart
// 首次启动引导
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../widgets/common.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _ctrl = PageController();
  int _page = 0;
  static const _pages = [
    _OnboardStep(
      icon: Icons.psychology_outlined,
      title: '你的私人第二大脑',
      subtitle: '自动整理 · 高质量回看 · 主题串联',
    ),
    _OnboardStep(
      icon: Icons.auto_awesome,
      title: '丢进去，自动成体系',
      subtitle: '基于智谱 GLM 大模型\n你丢什么，AI 就帮你理成什么',
    ),
    _OnboardStep(
      icon: Icons.shield_outlined,
      title: '你的 Key · 你的数据 · 你的云',
      subtitle: '隐私优先，云端加密\n全平台数据可一键导出',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                children: _pages.map((p) => _buildPage(p, theme)).toList(),
              ),
            ),
            // 进度点
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 20 : 6, height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary500 : theme.dividerColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s5),
              child: Column(
                children: [
                  AppButton(
                    label: _page == 2 ? '开始使用' : '下一步',
                    onPressed: () {
                      if (_page < 2) {
                        _ctrl.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                      } else {
                        context.go('/login');
                      }
                    },
                    fullWidth: true,
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  AppButton(
                    label: '已有账号，直接登录',
                    variant: AppButtonVariant.text,
                    onPressed: () => context.go('/login'),
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardStep step, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.primary500, AppColors.primary700],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(step.icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(step.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium),
          const SizedBox(height: AppSpacing.s3),
          Text(step.subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor, height: AppFonts.loose)),
        ],
      ),
    );
  }
}

class _OnboardStep {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardStep({required this.icon, required this.title, required this.subtitle});
}
