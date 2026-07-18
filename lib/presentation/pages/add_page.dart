// lib/presentation/pages/add_page.dart
// 添加 Modal - 文本/链接/拍照/文件/语音 Tab
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/models.dart';
import '../../data/repositories/item_repository.dart';
import '../../services/auth_service.dart';
import '../widgets/common.dart';

class AddPage extends ConsumerStatefulWidget {
  const AddPage({Key? key}) : super(key: key);
  @override
  ConsumerState<AddPage> createState() => _AddPageState();
}

class _AddPageState extends ConsumerState<AddPage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _tags = <String>[];
  bool _autoOrganize = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(ItemType type) async {
    if (_titleCtrl.text.trim().isEmpty) {
      showRecallToast(context, '请输入标题', isError: true);
      return;
    }
    setState(() => _saving = true);
    final ctrl = ref.read(itemsControllerProvider.notifier);
    final auth = ref.read(authControllerProvider).value;
    final userId = auth?.userId ?? 'u_local';
    final draft = Item.draft(
      userId: userId,
      type: type,
      title: _titleCtrl.text.trim(),
      content: type == ItemType.text ? _contentCtrl.text.trim() : null,
      url: type == ItemType.link ? _urlCtrl.text.trim() : null,
      source: type == ItemType.scan ? ItemSource.scan
            : type == ItemType.audio ? ItemSource.asr
            : ItemSource.manual,
    );
    try {
      await ctrl.add(draft, autoOrganize: _autoOrganize);
      if (mounted) {
        showRecallToast(context, '已存入，正在整理...');
        context.pop();
      }
    } catch (e) {
      if (mounted) showRecallToast(context, '保存失败：$e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: const Text('添加'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: '文本'),
            Tab(text: '链接'),
            Tab(text: '拍照'),
            Tab(text: '文件'),
            Tab(text: '语音'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _textTab(),
                _linkTab(),
                _scanTab(),
                _fileTab(),
                _audioTab(),
              ],
            ),
          ),

          // 通用底部
          Container(
            padding: const EdgeInsets.all(AppSpacing.s4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_offer_outlined, size: 16, color: AppColors.primary500),
                    const SizedBox(width: 4),
                    Text('标签：${_tags.join(', ')}', style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    TextButton(onPressed: _showTagPicker, child: const Text('+ 添加标签')),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('使用 AI 自动整理', style: TextStyle(fontSize: AppFonts.base)),
                  subtitle: const Text('自动提取标签 / 分类 / 摘要', style: TextStyle(fontSize: AppFonts.xs)),
                  value: _autoOrganize,
                  onChanged: (v) => setState(() => _autoOrganize = v),
                ),
                AppButton(
                  label: _saving ? '保存中...' : '保存',
                  onPressed: _saving ? null : () {
                    final types = [ItemType.text, ItemType.link, ItemType.scan, ItemType.file, ItemType.audio];
                    _save(types[_tab.index]);
                  },
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        children: [
          AppInput(controller: _titleCtrl, label: '标题', hint: '一句话总结'),
          const SizedBox(height: AppSpacing.s3),
          AppInput(controller: _contentCtrl, label: '内容', hint: '粘贴或输入正文', multiline: true, maxLines: 10),
        ],
      ),
    );
  }

  Widget _linkTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        children: [
          AppInput(controller: _urlCtrl, label: '链接 URL', hint: 'https://...', prefix: const Icon(Icons.link)),
          const SizedBox(height: AppSpacing.s3),
          AppInput(controller: _titleCtrl, label: '标题（可自动抓取）', hint: '选填'),
          const SizedBox(height: AppSpacing.s3),
          AppInput(controller: _contentCtrl, label: '备注', hint: '你想说点什么', multiline: true, maxLines: 6),
        ],
      ),
    );
  }

  Widget _scanTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4/3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightBgTertiary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.primary500.withOpacity(0.3), style: BorderStyle.solid, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.document_scanner_outlined, size: 64, color: AppColors.primary500),
                  const SizedBox(height: 8),
                  const Text('点击启动 VisionKit 文档扫描', style: TextStyle(color: AppColors.primary500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          AppInput(controller: _titleCtrl, label: '标题', hint: '为这次扫描命名'),
        ],
      ),
    );
  }

  Widget _fileTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s8),
            decoration: BoxDecoration(
              color: AppColors.lightBgTertiary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary500),
                const SizedBox(height: 8),
                const Text('点击选择文件', style: TextStyle(color: AppColors.primary500, fontSize: AppFonts.base)),
                const SizedBox(height: 4),
                const Text('支持 PDF / Word / Markdown / TXT', style: TextStyle(color: Color(0xFF9CA0A8), fontSize: AppFonts.xs)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          AppInput(controller: _titleCtrl, label: '标题', hint: '为这个文件命名'),
        ],
      ),
    );
  }

  Widget _audioTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.s6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary500, AppColors.primary700]),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.mic, color: Colors.white, size: 32),
                ),
                const SizedBox(width: AppSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('点击录音', style: TextStyle(color: Colors.white, fontSize: AppFonts.lg, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('00:00 / 最长 5 分钟', style: TextStyle(color: Colors.white70, fontSize: AppFonts.sm)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          AppInput(controller: _titleCtrl, label: '标题', hint: '为这段录音命名'),
        ],
      ),
    );
  }

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final all = ref.read(allTagsProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('选择标签', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.s3),
                Wrap(
                  spacing: AppSpacing.s2, runSpacing: AppSpacing.s2,
                  children: all.map((t) => TagChip(
                    label: t.name,
                    selected: _tags.contains(t.name),
                    onTap: () => setState(() {
                      if (_tags.contains(t.name)) {
                        _tags.remove(t.name);
                      } else {
                        _tags.add(t.name);
                      }
                    }),
                  )).toList(),
                ),
                const SizedBox(height: AppSpacing.s4),
                AppButton(label: '完成', onPressed: () => Navigator.pop(ctx), fullWidth: true),
              ],
            ),
          ),
        );
      },
    );
  }
}
