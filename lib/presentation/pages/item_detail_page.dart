// lib/presentation/pages/item_detail_page.dart
// 详情页
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/models.dart';
import '../../data/repositories/item_repository.dart';
import '../widgets/common.dart';

class ItemDetailPage extends ConsumerStatefulWidget {
  final String id;
  const ItemDetailPage({Key? key, required this.id}) : super(key: key);

  @override
  ConsumerState<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends ConsumerState<ItemDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(itemsControllerProvider.notifier).markViewedLocal(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = ref.watch(itemByIdProvider(widget.id));

    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const ErrorStateView(message: '内容不存在或已被删除'),
      );
    }

    final related = item.topicId == null ? <Item>[] : ref.watch(itemsByTopicProvider(item.topicId!))
        .where((i) => i.id != item.id).take(5).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () => _showActions(context, item)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s8),
        children: [
          Text(item.title, style: theme.textTheme.displayMedium),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Text(DateFormat('yyyy-MM-dd HH:mm').format(
                  DateTime.fromMillisecondsSinceEpoch(item.createdAt)),
                  style: theme.textTheme.bodyMedium),
              const SizedBox(width: AppSpacing.s2),
              Text('· ${item.source.label}',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
          if (item.url != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Row(
              children: [
                const Icon(Icons.link, size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(item.url!,
                      style: const TextStyle(color: AppColors.info, fontSize: AppFonts.sm),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.s5),

          // 内容区
          _buildContent(item, theme),

          if (item.summary != null) ...[
            const SizedBox(height: AppSpacing.s5),
            _sectionTitle('AI 摘要', theme),
            const SizedBox(height: AppSpacing.s2),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s4),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.primary100),
              ),
              child: Text(item.summary!, style: theme.textTheme.bodyLarge),
            ),
          ],

          const SizedBox(height: AppSpacing.s5),
          _sectionTitle('标签', theme),
          const SizedBox(height: AppSpacing.s2),
          Wrap(
            spacing: AppSpacing.s2, runSpacing: AppSpacing.s2,
            children: [
              ...item.tagNames.map((t) => TagChip(label: t)),
              TagChip(label: '+', onTap: () {}),
            ],
          ),

          const SizedBox(height: AppSpacing.s5),
          _sectionTitle('分类', theme),
          const SizedBox(height: AppSpacing.s2),
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 16, color: AppColors.primary500),
              const SizedBox(width: 4),
              Text('${item.domainName ?? '-'} / ${item.topicName ?? '-'}',
                  style: theme.textTheme.bodyLarge),
            ],
          ),

          const SizedBox(height: AppSpacing.s5),
          _sectionTitle('操作', theme),
          const SizedBox(height: AppSpacing.s2),
          Row(
            children: [
              Expanded(child: AppButton(label: '编辑', variant: AppButtonVariant.secondary, icon: Icons.edit, onPressed: () {})),
              const SizedBox(width: AppSpacing.s2),
              Expanded(child: AppButton(label: '分享', variant: AppButtonVariant.secondary, icon: Icons.share, onPressed: () {})),
              const SizedBox(width: AppSpacing.s2),
              Expanded(child: AppButton(label: '删除', variant: AppButtonVariant.danger, icon: Icons.delete_outline, onPressed: () => _confirmDelete(item))),
            ],
          ),

          if (related.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s5),
            _sectionTitle('同主题其他收藏 (${related.length})', theme),
            const SizedBox(height: AppSpacing.s2),
            ...related.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: AppCard(
                onTap: () => context.push('/item/${r.id}'),
                padding: const EdgeInsets.all(AppSpacing.s3),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title, style: theme.textTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (r.summary != null)
                            Text(r.summary!, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.primary500),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(Item item, ThemeData theme) {
    switch (item.type) {
      case ItemType.scan:
      case ItemType.image:
        return Column(
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.lightBgTertiary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.type == ItemType.scan ? Icons.document_scanner : Icons.image,
                      size: 48, color: theme.hintColor),
                  const SizedBox(height: 4),
                  Text(item.type == ItemType.scan ? '扫描文档预览' : '图片预览', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            if (item.content != null) ...[
              const SizedBox(height: AppSpacing.s3),
              MarkdownView(data: item.content!),
            ],
          ],
        );
      case ItemType.audio:
        return AudioPlayerWidget(durationSec: 24);
      case ItemType.file:
        return PdfPreview(url: item.url ?? 'document.pdf');
      case ItemType.link:
      case ItemType.text:
      default:
        return MarkdownView(data: item.content ?? '(该内容暂无正文)');
    }
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Text(title, style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.hintColor, fontWeight: FontWeight.w600, letterSpacing: 0.5));
  }

  void _showActions(BuildContext context, Item item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit), title: const Text('编辑'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.push_pin_outlined), title: const Text('加入主题'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.share), title: const Text('分享'), onTap: () => Navigator.pop(context)),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('删除', style: TextStyle(color: AppColors.danger)),
              onTap: () { Navigator.pop(context); _confirmDelete(item); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Item item) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ConfirmSheet(
        title: '确定删除？',
        message: '删除后无法恢复',
        confirmLabel: '确定删除',
        destructive: true,
      ),
    );
    if (ok == true) {
      await ref.read(itemsControllerProvider.notifier).remove(item.id);
      if (mounted) {
        showRecallToast(context, '已删除');
        context.pop();
      }
    }
  }
}
