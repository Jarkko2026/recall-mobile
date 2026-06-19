// lib/services/api_client.dart
// CloudBase 网关 HTTP 客户端
// 通过 https://{env}.service.tcloudbase.com/{function}{path} 调用云函数
// 与 web 端共用同一套云函数（items-api / user-api / search-api / llm-proxy）

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiException implements Exception {
  final int code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => 'ApiException($code, $message)';
}

class ApiClient {
  static const String baseUrl =
      'https://jarkko-cloud-01-d4f8nqwdcddd2c9c.service.tcloudbase.com';

  final Dio _dio;
  String? _userId;
  String? _username;

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
          validateStatus: (_) => true,
        ));

  void setSession({required String userId, required String username}) {
    _userId = userId;
    _username = username;
  }

  void clearSession() {
    _userId = null;
    _username = null;
  }

  String? get userId => _userId;
  String? get username => _username;
  bool get isAuthed => _userId != null;

  Map<String, dynamic> _userInfoMap() {
    final uid = _userId ?? 'web_anon_${DateTime.now().millisecondsSinceEpoch}';
    return {
      'uid': uid,
      'openId': uid,
      'userId': uid,
      'username': _username ?? '',
      'loginType': _userId != null ? 'ACCOUNT' : 'ANONYMOUS',
    };
  }

  /// 调用云函数（HTTP 网关）
  /// 全部用 POST 发送，body 顶层带：
  /// - 业务字段
  /// - __method: 真实 HTTP method（云函数据此派发）
  /// - __userInfo: 用户身份（私有路由要求）
  Future<Map<String, dynamic>> call(
    String functionName, {
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final url = '/$functionName$path';
    final m = method.toUpperCase();

    final mergedBody = <String, dynamic>{};
    if (body != null) mergedBody.addAll(body);
    mergedBody['__method'] = m;
    if (requireAuth || _userId != null) {
      mergedBody['__userInfo'] = _userInfoMap();
    }

    try {
      final res = await _dio.post(url, data: mergedBody);
      final data = res.data;
      Map<String, dynamic> respBody;
      if (data is Map<String, dynamic>) {
        respBody = data;
      } else if (data is String) {
        respBody = {'code': -1, 'message': data};
      } else {
        respBody = {'code': -1, 'message': '未知响应'};
      }
      final code = respBody['code'];
      if (code != 0) {
        throw ApiException(
          (code is int) ? code : -1,
          (respBody['message'] ?? '调用失败').toString(),
        );
      }
      final inner = respBody['data'];
      if (inner is Map<String, dynamic>) return inner;
      return {'data': inner};
    } on DioException catch (e) {
      throw ApiException(
        e.response?.statusCode ?? -1,
        e.message ?? '网络异常',
      );
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
