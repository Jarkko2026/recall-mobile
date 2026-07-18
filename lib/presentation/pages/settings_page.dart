// lib/presentation/pages/settings_page.dart
// 个人中心 + API Key 配置 + 标签管理 + 导出
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/auth_service.dart';
import '../widgets/common.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final username = auth.value?.username ?? '游客';
    final userId = auth.value?.userId ?? '-';
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // 用户卡片
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary50,
                    child: Text(
                      (username.isNotEmpty ? username[0] : 'R').toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primary500,
                          fontSize: AppFonts.xl,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username, style: theme.textTheme.titleLarge),
                        Text('UID: $userId',
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _Section(title: '智能', children: [
            _Item(
              icon: Icons.key, label: 'API Key 配置', trailing: '已配置 ✓',
              onTap: () => context.push('/key-setup')),
            _Item(
              icon: Icons.label_outline, label: '标签管理', trailing: '9 个',
              onTap: () {}),
            _Item(
              icon: Icons.folder_outlined, label: '分类管理', trailing: '4 个领域',
              onTap: () {}),
          ]),

          _Section(title: '数据', children: [
            _Item(
              icon: Icons.bar_chart_outlined, label: '本月用量', trailing: '¥3.20'),
            _Item(
              icon: Icons.upload_file_outlined, label: '数据导出',
              onTap: () {
                showRecallToast(context, '导出功能开发中');
              }),
            _Item(
              icon: Icons.delete_outline, label: '账户注销', destructive: true,
              onTap: () async {
                final ok = await showModalBottomSheet<bool>(
                  context: context, isScrollControlled: true,
                  builder: (_) => const ConfirmSheet(
                    title: '确定注销账户？',
                    message: '30 天后将硬删所有数据，期间可登录恢复。',
                    confirmLabel: '确定注销',
                    destructive: true,
                  ),
                );
                if (ok == true) {
                  showRecallToast(context, '已申请注销，30 天后生效');
                }
              }),
          ]),

          _Section(title: '偏好', children: [
            _Item(icon: Icons.dark_mode_outlined, label: '外观', trailing: '跟随系统 ▾'),
            _Item(icon: Icons.text_fields, label: '字体大小', trailing: '标准 ▾'),
          ]),

          _Section(title: '关于', children: [
            _Item(icon: Icons.help_outline, label: '帮助中心'),
            _Item(icon: Icons.star_border, label: '给我们评分'),
            _Item(icon: Icons.privacy_tip_outlined, label: '用户协议 / 隐私政策'),
            _Item(icon: Icons.info_outline, label: '版本 v1.0.0 (M1)'),
          ]),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: AppButton(
              label: '退出登录',
              variant: AppButtonVariant.danger,
              fullWidth: true,
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s2),
          child: Text(title, style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor, fontWeight: FontWeight.w600)),
        ),
        ...children,
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final bool destructive;
  const _Item({required this.icon, required this.label, this.trailing, this.onTap, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive ? AppColors.danger : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.s3),
            Expanded(child: Text(label, style: TextStyle(color: color, fontSize: AppFonts.base))),
            if (trailing != null) Text(trailing!, style: theme.textTheme.bodyMedium),
            if (onTap != null) Icon(Icons.chevron_right, size: 20, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

// ===== API Key 配置页 =====
class KeySetupPage extends ConsumerStatefulWidget {
  const KeySetupPage({Key? key}) : super(key: key);
  @override
  ConsumerState<KeySetupPage> createState() => _KeySetupPageState();
}

class _KeySetupPageState extends ConsumerState<KeySetupPage> {
  final _ctrl = TextEditingController();
  String _status = 'idle'; // idle / loading / success / error
  String _error = '';

  // Phase 1.6 — 补 dispose
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_ctrl.text.trim().length < 10) {
      setState(() {
        _status = 'error';
        _error = 'Key 格式不正确，应为 xxxx.xxxx.xxxx 格式';
      });
      return;
    }
    setState(() => _status = 'loading');
    // 真实环境调用云函数 ping
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _status = 'success');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('API Key 配置')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          // 步骤说明
          _step(1, '注册智谱开放平台', 'bigmodel.cn → 注册账号 → 实名认证'),
          _step(2, '创建 API Key', '控制台 → API Keys → 创建新 Key'),
          _step(3, '充值', '钱包 → 充值 ¥10 起（可用 1-2 月）'),
          _step(4, '粘贴到下方', '保存后立即用真实 Key 整理你的收藏'),

          const SizedBox(height: AppSpacing.s5),

          AppInput(
            controller: _ctrl,
            label: '智谱 API Key',
            hint: '粘贴 xxxx.xxxx.xxxx',
            obscure: true,
            errorText: _status == 'error' ? _error : null,
          ),

          const SizedBox(height: AppSpacing.s4),

          AppButton(
            label: _status == 'loading' ? '校验中...' : '校验并保存',
            loading: _status == 'loading',
            onPressed: _status == 'loading' ? null : _verify,
            fullWidth: true,
          ),

          if (_status == 'success') ...[
            const SizedBox(height: AppSpacing.s3),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s3),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text('已校验成功！本 App 已就绪', style: TextStyle(color: AppColors.success)),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.s5),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '你的 Key 仅保存在本地 Keychain，不会上传到云端。\n'
                    '开启"快速打标"模式时，会直接从本地调用智谱 API。',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(int n, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary500,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('$n',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: AppFonts.base)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: AppFonts.sm, color: Theme.of(context).hintColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
