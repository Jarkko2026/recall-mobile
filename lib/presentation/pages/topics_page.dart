// lib/presentation/pages/topics_page.dart
// 主题/领域聚合页
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
    final allItems = ref.watch(allItemsProvider);
    final allCategories = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('主题')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // 顶部统计
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Row(
              children: [
                _stat('总收藏', '${allItems.length}', theme),
                const SizedBox(width: AppSpacing.s3),
                _stat('领域', '${domains.length}', theme),
                const SizedBox(width: AppSpacing.s3),
                _stat('主题', '${allCategories.where((c) => c.level == 2).length}', theme),
              ],
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

          // 领域/主题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Text('领域 / 主题', style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: AppSpacing.s3),

          ...domains.map((d) {
            final topics = allCategories
                .where((c) => c.level == 2 && c.parentId == d.id)
                .toList();
            return _DomainSection(domain: d, topics: topics, allItems: allItems);
          }),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: theme.textTheme.displayMedium?.copyWith(
                    color: AppColors.primary500, fontWeight: FontWeight.w700)),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _DomainSection extends ConsumerWidget {
  final Category domain;
  final List<Category> topics;
  final List<Item> allItems;
  const _DomainSection({
    required this.domain,
    required this.topics,
    required this.allItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final domainCount = allItems.where((i) => i.domainId == domain.id).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s2),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.folder_outlined,
                      color: AppColors.primary500, size: 20),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(domain.name, style: theme.textTheme.titleLarge),
                      Text('$domainCount 条收藏 · ${topics.length} 个主题',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.hintColor),
              ],
            ),
            if (topics.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s3),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.s3),
              ...topics.map((t) {
                final count = allItems.where((i) => i.topicId == t.id).length;
                return InkWell(
                  onTap: () => context.push('/topic/${domain.id}/${t.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                    child: Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right,
                            size: 16, color: AppColors.primary500),
                        const SizedBox(width: AppSpacing.s2),
                        Expanded(child: Text(t.name, style: theme.textTheme.bodyLarge)),
                        Text('$count', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
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
