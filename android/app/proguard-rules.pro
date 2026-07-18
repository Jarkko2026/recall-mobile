# Flutter 默认 ProGuard 规则
# Flutter 编译产物已自带 R8 友好配置，这里只补保守保留规则

# 保留 Flutter 引擎入口
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# 保留 native 平台桥接代码
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 保留所有 native 方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留 Parcelable 序列化
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# 保留枚举 values/valueOf
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留 Dart 调用入口（Flutter 反射访问 Java 类）
-keep class io.flutter.plugins.** { *; }

# 忽略 Google Play Core 缺失类警告
# Flutter 引擎引用 Play Core（用于 Play Store deferred component），但项目未加该依赖
# release 模式 R8 严格检查会报 Missing class，加 -dontwarn 跳过
-dontwarn com.google.android.play.core.**
