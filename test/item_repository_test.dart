// test/item_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/models/models.dart';
import 'package:recall/data/repositories/item_repository.dart';

void main() {
  group('ItemRepository', () {
    test('list 默认按时间倒序', () {
      final repo = ItemRepository();
      final list = repo.list();
      for (int i = 0; i < list.length - 1; i++) {
        expect(list[i].createdAt, greaterThanOrEqualTo(list[i + 1].createdAt));
      }
    });

    test('list 按 topicId 过滤', () {
      final repo = ItemRepository();
      final all = repo.list();
      final topicId = all.first.topicId!;
      final filtered = repo.list(topicId: topicId);
      expect(filtered, isNotEmpty);
      for (final it in filtered) {
        expect(it.topicId, topicId);
      }
    });

    test('list 按 q 模糊搜索 title', () {
      final repo = ItemRepository();
      final all = repo.list();
      final kw = all.first.title.substring(0, 3);
      final filtered = repo.list(q: kw);
      expect(filtered, isNotEmpty);
    });

    test('byId 返回存在的 item', () {
      final repo = ItemRepository();
      final all = repo.list();
      final it = repo.byId(all.first.id);
      expect(it, isNotNull);
      expect(it!.id, all.first.id);
    });

    test('markViewed 增加 viewCount', () async {
      final repo = ItemRepository();
      final it = repo.list().first;
      final updated = await repo.markViewed(it.id);
      expect(updated.viewCount, it.viewCount + 1);
      expect(updated.lastViewedAt, isNotNull);
    });

    test('upsertTag 累加 useCount', () async {
      final repo = ItemRepository();
      final t = await repo.upsertTag('测试新标签_xyz');
      expect(t.useCount, 1);
      final t2 = await repo.upsertTag('测试新标签_xyz');
      expect(t2.useCount, 2);
      expect(t2.id, t.id);
    });

    test('domain 类别 level=1', () {
      final repo = ItemRepository();
      final domains = repo.categories(level: 1);
      expect(domains, isNotEmpty);
      for (final d in domains) {
        expect(d.level, 1);
        expect(d.parentId, isNull);
      }
    });

    test('topics 类别 level=2', () {
      final repo = ItemRepository();
      final domains = repo.categories(level: 1);
      final topics = repo.categories(level: 2, parentId: domains.first.id);
      for (final t in topics) {
        expect(t.level, 2);
        expect(t.parentId, domains.first.id);
      }
    });
  });

  group('Item.draft', () {
    test('draft 必填字段填充', () {
      final it = Item.draft(
        userId: 'u1',
        type: ItemType.text,
        title: '测试',
        content: '正文',
      );
      expect(it.id, startsWith('i_'));
      expect(it.status, ItemStatus.pending);
      expect(it.createdAt, greaterThan(0));
    });
  });
}
