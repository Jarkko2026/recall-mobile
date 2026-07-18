// lib/services/auth_service.dart
// 自助账号鉴权（与 web 端 v3.7.2 完全一致：直接走 user-api 云函数）
// 不依赖 CloudBase Web SDK 的匿名 token —— 移动端用 HTTP 网关直连
//
// 2026-07-18 Phase 1.2 — 增加 JWT token：
//   - 登录/注册成功后服务端返回 { token, expiresIn }
//   - 客户端持久化 token
//   - restore 时本地过期检查（exp），过期自动清掉
//   - 40102 错误码自动 logout

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthSession {
  final String userId;
  final String username;
  final String token;        // JWT
  final int issuedAt;         // 签发时间（秒）
  final int expiresAt;        // 过期时间（秒）
  final int since;            // 本地登录时间（毫秒）

  AuthSession({
    required this.userId,
    required this.username,
    required this.token,
    required this.issuedAt,
    required this.expiresAt,
    required this.since,
  });

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expiresAt;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'token': token,
        'issuedAt': issuedAt,
        'expiresAt': expiresAt,
        'since': since,
      };
  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        userId: j['userId'] as String,
        username: j['username'] as String,
        token: j['token'] as String? ?? '',
        issuedAt: (j['issuedAt'] as num?)?.toInt() ?? 0,
        expiresAt: (j['expiresAt'] as num?)?.toInt() ?? 0,
        since: (j['since'] as num?)?.toInt() ?? 0,
      );
}

class AuthService {
  static const _kSession = 'recall_account_session_v1';
  final ApiClient _api;
  AuthSession? _session;

  AuthService(this._api);

  AuthSession? get session => _session;
  String? get token => _session?.token;

  /// 启动时恢复登录态
  Future<AuthSession?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSession);
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = json.decode(raw) as Map<String, dynamic>;
      final s = AuthSession.fromJson(j);
      // Phase 1.2 — 本地过期检查：过期则清掉
      if (s.token.isEmpty || s.isExpired) {
        await prefs.remove(_kSession);
        return null;
      }
      _session = s;
      _api.setSession(userId: s.userId, username: s.username, token: s.token);
      return _session;
    } catch (_) {
      return null;
    }
  }

  Future<AuthSession> login(String username, String password) async {
    final data = await _api.call(
      'user-api',
      method: 'POST',
      path: '/auth/login',
      body: {'username': username, 'password': password},
      requireAuth: false,
    );
    final userId = (data['userId'] ?? '').toString();
    final uname = (data['username'] ?? username).toString();
    final token = (data['token'] ?? '').toString();
    final expiresIn = (data['expiresIn'] ?? 7 * 86400) as int;
    if (userId.isEmpty || token.isEmpty) throw ApiException(-1, '登录返回数据异常');
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final s = AuthSession(
      userId: userId,
      username: uname,
      token: token,
      issuedAt: now,
      expiresAt: now + expiresIn,
      since: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist(s);
    return s;
  }

  Future<AuthSession> register(String username, String password) async {
    final data = await _api.call(
      'user-api',
      method: 'POST',
      path: '/auth/register',
      body: {'username': username, 'password': password},
      requireAuth: false,
    );
    final userId = (data['userId'] ?? '').toString();
    final uname = (data['username'] ?? username).toString();
    final token = (data['token'] ?? '').toString();
    final expiresIn = (data['expiresIn'] ?? 7 * 86400) as int;
    if (userId.isEmpty || token.isEmpty) throw ApiException(-1, '注册返回数据异常');
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final s = AuthSession(
      userId: userId,
      username: uname,
      token: token,
      issuedAt: now,
      expiresAt: now + expiresIn,
      since: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist(s);
    return s;
  }

  /// JWT 刷新（在 token 仍有效时换新 token）
  Future<AuthSession?> refresh() async {
    if (_session == null) return null;
    try {
      final data = await _api.call(
        'user-api',
        method: 'POST',
        path: '/auth/refresh',
        requireAuth: true,
      );
      final userId = (data['userId'] ?? '').toString();
      final uname = (data['username'] ?? _session!.username).toString();
      final token = (data['token'] ?? '').toString();
      final expiresIn = (data['expiresIn'] ?? 7 * 86400) as int;
      if (token.isEmpty) return null;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final s = AuthSession(
        userId: userId,
        username: uname,
        token: token,
        issuedAt: now,
        expiresAt: now + expiresIn,
        since: _session!.since,
      );
      await _persist(s);
      return s;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSession);
    _session = null;
    _api.clearSession();
  }

  Future<void> _persist(AuthSession s) async {
    _session = s;
    _api.setSession(userId: s.userId, username: s.username, token: s.token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSession, json.encode(s.toJson()));
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthService(api);
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  final AuthService _svc;
  AuthController(this._svc) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final s = await _svc.restore();
      state = AsyncValue.data(s);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String u, String p) async {
    state = const AsyncValue.loading();
    try {
      final s = await _svc.login(u, p);
      state = AsyncValue.data(s);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register(String u, String p) async {
    state = const AsyncValue.loading();
    try {
      final s = await _svc.register(u, p);
      state = AsyncValue.data(s);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _svc.logout();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});
