# 南看台 Flutter 移动端

项目名为 `tifo`，Android applicationId 与 iOS bundle identifier 均为 `com.southstand.tifo`。使用 Flutter 3.44.6 / Dart 3.12.2，支持 Android 与 iOS；不支持 Flutter Web 或 Windows/Linux/macOS 桌面端，也不需要 Visual Studio 桌面开发组件。

F02 已在 F01 骨架上接入 Dio 5.10.0、`APP_ENV` / `API_BASE_URL`、Riverpod 配置与客户端注入、统一响应/分页解析及可测试异常分类。未配置 Base URL 时骨架仍可启动，首次 API 请求会抛出 `ConfigException`。当前不实现 Token、401/403 跳转或任何业务 API。

## 运行与 Hot Reload

```powershell
flutter devices
flutter run -d Pixel_8_API_36 `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
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

F02 自动验收使用 mock adapter，不依赖后端在线：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\scripts\windows\check-mobile-f02.ps1
```
