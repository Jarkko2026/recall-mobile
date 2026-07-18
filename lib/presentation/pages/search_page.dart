// lib/presentation/pages/search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/repositories/item_repository.dart';
import '../../services/search_service.dart';
import '../widgets/common.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({Key? key}) : super(key: key);
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  final _recentSearches = ['Claude Code', 'Cursor', '增长', 'LLM'];
  String _query = '';
  List<SearchHit> _hits = [];
  // Phase 2.5 — 搜索防抖
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    setState(() {
      _query = q;
    });
    // Phase 2.5 — 300ms 防抖，避免连续输入时阻塞主线程
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _hits = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final items = ref.read(allItemsProvider);
      final payload = items
          .map((i) => SearchItemPayload(
                id: i.id,
                title: i.title,
                summary: i.summary,
                content: i.content,
                tagNames: i.tagNames,
                topicName: i.topicName,
              ))
          .toList();
      final hits = SearchService.search(q, payload);
      if (mounted) setState(() => _hits = hits);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsById = {for (final i in ref.watch(allItemsProvider)) i.id: i};

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: RecallSearchBar(
          controller: _ctrl,
          onChanged: _onQueryChanged,
          hint: '搜索收藏内容、标签、链接',
        ),
        actions: [
          if (_query.isNotEmpty)
            TextButton(
              onPressed: () {
                _ctrl.clear();
                _onQueryChanged('');
              },
              child: const Text('取消'),
            ),
        ],
      ),
      body: _query.trim().length < 2
          ? _buildIdle(theme)
          : _hits.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: '没找到匹配结果',
                  subtitle: '换个关键词试试')
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  itemCount: _hits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
                  itemBuilder: (_, idx) {
                    final hit = _hits[idx];
                    final item = itemsById[hit.itemId];
                    if (item == null) return const SizedBox.shrink();
                    return AppCard(
                      onTap: () => context.push('/item/${item.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (hit.highlight != null) ...[
                            const SizedBox(height: AppSpacing.s2),
                            Text('...${hit.highlight}...',
                                style: TextStyle(fontSize: AppFonts.sm, color: theme.hintColor, height: AppFonts.normal),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: AppSpacing.s2),
                          Row(
                            children: [
                              Text('相关度 ${hit.score}',
                                  style: TextStyle(fontSize: AppFonts.xs, color: AppColors.primary500)),
                              const Spacer(),
                              Wrap(spacing: 6, children: item.tagNames.take(3).map((t) => TagChip(label: t)).toList()),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildIdle(ThemeData theme) {
    final hotTags = ref.watch(allTagsProvider).take(10).toList();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s4),
      children: [
        Text('最近搜索', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.s3),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: _recentSearches.map((s) => ActionChip(
            label: Text(s),
            onPressed: () {
              _ctrl.text = s;
              _onQueryChanged(s);
            },
          )).toList(),
        ),
        const SizedBox(height: AppSpacing.s5),
        Text('热门标签', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.s3),
        Wrap(
          spacing: AppSpacing.s2,
          runSpacing: AppSpacing.s2,
          children: hotTags.map((t) => TagChip(
            label: '${t.name} (${t.useCount})',
            onTap: () => _ctrl.text = t.name,
          )).toList(),
        ),
      ],
    );
  }
}
