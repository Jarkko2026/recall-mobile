// lib/services/api_client.dart
// CloudBase 网关 HTTP 客户端
// 通过 https://{env}.service.tcloudbase.com/{function} 调用云函数
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

  /// 调用云函数（HTTP 网关）
  /// - functionName: items-api / user-api / search-api / llm-proxy
  /// - method/path/body: 与 web 端 callFunction 的语义对齐
  Future<Map<String, dynamic>> call(
    String functionName, {
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final payload = <String, dynamic>{
      'method': method,
      'path': path,
      if (body != null) 'body': body,
    };
    if (requireAuth || _userId != null) {
      final uid = _userId ?? 'web_anon_${DateTime.now().millisecondsSinceEpoch}';
      payload['userInfo'] = {
        'uid': uid,
        'openId': uid,
        'userId': uid,
        'username': _username ?? '',
        'loginType': _userId != null ? 'ACCOUNT' : 'ANONYMOUS',
      };
    }

    try {
      final res = await _dio.post('/$functionName', data: payload);
      final data = res.data;
      // CloudBase HTTP 网关返回结构：直接是云函数 return 值
      Map<String, dynamic> body;
      if (data is Map<String, dynamic>) {
        body = data;
      } else if (data is String) {
        // 容错：偶尔被序列化两次
        body = {'code': -1, 'message': data};
      } else {
        body = {'code': -1, 'message': '未知响应'};
      }
      final code = body['code'];
      if (code != 0) {
        throw ApiException(
          (code is int) ? code : -1,
          (body['message'] ?? '调用失败').toString(),
        );
      }
      final inner = body['data'];
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
