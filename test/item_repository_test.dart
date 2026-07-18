// test/item_repository_test.dart
// Phase 1.6 重写：原测试停留在仓储层从"本地内存"迁移到 CloudBase HTTP 之前的 API
// 已编译失败。现重写为基于 mock ApiClient 的单测。

import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/models/models.dart';
import 'package:recall/data/repositories/item_repository.dart';
import 'package:recall/services/api_client.dart';

/// 假 ApiClient：拦截 call() 返回预设响应
class _FakeApi implements ApiClient {
  _FakeApi(this._dispatcher);
  final Future<Map<String, dynamic>> Function(String fn, String method, String path, Map<String, dynamic>? body) _dispatcher;

  @override
  String? get userId => 'u_acc_test';
  @override
  String? get username => 'tester';
  @override
  String? get token => 'fake.jwt.token';
  @override
  bool get isAuthed => true;

  @override
  void setSession({required String userId, required String username, String? token}) {}
  @override
  void clearSession() {}

  @override
  Future<Map<String, dynamic>> call(
    String functionName, {
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    return _dispatcher(functionName, method, path, body);
  }
}

void main() {
  group('ItemRepository', () {
    test('fetchItems 解析后端响应', () async {
      final api = _FakeApi((fn, m, p, body) async {
        expect(fn, 'items-api');
        expect(m, 'GET');
        expect(p, '/items');
        return {
          'items': [
            {
              '_id': 'i_1',
              'title': '测试条目 1',
              'type': 'link',
              'created_at': 1720000000000,
              'tags': [],
              'status': 'organized',
            }
          ],
        };
      });
      final repo = ItemRepository(api);
      final list = await repo.fetchItems(limit: 10);
      expect(list.length, 1);
      expect(list.first.id, 'i_1');
      expect(list.first.title, '测试条目 1');
    });

    test('create 透传字段', () async {
      final api = _FakeApi((fn, m, p, body) async {
        expect(fn, 'items-api');
        expect(m, 'POST');
        expect(body?['title'], '新条目');
        expect(body?['type'], 'text');
        return {
          'item': {
            '_id': 'i_new',
            'title': '新条目',
            'type': 'text',
            'created_at': 1720000000000,
            'tags': [],
            'status': 'pending',
          }
        };
      });
      final repo = ItemRepository(api);
      final item = await repo.create(title: '新条目', type: ItemType.text);
      expect(item.id, 'i_new');
      expect(item.title, '新条目');
    });

    test('delete 调 DELETE 路径', () async {
      var called = false;
      final api = _FakeApi((fn, m, p, body) async {
        expect(m, 'DELETE');
        expect(p, '/items/i_42');
        called = true;
        return {};
      });
      final repo = ItemRepository(api);
      await repo.delete('i_42');
      expect(called, true);
    });

    test('markViewed 调 POST /items/{id}/view', () async {
      var called = false;
      final api = _FakeApi((fn, m, p, body) async {
        expect(m, 'POST');
        expect(p, '/items/i_99/view');
        called = true;
        return {};
      });
      final repo = ItemRepository(api);
      await repo.markViewed('i_99');
      expect(called, true);
    });
  });
}
