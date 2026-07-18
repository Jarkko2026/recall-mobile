// test/search_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/services/search_service.dart';

void main() {
  group('SearchService', () {
    final corpus = [
      const SearchItemPayload(
        id: 'i1',
        title: 'Claude Code 最佳实践',
        summary: '介绍 Claude Code 的工作流',
        content: '支持代码 review、自动化测试等',
        tagNames: ['AI', '工具'],
        topicName: 'AI 编程',
      ),
      const SearchItemPayload(
        id: 'i2',
        title: 'Cursor 使用心得',
        summary: 'Cursor 工具入门',
        content: 'Cursor 是 VSCode 的 AI 增强',
        tagNames: ['AI'],
        topicName: 'AI 编程',
      ),
      const SearchItemPayload(
        id: 'i3',
        title: 'Flutter 性能优化',
        summary: 'const 构造函数、RepaintBoundary',
        content: '几个关键点',
        tagNames: ['编程'],
        topicName: '前端工程',
      ),
    ];

    test('短查询 (<2 字符) 不返回结果', () {
      expect(SearchService.search('a', corpus), isEmpty);
      expect(SearchService.search('', corpus), isEmpty);
    });

    test('精确匹配标题排序最高', () {
      final hits = SearchService.search('Claude Code', corpus);
      expect(hits, isNotEmpty);
      expect(hits.first.itemId, 'i1');
      expect(hits.first.score, greaterThan(0));
    });

    test('匹配摘要/正文也能命中', () {
      final hits = SearchService.search('工作流', corpus);
      expect(hits.any((h) => h.itemId == 'i1'), isTrue);
    });

    test('不存在的词返回空', () {
      final hits = SearchService.search('xyz_no_match', corpus);
      expect(hits, isEmpty);
    });

    test('提取高亮片段', () {
      final hits = SearchService.search('Cursor', corpus);
      expect(hits, isNotEmpty);
      expect(hits.first.highlight, isNotNull);
      expect(hits.first.highlight!.toLowerCase().contains('cursor'), isTrue);
    });

    test('标签精确匹配加权', () {
      final hits = SearchService.search('编程', corpus);
      // i3 有 "编程" 标签
      expect(hits.any((h) => h.itemId == 'i3'), isTrue);
    });

    test('结果按 score 降序', () {
      final hits = SearchService.search('AI', corpus);
      for (int i = 0; i < hits.length - 1; i++) {
        expect(hits[i].score, greaterThanOrEqualTo(hits[i + 1].score));
      }
    });

    test('最多返回 20 条', () {
      final big = List.generate(50, (i) => SearchItemPayload(
        id: 'i_$i',
        title: 'AI 文章 $i',
        tagNames: ['AI'],
      ));
      final hits = SearchService.search('AI', big);
      expect(hits.length, lessThanOrEqualTo(20));
    });
  });
}
