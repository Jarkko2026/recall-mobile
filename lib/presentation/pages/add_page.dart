// lib/presentation/pages/add_page.dart
// 添加 Modal - 文本/链接/拍照(OCR)/文件/语音 Tab
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/models.dart';
import '../../data/repositories/item_repository.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
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

  // 拍照/图片 OCR
  XFile? _image;
  String? _imageDataUrl; // data:image/...;base64,...

  // 文件导入（文本类）
  String? _fileContent;
  String? _fileName;

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

  Future<void> _pickImage(ImageSource src) async {
    try {
      final f = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      final mime = f.mimeType ?? 'image/jpeg';
      if (mounted) {
        setState(() {
          _image = f;
          _imageDataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
          if (_titleCtrl.text.trim().isEmpty) {
            _titleCtrl.text = f.name.replaceAll(RegExp(r'\.[^.]+$'), '');
          }
        });
      }
    } catch (e) {
      if (mounted) showRecallToast(context, '选取失败：$e', isError: true);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'md', 'markdown', 'csv', 'json', 'log', 'html'],
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      final path = f.path;
      if (path == null) {
        if (mounted) showRecallToast(context, '无法读取该文件路径', isError: true);
        return;
      }
      final bytes = await File(path).readAsBytes();
      final raw = utf8.decode(bytes, allowMalformed: true);
      final trimmed = raw.length > 60000 ? raw.substring(0, 60000) : raw;
      if (mounted) {
        setState(() {
          _fileContent = trimmed;
          _fileName = f.name;
          if (_titleCtrl.text.trim().isEmpty) {
            _titleCtrl.text = f.name.replaceAll(RegExp(r'\.[^.]+$'), '');
          }
        });
      }
    } catch (e) {
      if (mounted) showRecallToast(context, '选取失败：$e', isError: true);
    }
  }

  Future<void> _save(ItemType type) async {
    if (_titleCtrl.text.trim().isEmpty) {
      showRecallToast(context, '请输入标题', isError: true);
      return;
    }
    // 语音导入暂未支持（依赖未就绪），诚实提示，避免存入空 item
    if (type == ItemType.audio) {
      showRecallToast(context, '语音导入即将支持，请先用文本 / 链接 / 拍照 / 文件');
      return;
    }

    setState(() => _saving = true);
    final ctrl = ref.read(itemsControllerProvider.notifier);
    final auth = ref.read(authControllerProvider).value;
    final userId = auth?.userId ?? 'u_local';
    String? content;

    try {
      if (type == ItemType.text) {
        content = _contentCtrl.text.trim();
        if (content.isEmpty) {
          showRecallToast(context, '请输入内容', isError: true);
          setState(() => _saving = false);
          return;
        }
      } else if (type == ItemType.scan) {
        if (_imageDataUrl == null) {
          showRecallToast(context, '请先选取图片', isError: true);
          setState(() => _saving = false);
          return;
        }
        showRecallToast(context, 'OCR 识别中…');
        final ocr = await ref.read(apiClientProvider).call(
          'ocr-worker',
          method: 'POST',
          path: '/ocr',
          body: {'dataUrl': _imageDataUrl},
        );
        final text = (ocr['text'] as String?) ?? '';
        final summary = (ocr['summary'] as String?) ?? '';
        content = (summary.isNotEmpty ? '【视觉摘要】$summary\n\n' : '') + text;
        if (content.trim().isEmpty) {
          showRecallToast(context, '未识别到文字', isError: true);
          setState(() => _saving = false);
          return;
        }
      } else if (type == ItemType.file) {
        content = _fileContent;
        if (content == null || content.trim().isEmpty) {
          showRecallToast(context, '请先选取文件', isError: true);
          setState(() => _saving = false);
          return;
        }
      }

      final draft = Item.draft(
        userId: userId,
        type: type,
        title: _titleCtrl.text.trim(),
        content: content,
        url: type == ItemType.link ? _urlCtrl.text.trim() : null,
        source: type == ItemType.scan ? ItemSource.scan : ItemSource.manual,
      );
      final item = await ctrl.add(draft, autoOrganize: _autoOrganize);
      // 后端 items-api 创建后 status=pending，前端异步触发 llm-proxy /organize
      if (_autoOrganize) {
        final api = ref.read(apiClientProvider);
        api.call('llm-proxy', method: 'POST', path: '/organize', body: {'itemId': item.id}).then((_) {}).catchError((_) {});
      }
      if (mounted) {
        showRecallToast(context, '已存入，AI 正在整理...');
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
                _comingSoonTab('语音录入', '语音转文字导入，即将支持。请先用文本 / 链接 / 拍照 / 文件。'),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_image != null)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Image.memory(
                  _imageBytes(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: AppColors.lightBgTertiary, child: const Icon(Icons.broken_image, size: 48)),
                ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.lightBgTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.primary500.withOpacity(0.3), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.document_scanner_outlined, size: 56, color: AppColors.primary500),
                    const SizedBox(height: 8),
                    Text('拍照或选图，OCR 自动识别文字', style: TextStyle(color: AppColors.primary500, fontSize: AppFonts.sm)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(child: AppButton(label: '拍照', icon: Icons.camera_alt_outlined, variant: AppButtonVariant.secondary, onPressed: () => _pickImage(ImageSource.camera))),
              const SizedBox(width: AppSpacing.s2),
              Expanded(child: AppButton(label: '相册', icon: Icons.photo_outlined, variant: AppButtonVariant.secondary, onPressed: () => _pickImage(ImageSource.gallery))),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          AppInput(controller: _titleCtrl, label: '标题', hint: '为这次识别命名'),
        ],
      ),
    );
  }

  // 文件导入（txt/md/csv/json/log/html 文本文件）
  Widget _fileTab() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_fileName != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.s4),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.primary100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary500),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(child: Text(_fileName!, style: const TextStyle(color: AppColors.primary700, fontWeight: FontWeight.w600))),
                  IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() { _fileContent = null; _fileName = null; })),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text('${_fileContent?.length ?? 0} 字', style: theme.textTheme.bodySmall),
          ] else
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s8),
                decoration: BoxDecoration(
                  color: AppColors.lightBgTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.primary500.withOpacity(0.3), width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primary500),
                    const SizedBox(height: 8),
                    const Text('点击选择文件', style: TextStyle(color: AppColors.primary500, fontSize: AppFonts.base)),
                    const SizedBox(height: 4),
                    const Text('支持 txt / md / csv / json / log / html', style: TextStyle(color: Color(0xFF9CA0A8), fontSize: AppFonts.xs)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.s3),
          AppInput(controller: _titleCtrl, label: '标题', hint: '为这个文件命名'),
        ],
      ),
    );
  }

  // 诚实占位：未实现的导入方式
  Widget _comingSoonTab(String title, String desc) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top, size: 56, color: AppColors.accent),
            const SizedBox(height: AppSpacing.s3),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s2),
            Text(desc, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          ],
        ),
      ),
    );
  }

  // _image 的 bytes（用于预览）
  Uint8List _imageBytes() {
    final b64 = (_imageDataUrl ?? '').split('base64,').last;
    return base64Decode(b64);
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
