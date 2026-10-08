# 南看台部署可行性报告：后端 → 阿里云 8.138.118.219，前端 → 手机 APK

> 日期：2026-10-06
> 结论：**方案可行，但有一个必须解决的阻塞点（Release APK 的明文 HTTP 限制）和若干部署前置条件。**

---

## 1. 结论摘要

| 维度 | 结论 |
|---|---|
| 后端能否部署到阿里云 | ✅ 可以。已有 Linux 部署脚本和文档化的 plain-jar 部署模式，且此前有过成功的阿里云部署记录 |
| 前端能否通过 APK 连接服务器 | ✅ 可以。`API_BASE_URL` 通过 `--dart-define` 在构建时注入，无需改代码 |
| 整体方案是否可行 | ⚠️ **有条件可行** — 必须解决 Release APK 的明文 HTTP 阻塞（见 §4） |

---

## 2. 后端部署可行性

### 2.1 技术栈与产物

- Spring Boot 3.2.4 + Java 17，打包为单一 `south-stand-server.jar`（约 62 MB）
- 已有产物：`D:\Football-APP\target\south-stand-server.jar`
- 运行方式：`java -jar south-stand-server.jar`

### 2.2 服务器依赖

后端启动**硬性依赖** MySQL 8 和 Redis 7，缺一不可：

| 依赖 | 默认地址 | 服务器上需要 |
|---|---|---|
| MySQL 8 | `localhost:3306` | 安装 MySQL 8，导入 `scripts/sql/schema.sql` + 种子数据 |
| Redis 7 | `localhost:6379` | 安装 Redis 7 |

### 2.3 已有部署资产

- `scripts/linux/run-backend.sh` / `stop-backend.sh` / `check-backend.sh` — 现成的 Linux 启停脚本
- `docs/09_DEPLOYMENT_GUIDE.md` — 部署文档（含 Docker/Nginx 模板）
- `tmp/南看台_Linux部署交接记录与后续计划.md` — **此前已有成功的阿里云部署记录**（MySQL/Redis 容器 + jar）

### 2.4 需要配置的环境变量

在服务器上创建 `/opt/south-stand/.env`，覆盖默认值：

```bash
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=8080
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_DATABASE=south_stand
MYSQL_USERNAME=root
MYSQL_PASSWORD=<实际密码>
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
JWT_SECRET=<至少32字节的密钥>
APP_FILE_STORAGE_ROOT=/opt/south-stand/uploads
APP_CORS_ALLOWED_ORIGINS=<前端来源，见 §5>
```

### 2.5 文件上传/下载

- 上传后返回**相对路径**（如 `/api/public/files/123`），客户端自行拼接 Base URL
- 服务器上需设置 `APP_FILE_STORAGE_ROOT=/opt/south-stand/uploads` 确保持久化
- 无硬编码域名，天然适配任意 IP/域名部署

---

## 3. 前端 APK 连接可行性

### 3.1 Base URL 注入机制

`apps/mobile/lib/app/config/app_config.dart`：

```dart
apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
```

构建时注入，无需改代码：

```powershell
flutter build apk --release `
  --dart-define=APP_ENV=production `
  --dart-define=API_BASE_URL=http://8.138.118.219:8080
```

### 3.2 图片/文件 URL 解析

`apps/mobile/lib/core/network/media_url_resolver.dart` 将相对路径解析为 `API_BASE_URL` 的绝对路径，无 host 白名单限制。后端返回相对路径 → 前端拼接 `http://8.138.118.219:8080` → 正常工作。

### 3.3 无硬编码地址

生产代码中无 `localhost` / `127.0.0.1` / `10.0.2.2` 硬编码，所有环境地址均通过 `dart-define` 注入。

---

## 4. 关键阻塞：Release APK 明文 HTTP 限制

### 4.1 问题

`apps/mobile/android/app/src/main/AndroidManifest.xml` **没有** `android:usesCleartextTraffic="true"`。

只有 `src/debug/AndroidManifest.xml` 设置了 `usesCleartextTraffic="true"`。

这意味着：

| 构建类型 | 明文 HTTP 到 `http://8.138.118.219:8080` |
|---|---|
| Debug APK | ✅ 可以（debug manifest 允许） |
| **Release APK** | ❌ **被 Android 9+ 系统阻止** |

项目文档 `docs/08_BUILD_DEPLOYMENT_GUIDE.md` 明确写道：*"正式环境必须使用 HTTPS"*。

### 4.2 解决方案（二选一）

**方案 A：给后端加 HTTPS（推荐，符合项目文档要求）**

- 需要一个域名（不能用裸 IP 签受信证书）
- 在阿里云上配置 Nginx 反向代理 + Let's Encrypt 免费证书
- APK 构建时使用 `--dart-define=API_BASE_URL=https://your-domain.com`
- **优点**：安全、符合项目规范、不需要修改前端代码
- **缺点**：需要购买/配置域名

**方案 B：修改 AndroidManifest 允许明文 HTTP（快速但不安全）**

- 在 `apps/mobile/android/app/src/main/AndroidManifest.xml` 的 `<application>` 标签中加 `android:usesCleartextTraffic="true"`
- **优点**：立即可用，不需要域名
- **缺点**：所有流量明文传输，Token 和数据可被中间人截获；违反项目文档的安全要求

### 4.3 建议

- **短期验证**：用 Debug APK + `http://8.138.118.219:8080` 可以快速验证整条链路
- **正式部署**：必须上 HTTPS（方案 A），这是项目文档的既定要求

---

## 5. 其他需要注意的事项

### 5.1 阿里云安全组

确保阿里云 ECS 安全组**入方向**开放以下端口：

| 端口 | 用途 |
|---|---|
| 22 | SSH 管理 |
| 8080 | 后端 API（或 Nginx 80/443） |
| 80/443 | 如果加 Nginx + HTTPS |

**不要**对外开放 MySQL 3306 和 Redis 6379。

### 5.2 CORS

后端默认 CORS 允许 `localhost:5173` 等开发地址。手机 APK 不经过浏览器，**不受 CORS 限制**。但如果管理后台也要部署，需要将管理后台的实际来源加入 `APP_CORS_ALLOWED_ORIGINS`。

### 5.3 Release 签名

当前 Release 构建使用 Debug 签名（`build.gradle.kts` 中 `signingConfig = signingConfigs.getByName("debug")`）。内部测试可用，但如需分发建议配置正式签名。

### 5.4 管理后台

管理后台（Vue 3 SPA）需要单独构建和托管。如果管理员需要通过浏览器管理后端，需额外部署。手机 APK 方案不涉及管理后台。

### 5.5 数据库初始化

服务器上需要执行：

```bash
mysql -u root -p < scripts/sql/schema.sql
mysql -u root -p south_stand < scripts/sql/seed.sql
# 如需足球数据：
mysql -u root -p south_stand < scripts/sql/seed_football_data_2026.sql
```

---

## 6. 部署步骤概要

```
1. 阿里云 ECS 安装 Java 17、MySQL 8、Redis 7
2. 安全组开放 8080（或 80/443）
3. 导入数据库 schema + 种子数据
4. 上传 south-stand-server.jar 到 /opt/south-stand/backend/
5. 创建 /opt/south-stand/.env 配置环境变量
6. 运行 scripts/linux/run-backend.sh 启动后端
7. 验证：curl http://8.138.118.219:8080/api/public/health
8. 本地构建 APK：
   flutter build apk --release \
     --dart-define=APP_ENV=production \
     --dart-define=API_BASE_URL=http://8.138.118.219:8080
   （Release 需先解决明文 HTTP 问题，或用 debug 构建先验证）
9. 手机安装 APK，验证注册/登录/Feed/数据页
```

---

## 7. 风险评估

| 风险 | 等级 | 说明 |
|---|---|---|
| 明文 HTTP 被 Android 阻止 | 🔴 高 | Release APK 必须解决，见 §4 |
| 裸 IP 无法签 HTTPS 证书 | 🟡 中 | 需要域名才能上 HTTPS |
| 服务器资源不足 | 🟡 中 | MySQL + Redis + JVM 建议至少 2C4G |
| 2GB 足球数据导入耗时 | 🟢 低 | 一次性操作，可后台执行 |
| 无 HTTPS 的安全风险 | 🟡 中 | Token 明文传输，仅适合内网/测试 |

---

## 8. 最终结论

**你的方案（后端部署到阿里云 + 手机安装 APK）是可行的。** 架构设计（dart-define 注入 Base URL、相对文件 URL、无硬编码地址）天然支持这种部署模式。

**必须解决的一件事**：Release APK 的明文 HTTP 限制。要么给后端加 HTTPS（需要域名），要么修改 AndroidManifest 允许明文（仅建议测试用）。

**建议路径**：
1. 先用 Debug APK + HTTP 快速验证整条链路
2. 购买域名 → 配置 Nginx + HTTPS → 构建 Release APK 正式使用
