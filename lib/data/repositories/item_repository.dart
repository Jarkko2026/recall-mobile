// lib/data/repositories/item_repository.dart
// 远程仓储 —— 直连 CloudBase 云函数 items-api
// 设计原则：保持原有 ItemRepository 同名 provider 接口，UI 层无需大改
// 数据存放在 ItemsState（StateNotifier）里，allItemsProvider 读取它

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_client.dart';
import '../models/models.dart';
import '../models/seed_data.dart';

class ItemRepository {
  final ApiClient _api;
  ItemRepository(this._api);

  // ===== items =====

  Future<List<Item>> fetchItems({String? topicId, String? domainId, String? tagId, int limit = 200, String sort = 'created_at', String dir = 'desc'}) async {
    final body = <String, dynamic>{};
    if (topicId != null) body['topicId'] = topicId;
    if (domainId != null) body['domainId'] = domainId;
    if (tagId != null) body['tagId'] = tagId;
    body['limit'] = limit;
    body['sort'] = sort;
    body['dir'] = dir;
    final data = await _api.call('items-api', method: 'GET', path: '/items', body: body);
    final list = (data['items'] as List? ?? []);
    return list
        .whereType<Map>()
        .map((m) => _itemFromBackend(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<Item> create({
    required String title,
    required ItemType type,
    String? content,
    String? url,
    ItemSource source = ItemSource.manual,
    bool autoOrganize = true,
  }) async {
    final data = await _api.call('items-api', method: 'POST', path: '/items', body: {
      'title': title,
      'type': type.value,
      if (content != null) 'content': content,
      if (url != null) 'url': url,
      'source': source.value,
      'auto_organize': autoOrganize,
    });
    final m = (data['item'] as Map?) ?? data;
    return _itemFromBackend(Map<String, dynamic>.from(m));
  }

  Future<Item> updatePatch(String id, Map<String, dynamic> patch) async {
    final data = await _api.call('items-api', method: 'PATCH', path: '/items/$id', body: patch);
    final m = (data['item'] as Map?) ?? data;
    return _itemFromBackend(Map<String, dynamic>.from(m));
  }

  Future<void> delete(String id) async {
    await _api.call('items-api', method: 'DELETE', path: '/items/$id');
  }

  Future<Item?> getById(String id) async {
    try {
      final data = await _api.call('items-api', method: 'GET', path: '/items/$id');
      final m = (data['item'] as Map?) ?? data;
      return _itemFromBackend(Map<String, dynamic>.from(m));
    } catch (e) {
      // Phase 2.5 — 区分 404（条目不存在）和网络错误
      if (e is ApiException && e.code == 40400) return null;
      if (e is ApiException && (e.code == 40301 || e.code == 40404)) return null;
      rethrow;
    }
  }

  Future<void> markViewed(String id) async {
    await _api.call('items-api', method: 'POST', path: '/items/$id/view');
  }

  Future<Map<String, dynamic>> graph() async {
    final data = await _api.call('items-api', method: 'GET', path: '/items/graph');
    return data;
  }

  // ===== utilities =====
  // 后端 toClient 返回 original_preview（原文截断 2000 字）而非 content；
  // 且 organize 写回的 summary_sections / summary_long / fail_reason 必须在此完整解析，
  // 否则详情页「内容/长摘要/AI 整理详情/失败原因」会空白（与 web 端表现不一致）。
  Item _itemFromBackend(Map<String, dynamic> m) {
    final id = (m['_id'] ?? m['id'] ?? '').toString();
    return Item(
      id: id,
      userId: (m['user_id'] ?? '').toString(),
      type: ItemTypeX.from((m['type'] ?? 'text').toString()),
      title: (m['title'] ?? '').toString(),
      content: (m['original_preview'] as String?) ?? (m['content'] as String?),
      url: m['url'] as String?,
      summary: m['summary'] as String?,
      summarySections: m['summary_sections'] is Map
          ? Map<String, dynamic>.from(m['summary_sections'])
          : null,
      summaryLong: m['summary_long'] as String?,
      failReason: m['fail_reason'] as String?,
      tagIds: (m['tag_ids'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      domainId: m['domain_id'] as String?,
      topicId: m['topic_id'] as String?,
      attachmentIds:
          (m['attachment_ids'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      status: ItemStatusX.from(m['status'] as String?),
      source: ItemSourceX.from(m['source'] as String?),
      createdAt: (m['created_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: (m['updated_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      viewCount: (m['view_count'] as num?)?.toInt() ?? 0,
      lastViewedAt: (m['last_viewed_at'] as num?)?.toInt(),
      tagNames: (m['tag_names'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      domainName: m['domain_name'] as String?,
      topicName: m['topic_name'] as String?,
    );
  }
}

// ===== Riverpod providers =====

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(apiClientProvider));
});

/// 知识谱系聚合数据（/items/graph）-- 用于谱系可视化
final graphDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(itemRepositoryProvider).graph();
});

/// 全量 items 状态（带加载/失败态）
class ItemsState {
  final List<Item> items;
  final bool loading;
  final Object? error;
  const ItemsState({this.items = const [], this.loading = false, this.error});

  ItemsState copyWith({List<Item>? items, bool? loading, Object? error, bool clearError = false}) =>
      ItemsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

class ItemsController extends StateNotifier<ItemsState> {
  final ItemRepository _repo;
  String _sort = 'created_at';
  String _dir = 'desc';
  ItemsController(this._repo) : super(const ItemsState());

  Future<void> refresh() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final list = await _repo.fetchItems(limit: 500, sort: _sort, dir: _dir);
      state = ItemsState(items: list, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// 设置排序并刷新（sort: created_at/updated_at/view_count）
  void setSort(String sort, [String dir = 'desc']) {
    _sort = sort;
    _dir = dir;
    refresh();
  }

  Future<Item> add(Item draft, {bool autoOrganize = true}) async {
    final created = await _repo.create(
      title: draft.title,
      type: draft.type,
      content: draft.content,
      url: draft.url,
      source: draft.source,
      autoOrganize: autoOrganize,
    );
    state = state.copyWith(items: [created, ...state.items]);
    return created;
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    state = state.copyWith(items: state.items.where((e) => e.id != id).toList());
  }

  Future<void> patch(String id, Map<String, dynamic> p) async {
    final updated = await _repo.updatePatch(id, p);
    state = state.copyWith(
      items: state.items.map((e) => e.id == id ? updated : e).toList(),
    );
  }

  Future<void> markViewedLocal(String id) async {
    try { await _repo.markViewed(id); } catch (_) {}
    state = state.copyWith(
      items: state.items
          .map((e) => e.id == id
              ? e.copyWith(
                  viewCount: e.viewCount + 1,
                  lastViewedAt: DateTime.now().millisecondsSinceEpoch,
                )
              : e)
          .toList(),
    );
  }
}

final itemsControllerProvider =
    StateNotifierProvider<ItemsController, ItemsState>((ref) {
  return ItemsController(ref.watch(itemRepositoryProvider));
});

// ===== 兼容旧 provider 名 =====

final allItemsProvider = Provider<List<Item>>((ref) {
  return ref.watch(itemsControllerProvider).items;
});

final allTagsProvider = Provider<List<Tag>>((ref) {
  // 远端没单独 tags 接口时，从 items 推导
  final items = ref.watch(allItemsProvider);
  final map = <String, Tag>{};
  for (final it in items) {
    for (var i = 0; i < it.tagIds.length; i++) {
      final id = it.tagIds[i];
      final name = i < it.tagNames.length ? it.tagNames[i] : id;
      final cur = map[id];
      map[id] = Tag(id: id, name: name, useCount: (cur?.useCount ?? 0) + 1);
    }
  }
  // fallback：seed
  if (map.isEmpty) return SeedData.tags;
  final l = map.values.toList()..sort((a, b) => b.useCount.compareTo(a.useCount));
  return l;
});

final allCategoriesProvider = Provider<List<Category>>((ref) {
  final items = ref.watch(allItemsProvider);
  final map = <String, Category>{};
  for (final it in items) {
    if (it.domainId != null && it.domainId!.isNotEmpty) {
      map.putIfAbsent(
        it.domainId!,
        () => Category(id: it.domainId!, level: 1, name: it.domainName ?? '未命名'),
      );
    }
    if (it.topicId != null && it.topicId!.isNotEmpty) {
      map.putIfAbsent(
        it.topicId!,
        () => Category(
          id: it.topicId!,
          level: 2,
          name: it.topicName ?? '未命名主题',
          parentId: it.domainId,
        ),
      );
    }
  }
  if (map.isEmpty) return SeedData.categories;
  return map.values.toList();
});

final domainCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(allCategoriesProvider).where((c) => c.level == 1).toList();
});

final topicsByDomainProvider =
    Provider.family<List<Category>, String>((ref, domainId) {
  return ref
      .watch(allCategoriesProvider)
      .where((c) => c.level == 2 && c.parentId == domainId)
      .toList();
});

final itemsByTopicProvider =
    Provider.family<List<Item>, String>((ref, topicId) {
  return ref.watch(allItemsProvider).where((i) => i.topicId == topicId).toList();
});

final itemsByDomainProvider =
    Provider.family<List<Item>, String>((ref, domainId) {
  return ref.watch(allItemsProvider).where((i) => i.domainId == domainId).toList();
});

final itemByIdProvider = Provider.family<Item?, String>((ref, id) {
  try {
    return ref.watch(allItemsProvider).firstWhere((i) => i.id == id);
  } catch (_) {
    return null;
  }
});
