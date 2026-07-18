# Recall Mobile

> Recall · 自动整理 · 高质量回看 · 主题串联 —— 移动端（iOS / Android）

与 web 端（v3.7.2）共享同一套 CloudBase 后端（云函数 + 自助账号体系），数据互通。

## 快速链接

- 构建说明：[BUILD.md](./BUILD.md)
- Web 端在线版：https://jarkko-cloud-2-d6gfsv71afe0890fc-1431595147.tcloudbaseapp.com/recall-web-prod/index.html

## 技术栈

- **Flutter 3.44+** / Dart 3.x
- **Riverpod 2.x**（状态管理）
- **go_router 12.x**（路由）
- **Dio 5.x**（HTTP）
- **CloudBase 云函数 HTTP 网关**（后端复用）

## 目录

```
lib/
├── core/
│   ├── theme/        # 设计 tokens + Material 3 主题
│   └── router/       # go_router + 鉴权 redirect
├── data/
│   ├── models/       # Item / Tag / Category / SeedData
│   └── repositories/ # ItemRepository + ItemsController(StateNotifier)
├── presentation/
│   ├── pages/        # 8 个页面：onboarding / login / timeline / topics / search / settings / detail / add
│   └── widgets/      # 16 个通用组件（AppButton / AppCard / TagChip / EmptyState / ConfirmSheet ...）
└── services/
    ├── api_client.dart    # CloudBase 网关客户端
    ├── auth_service.dart  # 自助账号鉴权
    └── search_service.dart # 本地搜索
```

## 后端契约

所有云函数走 CloudBase HTTP 网关：

```
POST https://jarkko-cloud-2-d6gfsv71afe0890fc.service.tcloudbase.com/{function}

body = {
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH',
  path: '/items', '/items/:id', '/auth/login', ...,
  body: { ... },
  userInfo: { uid, openId, userId, username, loginType }
}

response = {
  code: 0,        // 0 = 成功
  message: '',
  data: { ... }
}
```

`userInfo.userId` 是业务 uid（与 web 端一致：`u_xxxxxxxx`），由 user-api/auth/login 颁发，存 SharedPreferences。
