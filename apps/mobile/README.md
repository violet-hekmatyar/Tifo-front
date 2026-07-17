# 南看台 Flutter 移动端

项目名 `tifo`，Android applicationId 与 iOS bundle identifier 均为 `com.southstand.tifo`。F03 使用 Dio、Riverpod、go_router 与 `flutter_secure_storage`，完成注册、登录、登录态恢复、首次偏好选择和本地退出。后端当前只有 Access Token，没有 Refresh Token；不保存密码或完整响应。

## 本机真实后端

在前端仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\ensure-local-backend-f03.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\windows\status-local-backend-f03.ps1
```

Android 模拟器通过 `10.0.2.2` 访问 Windows 宿主机：

```powershell
flutter run -d Pixel_8_API_36 `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

登录页、注册页与 onboarding 页面使用真实数据；完成后进入的页面只是 F03 临时完成页，F04 才开发主框架与首页。

## 测试与验收

```powershell
flutter test
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\scripts\windows\check-mobile-f03.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ..\..\scripts\windows\smoke-mobile-auth-f03.ps1
```

默认 `flutter test` 只运行 Mock/Widget 测试；真实 smoke 使用独立 `test_local_backend`，会创建唯一命名测试用户且不重置数据库。Windows 不执行 iOS build。
