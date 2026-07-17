# 南看台 Flutter 移动端

项目名为 `tifo`，Android applicationId 与 iOS bundle identifier 均为 `com.southstand.tifo`。使用 Flutter 3.44.6 / Dart 3.12.2，支持 Android 与 iOS；不支持 Flutter Web 或 Windows/Linux/macOS 桌面端，也不需要 Visual Studio 桌面开发组件。

F01 已接入 Riverpod、go_router、统一主题、根路由、错误 fallback、占位页面和 Widget 测试。尚未实现登录、网络请求、Token、首页或其他业务功能。

## 运行与 Hot Reload

```powershell
flutter devices
flutter run -d <android-device-id>
```

运行中按 `r` 热重载、`R` 热重启、`q` 退出。Android 模拟器/真机、镜像及 SDK 配置见 [本地开发环境](../../docs/12_LOCAL_DEVELOPMENT_ENVIRONMENT.md)。

## 验证与构建

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

iOS 工程已保留，但 Windows 下未执行 iOS build。
