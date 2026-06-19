# Recall Mobile · 构建说明

> 本工程同时输出 iOS / Android。当前构建机（macOS 11.7）工具链不完整，无法本地直接出包。
> 以下流程只需 5 分钟即可拿到双端可安装包。

---

## 当前文件

```
recall_app_mobile/
├── lib/                       # Flutter Dart 源码（全部就绪）
├── android/                   # Android 工程（已升级到 AGP 8.1 / Gradle 8.3 / minSdk 21）
├── ios/                       # iOS 工程（Podfile 就绪，部署目标 iOS 12）
├── .github/workflows/
│   └── build-apk.yml          # GitHub Actions 一键构建 APK
├── pubspec.yaml               # Flutter 3.16+ / Dart 3.x
└── BUILD.md                   # 当前文档
```

后端复用的 CloudBase 云函数（已开 HTTP 网关）：
- `https://jarkko-cloud-01-d4f8nqwdcddd2c9c.service.tcloudbase.com/items-api`
- `.../user-api`、`.../search-api`、`.../llm-proxy`

---

## 路线 A · 5 分钟拿到 Android APK（推荐）

### 步骤 1 · 创建 GitHub 仓库并推送

在 GitHub 网页端手动建一个空仓库（私有/公开都行），假设叫 `recall-mobile`。然后在本地：

```bash
cd /Users/seikakuki/Downloads/Jarkko/codex-project/workbuddydraft/recall_app_full/recall_app_mobile

git init -b main
git add .
git commit -m "init: recall mobile v1.0.0"
git remote add origin https://github.com/<你的用户名>/recall-mobile.git
git push -u origin main
```

### 步骤 2 · 等 CI 跑完（约 4-6 分钟）

打开仓库 → Actions 标签 → 看到 `Build Android APK` 任务在跑。

### 步骤 3 · 下载 APK

任务完成后，点进去 → 底部 Artifacts 区域 → 下载 `recall-android-apk.zip` → 解压即得 `recall-XXXXXXX.apk`。

> 直接发到手机即可安装（首次安装 Android 会要求允许"未知来源"）。

### 标签发布（可选）

```bash
git tag v1.0.0 && git push origin v1.0.0
```

会自动创建 GitHub Release 并附 APK 下载链接。

---

## 路线 B · iOS 构建（需要本机 macOS 14+ 与 Xcode 15+）

iOS 没法走 GitHub Actions 免费档（需要 macOS runner，免费时长极少），且 Apple 强制要 Xcode + 签名证书。

> 等用户升级 Mac 系统并装好 Xcode 后：

```bash
cd recall_app_mobile
flutter pub get
cd ios && pod install && cd ..

# 模拟器跑：
flutter run -d <simulator-id>

# 装到自己 iPhone（免费 Apple ID 即可，7 天有效）：
open ios/Runner.xcworkspace
# 在 Xcode 里 Signing & Capabilities → Team 选自己的 Apple ID
# 接上 iPhone → 点 Run

# 出 .ipa（需要付费 Developer 账号）：
flutter build ipa --release
# 产物：build/ios/ipa/Recall.ipa
```

---

## 路线 C · 本地直接出包（如果你升级了 macOS）

### Android（需要 JDK 17 + Android SDK）

```bash
brew install --cask zulu17 android-commandlinetools
sdkmanager "platforms;android-34" "build-tools;34.0.0"

cd recall_app_mobile
flutter pub get
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

### iOS（需要 Xcode 15+）

见路线 B。

---

## 设计与功能要点

**与 web 端 v3.7.2 完全打通：**

- 同一套自助账号体系（CloudBase user-api/auth/login）—— web 端注册的账号在 app 直接能登
- 同一套云函数（items-api / search-api / llm-proxy / user-api）
- 同一套数据 schema（items / categories / tags）

**四屏视觉稿对应的页面：**

| 视觉稿 | 实现页面 | 路径 |
|-------|---------|------|
| 启动引导 | OnboardingPage | `lib/presentation/pages/onboarding_page.dart` |
| 时间线 | TimelinePage | `.../timeline_page.dart` |
| 主题/领域聚合 | TopicsPage | `.../topics_page.dart` |
| 搜索 | SearchPage | `.../search_page.dart` |
| 我的 | SettingsPage | `.../settings_page.dart` |
| 详情 | ItemDetailPage | `.../item_detail_page.dart` |
| 添加 | AddPage | `.../add_page.dart` |
| 登录 | LoginPage | `.../login_page.dart` |

**状态管理：** Riverpod（StateNotifier + Provider.family）
**网络：** Dio，统一 ApiClient 注入 userInfo
**鉴权：** 自助账号会话存 SharedPreferences，启动恢复

---

## 已知约束 / 后续工作

- [ ] APK 当前用 debug 签名 → 上线前需要换正式 keystore（写入 `android/app/build.gradle` 的 signingConfigs）
- [ ] iOS 需要 Apple Developer 账号才能产生分发包
- [ ] 当前 url-fetcher / ocr-worker / recall-copilot 云函数尚未在网关暴露（目前 app 端不直接调用，登录、CRUD、搜索已够用）
- [ ] 应用图标用的是默认图标，发布前可换

---

## 故障排查

**Q：CI 失败，提示 `Flutter SDK not found`**
A：workflow 用的是 subosito/flutter-action@v2，会自动下载 Flutter 3.16.9 stable，几乎不会失败。如果失败重跑一次。

**Q：登录提示"网络异常"**
A：检查云函数 HTTP 网关已开（已在 deploy 时通过 MCP 自动开通）。在浏览器访问 `https://jarkko-cloud-01-d4f8nqwdcddd2c9c.service.tcloudbase.com/user-api` 应返回 4xx 而非 404。

**Q：APK 装到手机后启动闪退**
A：抓 logcat：`adb logcat | grep -i recall`，最常见是 minSdkVersion 不匹配（已设为 21，覆盖 Android 5.0+）。
