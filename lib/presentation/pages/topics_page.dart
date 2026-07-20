// lib/presentation/pages/topics_page.dart
// 知识谱系 - 领域/主题聚合（可折叠树 + graph 统计）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/models.dart';
import '../../data/repositories/item_repository.dart';
import '../widgets/common.dart';

class TopicsPage extends ConsumerWidget {
  const TopicsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domains = ref.watch(domainCategoriesProvider);
    final theme = Theme.of(context);
    final graph = ref.watch(graphDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('知识谱系')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // graph 统计头
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: graph.when(
              data: (g) => _GraphStatsCard(
                total: (g['total_items'] as num?)?.toInt() ?? 0,
                domains: (g['domain_count'] as num?)?.toInt() ?? 0,
                topics: (g['topic_count'] as num?)?.toInt() ?? 0,
                tags: (g['tag_count'] as num?)?.toInt() ?? 0,
              ),
              loading: () => const SizedBox(height: 88, child: Center(child: CircularProgressIndicator())),
              error: (_, __) => const SizedBox(height: 88, child: Center(child: Text('统计加载失败'))),
            ),
          ),

          // 标签云
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('热门标签', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.s3),
                Wrap(
                  spacing: AppSpacing.s2,
                  runSpacing: AppSpacing.s2,
                  children: ref.watch(allTagsProvider).take(15).map((t) =>
                    TagChip(label: '${t.name} (${t.useCount})')
                  ).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s5),

          // 领域/主题 可折叠树
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Text('领域 / 主题', style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.s3),

          ...domains.map((d) {
            final topics = ref.watch(allCategoriesProvider)
                .where((c) => c.level == 2 && c.parentId == d.id)
                .toList();
            return _DomainSection(domain: d, topics: topics, allItems: ref.watch(allItemsProvider));
          }),
        ],
      ),
    );
  }
}

/// graph 统计卡（4 格）
class _GraphStatsCard extends StatelessWidget {
  final int total;
  final int domains;
  final int topics;
  final int tags;
  const _GraphStatsCard({required this.total, required this.domains, required this.topics, required this.tags});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tiles = [
      ('总收藏', total, Icons.bookmark_outline),
      ('领域', domains, Icons.folder_outlined),
      ('主题', topics, Icons.label_outline),
      ('标签', tags, Icons.tag),
    ];
    return AppCard(
      child: Row(
        children: tiles.map((t) {
          return Expanded(
            child: Column(
              children: [
                Icon(t.$3, size: 20, color: AppColors.primary500),
                const SizedBox(height: 4),
                Text('${t.$2}', style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary500, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(t.$1, style: theme.textTheme.bodySmall),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DomainSection extends ConsumerStatefulWidget {
  final Category domain;
  final List<Category> topics;
  final List<Item> allItems;
  const _DomainSection({required this.domain, required this.topics, required this.allItems});
  @override
  ConsumerState<_DomainSection> createState() => _DomainSectionState();
}

class _DomainSectionState extends ConsumerState<_DomainSection> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final domainCount = widget.allItems.where((i) => i.domainId == widget.domain.id).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s2),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.folder_outlined, color: AppColors.primary500, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.domain.name, style: theme.textTheme.titleLarge),
                        Text('$domainCount 条收藏 · ${widget.topics.length} 个主题', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.chevron_right, color: theme.hintColor),
                ],
              ),
            ),
            if (_open) ...[
              const SizedBox(height: AppSpacing.s3),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.s2),
              ...widget.topics.map((t) {
                final count = widget.allItems.where((i) => i.topicId == t.id).length;
                return InkWell(
                  onTap: () => context.push('/topic/${widget.domain.id}/${t.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                    child: Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right, size: 16, color: AppColors.primary500),
                        const SizedBox(width: AppSpacing.s2),
                        Expanded(child: Text(t.name, style: theme.textTheme.bodyLarge)),
                        Text('$count', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.s2),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: const Text('查看全部'),
                  onPressed: () => _showDomainItems(context, widget.domain, widget.allItems),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 领域下全部收藏（点击「查看全部」-> 展示该领域 items，可跳详情）
void _showDomainItems(BuildContext context, Category domain, List<Item> allItems) {
  final items = allItems.where((i) => i.domainId == domain.id).toList();
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
            Text('${domain.name}（${items.length} 条）',
                style: Theme.of(_).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s3),
            if (items.isEmpty)
              const Text('该领域下还没有收藏')
            else
              ...items.map((i) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(i.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: i.summary != null
                        ? Text(i.summary!, maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/item/${i.id}');
                    },
                  )),
            const SizedBox(height: AppSpacing.s4),
          ],
        ),
      ),
    ),
  );
}

// === 主题详情页 ===
class TopicDetailPage extends ConsumerWidget {
  final String domainId;
  final String topicId;
  const TopicDetailPage({Key? key, required this.domainId, required this.topicId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = ref.watch(itemsByTopicProvider(topicId));
    final cats = ref.watch(allCategoriesProvider);
    Category? findCat(String id) {
      for (final c in cats) {
        if (c.id == id) return c;
      }
      return null;
    }
    final domain = findCat(domainId);
    final topic = findCat(topicId);

    return Scaffold(
      appBar: AppBar(
        title: Text('${domain?.name ?? ''} / ${topic?.name ?? ''} (${items.length})'),
      ),
      body: items.isEmpty
          ? const EmptyState(icon: Icons.topic_outlined, title: '该主题下还没有收藏')
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s4),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
              itemBuilder: (_, idx) {
                final item = items[idx];
                return AppCard(
                  onTap: () => context.push('/item/${item.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (item.summary != null) ...[
                        const SizedBox(height: AppSpacing.s2),
                        Text(item.summary!, style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: AppSpacing.s2),
                      Wrap(
                        spacing: 6,
                        children: item.tagNames.take(3).map((t) => TagChip(label: t)).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
