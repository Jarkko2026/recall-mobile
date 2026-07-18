// lib/presentation/pages/login_page.dart
// 登录 / 注册（自助账号）—— 与 web 端 v3.7.2 完全一致的契约：user-api/auth/login & /auth/register
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../widgets/common.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _busy = false;
  String? _msg;
  bool _msgError = true;

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  bool _validate() {
    final u = _u.text.trim();
    final p = _p.text;
    final reg = RegExp(r'^[a-zA-Z0-9._\-:+@]{3,32}$');
    if (!reg.hasMatch(u)) {
      _setMsg('用户名 3-32 位，仅支持字母数字与 . _ - : + @', true);
      return false;
    }
    if (p.length < 6) {
      _setMsg('密码至少 6 位', true);
      return false;
    }
    return true;
  }

  void _setMsg(String s, bool err) {
    setState(() {
      _msg = s;
      _msgError = err;
    });
  }

  Future<void> _login() async {
    if (!_validate()) return;
    setState(() => _busy = true);
    _setMsg('登录中…', false);
    try {
      await ref.read(authControllerProvider.notifier).login(_u.text.trim(), _p.text);
      if (!mounted) return;
      _setMsg('已登录', false);
      context.go('/timeline');
    } catch (e) {
      _setMsg('登录失败：$e', true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    if (!_validate()) return;
    setState(() => _busy = true);
    _setMsg('注册中…', false);
    try {
      await ref.read(authControllerProvider.notifier).register(_u.text.trim(), _p.text);
      if (!mounted) return;
      _setMsg('注册成功，已自动登录', false);
      context.go('/timeline');
    } catch (e) {
      _setMsg('注册失败：$e', true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s6, vertical: AppSpacing.s8),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.s6),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary500, AppColors.primary700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppShadows.md,
                ),
                child:
                    const Icon(Icons.psychology_outlined, size: 48, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text('Recall', style: theme.textTheme.displayMedium),
              const SizedBox(height: AppSpacing.s1),
              Text('自动整理 · 高质量回看 · 主题串联',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor)),
              const SizedBox(height: AppSpacing.s8),
              AppInput(
                controller: _u,
                label: '用户名',
                hint: '3-32 位字母数字与 . _ - : + @',
              ),
              const SizedBox(height: AppSpacing.s3),
              AppInput(
                controller: _p,
                label: '密码',
                hint: '至少 6 位',
                obscure: true,
              ),
              const SizedBox(height: AppSpacing.s4),
              if (_msg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                  child: Text(
                    _msg!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: _msgError ? AppColors.danger : AppColors.success),
                  ),
                ),
              AppButton(
                label: _busy ? '处理中…' : '登录',
                onPressed: _busy ? null : _login,
                fullWidth: true,
              ),
              const SizedBox(height: AppSpacing.s2),
              AppButton(
                label: '注册新账号',
                variant: AppButtonVariant.secondary,
                onPressed: _busy ? null : _register,
                fullWidth: true,
              ),
              const Spacer(),
              Text('数据存于云端 · 与 web 端共享同一个账号',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor)),
            ],
          ),
        ),
      ),
    );
  }
}
