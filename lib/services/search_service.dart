// lib/services/search_service.dart
// 客户端模糊搜索 —— 对应方案 §4.5.4 Fuse.js 等价的 Dart 实现
// 真实环境：Fuse.js (JS) → 这里用 Dart 自行实现加权 + 模糊匹配

class SearchHit {
  final String itemId;
  final int score; // 越高越相关
  final String? highlight; // 命中片段
  SearchHit({required this.itemId, required this.score, this.highlight});
}

class SearchItemPayload {
  final String id;
  final String title;
  final String? summary;
  final String? content;
  final List<String> tagNames;
  final String? topicName;
  const SearchItemPayload({
    required this.id,
    required this.title,
    this.summary,
    this.content,
    this.tagNames = const [],
    this.topicName,
  });
}

class SearchService {
  /// 加权 + 模糊匹配
  /// - title 权重 0.5
  /// - summary 权重 0.3
  /// - content 权重 0.15
  /// - tags/topic 权重 0.05
  static List<SearchHit> search(String query, List<SearchItemPayload> items) {
    if (query.trim().length < 2) return [];
    final q = query.toLowerCase().trim();
    final hits = <SearchHit>[];

    for (final it in items) {
      double score = 0;
      String? highlight;

      // 1. 标题
      if (it.title.toLowerCase().contains(q)) {
        score += 50 * 0.5;
        highlight ??= _extract(it.title, q);
      }
      score += _charMatchScore(it.title, q) * 30 * 0.5;

      // 2. 摘要
      if (it.summary != null && it.summary!.toLowerCase().contains(q)) {
        score += 40 * 0.3;
        highlight ??= _extract(it.summary!, q, context: 30);
      }
      score += _charMatchScore(it.summary ?? '', q) * 25 * 0.3;

      // 3. 正文
      if (it.content != null && it.content!.toLowerCase().contains(q)) {
        score += 30 * 0.15;
        highlight ??= _extract(it.content!, q, context: 30);
      }

      // 4. 标签/主题
      for (final t in it.tagNames) {
        if (t.toLowerCase() == q) {
          score += 60 * 0.05;
        } else if (t.toLowerCase().contains(q)) {
          score += 30 * 0.05;
        }
      }
      if (it.topicName != null && it.topicName!.toLowerCase().contains(q)) {
        score += 20 * 0.05;
      }

      if (score > 0) {
        hits.add(SearchHit(itemId: it.id, score: score.round(), highlight: highlight));
      }
    }

    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.take(20).toList();
  }

  static double _charMatchScore(String text, String query) {
    if (text.isEmpty) return 0;
    final t = text.toLowerCase();
    int qi = 0;
    int matches = 0;
    for (int i = 0; i < t.length && qi < query.length; i++) {
      if (t[i] == query[qi]) {
        matches++;
        qi++;
      }
    }
    return query.isEmpty ? 0 : matches / query.length;
  }

  static String _extract(String text, String query, {int context = 30}) {
    final idx = text.toLowerCase().indexOf(query);
    if (idx < 0) {
      return text.length > context * 2 ? '${text.substring(0, context * 2)}...' : text;
    }
    final start = (idx - context).clamp(0, text.length);
    final end = (idx + query.length + context).clamp(0, text.length);
    final prefix = start > 0 ? '...' : '';
    final suffix = end < text.length ? '...' : '';
    return '$prefix${text.substring(start, end)}$suffix';
  }
}
