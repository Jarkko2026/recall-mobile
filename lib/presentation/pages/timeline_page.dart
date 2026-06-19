// lib/presentation/pages/timeline_page.dart
// 首页 - 时间线
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/models.dart';
import '../../data/repositories/item_repository.dart';
import '../widgets/common.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({Key? key}) : super(key: key);
  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(itemsControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(itemsControllerProvider);
    final items = s.items;
    final theme = Theme.of(context);

    if (s.loading && items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('时间线')),
        body: const LoadingSkeleton(),
      );
    }
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('时间线')),
        body: EmptyState(
          icon: Icons.inbox_outlined,
          title: s.error != null ? '加载失败' : '还没有收藏哦',
          subtitle: s.error != null
              ? '${s.error}\n下拉重试'
              : '把你看到的、想到的、读到的丢进来\n让 Recall 帮你整理',
          actionLabel: s.error != null ? '重试' : '添加第一条',
          onAction: () {
            if (s.error != null) {
              ref.read(itemsControllerProvider.notifier).refresh();
            } else {
              context.push('/add');
            }
          },
        ),
      );
    }

    // 按日期分组
    final grouped = _groupByDay(items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('时间线'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(itemsControllerProvider.notifier).refresh(),
        child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: grouped.length,
          itemBuilder: (_, idx) {
            final group = grouped[idx];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s4, AppSpacing.s4, AppSpacing.s4, AppSpacing.s2),
                  child: Text(
                    group.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor, fontWeight: FontWeight.w600),
                  ),
                ),
                ...group.items.map((item) => _ItemCard(item: item)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_DayGroup> _groupByDay(List<Item> items) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final fmt = DateFormat('yyyy-MM-dd');
    final groups = <String, _DayGroup>{};
    for (final it in items) {
      final dt = DateTime.fromMillisecondsSinceEpoch(it.createdAt);
      String key;
      String label;
      if (fmt.format(dt) == fmt.format(today)) {
        key = '0';
        label = '今日 · ${fmt.format(dt)}';
      } else if (fmt.format(dt) == fmt.format(yesterday)) {
        key = '1';
        label = '昨日 · ${fmt.format(dt)}';
      } else if (today.difference(dt).inDays < 7) {
        key = '2';
        label = '本周 · ${fmt.format(dt)}';
      } else {
        key = '3';
        label = fmt.format(dt);
      }
      groups.putIfAbsent(key, () => _DayGroup(label, [])).items.add(it);
    }
    final order = ['0', '1', '2', '3'];
    return order.where(groups.containsKey).map((k) => groups[k]!).toList();
  }
}

class _DayGroup {
  final String label;
  final List<Item> items;
  _DayGroup(this.label, this.items);
}

class _ItemCard extends ConsumerWidget {
  final Item item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s1),
      child: AppCard(
        onTap: () => context.push('/item/${item.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _typeIcon(item.type),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(item.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                if (item.status == ItemStatus.pending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Text('整理中',
                        style: TextStyle(fontSize: AppFonts.xs, color: AppColors.warning)),
                  ),
              ],
            ),
            if (item.summary != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(item.summary!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: AppSpacing.s3),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: item.tagNames.take(3).map((t) => TagChip(label: t)).toList(),
            ),
            const SizedBox(height: AppSpacing.s2),
            Row(
              children: [
                Text(_formatTime(item.createdAt),
                    style: TextStyle(
                        fontSize: AppFonts.xs, color: theme.hintColor)),
                const SizedBox(width: AppSpacing.s2),
                Text('· ${item.source.label}',
                    style: TextStyle(
                        fontSize: AppFonts.xs, color: theme.hintColor)),
                const Spacer(),
                if (item.viewCount > 0)
                  Row(children: [
                    Icon(Icons.visibility, size: 12, color: theme.hintColor),
                    const SizedBox(width: 2),
                    Text('${item.viewCount}',
                        style: TextStyle(
                            fontSize: AppFonts.xs, color: theme.hintColor)),
                  ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeIcon(ItemType type) {
    IconData icon;
    Color color;
    switch (type) {
      case ItemType.text:
        icon = Icons.notes; color = AppColors.primary500; break;
      case ItemType.link:
        icon = Icons.link; color = AppColors.info; break;
      case ItemType.image:
        icon = Icons.image_outlined; color = AppColors.success; break;
      case ItemType.file:
        icon = Icons.insert_drive_file_outlined; color = AppColors.warning; break;
      case ItemType.audio:
        icon = Icons.mic_none; color = AppColors.danger; break;
      case ItemType.scan:
        icon = Icons.document_scanner_outlined; color = AppColors.primary700; break;
    }
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat('HH:mm').format(dt);
    }
    return DateFormat('MM-dd').format(dt);
  }
}
