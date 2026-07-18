// lib/services/api_client.dart
// CloudBase 云函数调用客户端（与 web 端 callFunction 对齐）
//
// 2026-07-19 重要修复：
//   原实现用 HTTP 网关直连（service.tcloudbase.com/{function}/{path}），
//   但云函数是 Event 类型，HTTP 网关返回 INVALID_PATH，导致 iOS/Android 登录注册无反应。
//   现改用 CloudBase Flutter SDK 的 callFunction，与 web 端 JS SDK 完全对齐。
//
// data 格式（与 web 端 app.js callFunctionAnon / callFunction 一致）：
//   { method, path, body, userInfo, __token }

import 'dart:convert';
import 'package:cloudbase_flutter/cloudbase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiException implements Exception {
  final int code;
  final String message;
  ApiException(this.code, this.message);
  @override
  String toString() => 'ApiException($code, $message)';
}

class ApiClient {
  static const String _envId = 'jarkko-cloud-2-d6gfsv71afe0890fc';

  CloudBase? _app;
  bool _initing = false;
  String? _userId;
  String? _username;
  String? _token; // Phase 1.2 — JWT token（业务自助账号）

  ApiClient();

  /// 初始化 CloudBase app 并匿名登录（懒加载，首次 call 时触发）
  /// 匿名登录是 CloudBase SDK 调用云函数的前置条件（与 web 端 ensureLogin 一致）
  Future<CloudBase> _ensureApp() async {
    if (_app != null) return _app!;
    if (_initing) {
      // 并发调用时等待初始化完成
      while (_initing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_app != null) return _app!;
    }
    _initing = true;
    try {
      final app = await CloudBase.init(env: _envId);
      // 匿名登录（获取 CloudBase access_token，SDK 内部用于鉴权调用云函数）
      final res = await app.auth.signInAnonymously();
      if (!res.isSuccess) {
        throw ApiException(
          -1,
          'CloudBase 匿名登录失败: ${res.error?.message ?? "未知错误"}',
        );
      }
      _app = app;
      return app;
    } finally {
      _initing = false;
    }
  }

  /// Phase 1.2 — setSession 接受业务账号 token
  void setSession({required String userId, required String username, String? token}) {
    _userId = userId;
    _username = username;
    _token = token;
  }

  void clearSession() {
    _userId = null;
    _username = null;
    _token = null;
  }

  String? get userId => _userId;
  String? get username => _username;
  String? get token => _token;
  bool get isAuthed => _userId != null && _token != null && _token!.isNotEmpty;

  Map<String, dynamic> _userInfoMap() {
    // 与 web 端 extractClientUserInfo 一致
    final uid = _userId ?? 'web_anon_${DateTime.now().millisecondsSinceEpoch}';
    return {
      'uid': uid,
      'openId': uid,
      'userId': uid,
      'username': _username ?? '',
      'loginType': _userId != null ? 'ACCOUNT' : 'ANONYMOUS',
    };
  }

  /// 调用云函数（通过 CloudBase SDK callFunction）
  ///
  /// 与 web 端 callFunctionAnon / callFunction 完全对齐：
  /// - data 顶层带 method / path / body / userInfo / __token
  /// - SDK 内部走鉴权通道调用 Event 类型云函数
  Future<Map<String, dynamic>> call(
    String functionName, {
    required String method,
    required String path,
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final app = await _ensureApp();

    // 构造 data（与 web 端 payload 格式一致）
    final data = <String, dynamic>{
      'method': method.toUpperCase(),
      'path': path,
    };
    if (body != null) data['body'] = body;
    // userInfo：登录前用匿名 uid，登录后用业务 uid
    if (requireAuth || _userId != null) {
      data['userInfo'] = _userInfoMap();
    }
    // Phase 1.2 — JWT token（服务端优先校验 token）
    if (_token != null && _token!.isNotEmpty) {
      data['__token'] = _token;
    }

    final res = await app.callFunction(name: functionName, data: data);

    // ⚠️ 不能用 res.isSuccess 判断业务成功/失败
    // SDK 的 FunctionResponse.isSuccess 只认 code==null||'200'，
    // 但 CloudBase 云函数的业务 code 是 0=成功（由 _shared/auth.js ok() 产生）。
    // 云函数成功返回 {code:0, data:{...}} 时，SDK 的 code="0"，isSuccess=false（误判失败）。
    //
    // SDK 的 result 解析逻辑：result = json['result'] ?? json['data'] ?? json
    // - 成功时（云函数返回 {code:0, data:{...}}）：result = data 内容（无 code 字段）
    // - 失败时（云函数返回 {code:40404, message:"..."}）：result = 整个 json（有 code 字段）
    final result = res.result;
    Map<String, dynamic> respBody;
    if (result is Map<String, dynamic>) {
      respBody = result;
    } else if (result is String) {
      try {
        final decoded = jsonDecode(result);
        respBody = (decoded is Map<String, dynamic>)
            ? decoded
            : <String, dynamic>{'code': -1, 'message': result};
      } catch (_) {
        throw ApiException(-1, '响应解析失败: $result');
      }
    } else if (result == null) {
      throw ApiException(-1, '云函数返回空响应');
    } else {
      respBody = {'code': -1, 'message': '未知响应类型: $result'};
    }

    // 业务层错误检查：
    // - respBody 有 'code' 字段且 != 0 → 业务失败（如 40404 账号不存在）
    // - respBody 无 'code' 字段 → 业务成功（result 是 data 内容）
    final bizCode = respBody['code'];
    if (bizCode != null && bizCode != 0) {
      throw ApiException(
        (bizCode is int) ? bizCode : (int.tryParse(bizCode.toString()) ?? -1),
        (respBody['message'] ?? '调用失败').toString(),
      );
    }

    // 业务成功：respBody 可能是 data 内容（无 code 字段）或整个 json（code=0）
    final inner = respBody['data'];
    if (inner is Map<String, dynamic>) return inner;
    return respBody;
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
