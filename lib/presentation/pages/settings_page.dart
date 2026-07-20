// lib/presentation/pages/settings_page.dart
// 个人中心 + API Key 配置 + 偏好（主题/字体真生效）+ 数据
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/models.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../data/repositories/item_repository.dart';
import '../providers/preferences_provider.dart';
import '../widgets/common.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final username = auth.value?.username ?? '游客';
    final userId = auth.value?.userId ?? '-';
    final tags = ref.watch(allTagsProvider);
    final categories = ref.watch(allCategoriesProvider);
    final domains = categories.where((c) => c.level == 1).length;
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final themeLabel = themeMode == ThemeMode.light
        ? '浅色'
        : themeMode == ThemeMode.dark
            ? '深色'
            : '跟随系统';
    final fontLabel = fontScale == 0.9 ? '小' : fontScale == 1.15 ? '大' : '标准';

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
                icon: Icons.key, label: 'API Key 配置', trailing: '管理',
                onTap: () => context.push('/key-setup')),
            _Item(
                icon: Icons.label_outline, label: '标签管理', trailing: '${tags.length} 个',
                onTap: () => _showTagsSheet(context, tags)),
            _Item(
                icon: Icons.folder_outlined, label: '分类管理', trailing: '$domains 个领域',
                onTap: () => context.push('/topics')),
          ]),

          _Section(title: '数据', children: [
            _Item(
                icon: Icons.bar_chart_outlined, label: '知识库统计', trailing: '查看',
                onTap: () => _showStats(context, ref)),
            _Item(
                icon: Icons.upload_file_outlined, label: '数据导出',
                onTap: () => _exportGraph(context, ref)),
            _Item(
                icon: Icons.delete_outline, label: '账户注销', destructive: true,
                onTap: () async {
                  final ok = await showModalBottomSheet<bool>(
                    context: context, isScrollControlled: true,
                    builder: (_) => const ConfirmSheet(
                      title: '确定注销账户？',
                      message: '将清除本地登录态并退出。云端数据保留，可重新登录恢复。',
                      confirmLabel: '确定注销',
                      destructive: true,
                    ),
                  );
                  if (ok == true) {
                    try {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        showRecallToast(context, '已注销，可重新登录恢复');
                        context.go('/login');
                      }
                    } catch (e) {
                      if (context.mounted) showRecallToast(context, '注销失败：$e', isError: true);
                    }
                  }
                }),
          ]),

          _Section(title: '偏好', children: [
            _Item(
              icon: Icons.dark_mode_outlined, label: '外观', trailing: '$themeLabel ▾',
              onTap: () => _showThemePicker(context, ref),
            ),
            _Item(
              icon: Icons.text_fields, label: '字体大小', trailing: '$fontLabel ▾',
              onTap: () => _showFontSizePicker(context, ref),
            ),
          ]),

          _Section(title: '关于', children: [
            _Item(
                icon: Icons.help_outline, label: '帮助中心',
                onTap: () => _showInfoSheet(context, '帮助中心', _helpText)),
            _Item(
                icon: Icons.star_border, label: '给我们评分',
                onTap: () => _showInfoSheet(context, '感谢支持', _thanksText)),
            _Item(
                icon: Icons.privacy_tip_outlined, label: '用户协议 / 隐私政策',
                onTap: () => _showInfoSheet(context, '隐私政策', _privacyText)),
            _Item(
                icon: Icons.info_outline, label: '版本 v1.0.7 · UI 重构',
                onTap: () => showRecallToast(context, 'Recall v1.0.7 · 编辑级 UI + 字段修复')),
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

  // ===== 真实行为：标签列表 =====
  void _showTagsSheet(BuildContext context, List<Tag> tags) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('我的标签（${tags.length}）',
                  style: Theme.of(_).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s3),
              if (tags.isEmpty)
                const Text('暂无标签，整理收藏后会自动生成。')
              else
                Wrap(
                  spacing: AppSpacing.s2, runSpacing: AppSpacing.s2,
                  children: tags
                      .map((t) => TagChip(label: t.name))
                      .toList(),
                ),
              const SizedBox(height: AppSpacing.s4),
            ],
          ),
        ),
      ),
    );
  }

  // ===== 真实行为：知识库统计（items-api /items/stats）=====
  Future<void> _showStats(BuildContext context, WidgetRef ref) async {
    showRecallToast(context, '统计中...');
    try {
      final data = await ref.read(apiClientProvider).call('items-api', method: 'GET', path: '/items/stats');
      final total = data['total'] ?? 0;
      final organized = data['organized'] ?? 0;
      final pending = (total as int) - (organized as int);
      if (context.mounted) {
        _showInfoSheet(context, '知识库统计',
            '总收藏：$total 条\n已整理：$organized 条\n待整理：$pending 条');
      }
    } catch (e) {
      if (context.mounted) showRecallToast(context, '查询失败：$e', isError: true);
    }
  }

  // ===== 真实行为：导出知识谱系摘要到剪贴板 =====
  Future<void> _exportGraph(BuildContext context, WidgetRef ref) async {
    try {
      final data = await ref.read(apiClientProvider).call('items-api', method: 'GET', path: '/items/graph');
      final buf = StringBuffer()
        ..writeln('Recall 知识谱系导出')
        ..writeln('总收藏：${data['total_items']}  领域：${data['domain_count']}  主题：${data['topic_count']}  标签：${data['tag_count']}')
        ..writeln();
      for (final d in (data['domains'] as List?) ?? []) {
        final m = d as Map;
        buf.writeln('· ${m['id']}（${m['count']} 条）');
      }
      await Clipboard.setData(ClipboardData(text: buf.toString()));
      if (context.mounted) showRecallToast(context, '已导出知识谱系摘要到剪贴板');
    } catch (e) {
      if (context.mounted) showRecallToast(context, '导出失败：$e', isError: true);
    }
  }

  void _showInfoSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(_).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s3),
              Text(body, style: Theme.of(_).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.s4),
            ],
          ),
        ),
      ),
    );
  }
}

const _helpText = 'Recall 使用指南\n\n'
    '1. 收藏：点底部 + 粘贴链接或文本，AI 自动抓取并整理\n'
    '2. 整理：系统提取标签、归入领域/主题、生成四段中文摘要\n'
    '3. 回看：时间线浏览，详情页看摘要与原文\n'
    '4. 检索：搜索页按关键词/标签找回顾\n'
    '5. Copilot：基于你的知识库问答\n\n'
    '配置 API Key 后即可开启 AI 整理（设置 → API Key 配置）。';

const _thanksText = '感谢你使用 Recall！\n\n'
    '这是一个个人 AI 知识库项目，你的反馈是它变好的动力。\n'
    '如有建议，欢迎反馈给开发者。';

const _privacyText = 'Recall 隐私政策\n\n'
    '1. 你的所有收藏内容仅对你本人可见，按账号严格隔离\n'
    '2. API Key 加密存储在云端，仅用于调用智谱 AI 整理你的内容\n'
    '3. 本应用不收集任何与功能无关的个人信息\n'
    '4. 账户注销后本地登录态清除，云端数据保留可恢复\n'
    '5. 继续使用即表示你认可上述说明';

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

  // Phase 1.6 - 补 dispose
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final key = _ctrl.text.trim();
    if (key.length < 10) {
      setState(() { _status = 'error'; _error = 'Key 格式不正确，应为 xxxx.xxxx.xxxx 格式'; });
      return;
    }
    setState(() => _status = 'loading');
    try {
      // 直接调 user-api /api-keys 保存 Key
      // 后端会先 pingZhipu 验证（30 秒超时），失败也保存 -- AI 整理时再真实验证
      // 前端不再做直连智谱的 ping（iOS 真机网络慢，会假超时）
      await ref.read(apiClientProvider).call(
        'user-api',
        method: 'POST',
        path: '/api-keys',
        body: {'apiKey': key},
      );
      if (mounted) setState(() => _status = 'success');
    } catch (e) {
      if (mounted) setState(() { _status = 'error'; _error = e.toString().replaceFirst('ApiException', '').replaceAll(RegExp(r'^\(\d+,\s*'), '').replaceAll(RegExp(r'\)$'), ''); });
    }
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
          _step(1, '注册智谱开放平台', 'bigmodel.cn -> 注册账号 -> 实名认证'),
          _step(2, '创建 API Key', '控制台 -> API Keys -> 创建新 Key'),
          _step(3, '充值', '钱包 -> 充值 ¥10 起（可用 1-2 月）'),
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
                    '你的 Key 加密存储在云端，仅用于调用智谱 AI 整理你的收藏。\n'
                    '整理由云端 llm-proxy 代理调用，Key 不落客户端。',
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

// 外观选择器（真切换主题）
Future<void> _showThemePicker(BuildContext context, WidgetRef ref) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('跟随系统'),
              onTap: () => Navigator.pop(context, 'system')),
          ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('浅色'),
              onTap: () => Navigator.pop(context, 'light')),
          ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('深色'),
              onTap: () => Navigator.pop(context, 'dark')),
        ],
      ),
    ),
  );
  if (result != null) {
    final mode = result == 'light'
        ? ThemeMode.light
        : result == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    await ref.read(themeModeProvider.notifier).set(mode);
    final label = result == 'system' ? '跟随系统' : result == 'light' ? '浅色' : '深色';
    if (context.mounted) showRecallToast(context, '已切换到：$label');
  }
}

// 字体大小选择器（真切换缩放）
Future<void> _showFontSizePicker(BuildContext context, WidgetRef ref) async {
  final result = await showModalBottomSheet<String>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
              leading: const Icon(Icons.text_decrease),
              title: const Text('小'),
              onTap: () => Navigator.pop(context, 'small')),
          ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('标准'),
              onTap: () => Navigator.pop(context, 'normal')),
          ListTile(
              leading: const Icon(Icons.text_increase),
              title: const Text('大'),
              onTap: () => Navigator.pop(context, 'large')),
        ],
      ),
    ),
  );
  if (result != null) {
    await ref.read(fontScaleProvider.notifier).setByName(result);
    final label = result == 'small' ? '小' : result == 'large' ? '大' : '标准';
    if (context.mounted) showRecallToast(context, '已切换到：$label');
  }
}
