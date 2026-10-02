# Football App 项目接手简报

> 生成时间：2026-10-02  
> 基于最近读取的 5 条 Codex 线程（共 1,886 条消息）整理  
> 本简报供新接手的 AI/开发者快速了解项目全局、当前阻塞与下一步动作。

---

## 1. 项目结构

项目分为 **前端仓库** 和 **后端仓库** 两个独立目录：

### 1.1 前端仓库：`D:\Football-APP-Front`

| 模块 | 技术栈 | 路径 |
|---|---|---|
| 移动客户端 | Flutter 3.44 + Dart 3.12 + Riverpod + go_router | `apps/mobile/` |
| 管理后台 | Vue 3 + TypeScript + Element Plus | `apps/admin/` |
| 检查/构建脚本 | PowerShell | `scripts/windows/` |
| 验收报告与证据 | Markdown + 截图 | `reports/` |
| 原型对齐 Prompts | Markdown | `reports/prototype-alignment-prompts/` |

### 1.2 后端仓库：`D:\Football-APP`

| 模块 | 技术栈 | 路径 |
|---|---|---|
| 后端服务 | Spring Boot 3.2.4 + Java 17 + Maven + MyBatis-Plus | `src/main/java/com/southstand/` |
| 数据库 | MySQL 8 + Redis 7 | `scripts/sql/` |
| Demo 数据/素材 | Python + SQL | `scripts/data/` |
| 验收脚本 | PowerShell / Linux Shell | `scripts/windows/`、`scripts/linux/` |
| 前端交接文档 | Markdown | `docs/FRONTEND_BACKEND_HANDOFF_V1.md` |

---

## 2. 当前阶段与状态

### 2.1 后端（`D:\Football-APP`）

- **T00 → T17 全部完成**
- 单元测试：**105 项，0 失败，0 跳过**
- 前端交接文档已完成：
  - `docs/FRONTEND_BACKEND_HANDOFF_V1.md`
  - `docs/FRONTEND_BACKEND_QUICKSTART_V1.md`
- 当前状态：**可交接，等待前端联调**

### 2.2 前端（`D:\Football-APP-Front`）

| 阶段 | 状态 | 说明 |
|---|---|---|
| F00 → F18 | 自动测试通过 | 功能实现完成，但人工视觉验收未通过 |
| Round 05D → 14A | 已验收通过 | 在主目录连续迭代并收口 |
| VR5 → VR13 | 已关闭 | 逐页原型视觉对齐完成 |
| **VR14** | **已关闭（2026-10-02）** | 四根页面最终集成经 R1→R4→R4-E1 迭代后通过终验；60 张原型状态：53 通过、7 既定排除、0 未决 |

### 2.3 当前最新事件

- **2026-10-02**：本地前后端意外关闭后已重启验证完毕（后端 health UP、模拟器在线、设备恢复标准参数）。
- **2026-10-02**：VR14 经 R4-E1 终验通过并正式关闭；最终 APK SHA-256：`88dda1628622d07099e44b0203b0ed1257f6ae1b66cbc87fb6a090b105d99be6`。

---

## 3. 关键阻塞点

### 3.1 前后端进程已关闭（已解决）

- 2026-10-02 已按历史记录重启：后端 health 返回 UP，模拟器在线并装入最终 APK，设备恢复 1080×2400 / 420dpi / font scale 1.0。

### 3.2 VR14 视觉复验未关闭（已关闭）

- VR14（首页、数据、我的、消息四根页面最终集成）已于 2026-10-02 通过 Plan 模型终验，见 `reports/VR14_FINAL_ACCEPTANCE_2026-10-02.md`。
- 遗留登记项（不阻塞）：数据页比赛卡轮次字段待后端专项、日期分组排序待产品决策、完整淘汰树为下一阶段独立必做专项。

### 3.3 人工视觉验收与原型仍有差距（已收口）

- 60 张原型最终状态：53 通过、7 既定排除、0 未决；逐项偏差表见 `reports/VR14_R4_FINAL_EVIDENCE/HOME_DATA_DEVIATION_TABLE.md`。

---

## 4. 最近的关键决策和约束

### 4.1 关键决策

1. **严格视觉验收优先**：测试通过 ≠ 阶段通过，必须以同一 APK 的 Android 截图、双栏原型对照、360dp / 140% 字体验证为准。
2. **窄范围返修**：每次只处理复验报告指出的具体阻塞点，不扩大到已通过页面或后端能力。
3. **同一 APK 证据**：所有 Android 截图、对照图必须来自同一个新构建 APK，旧 APK 不能冒充。
4. **构建环境隔离**：Codex 进程内受 Windows JDK `PipeImpl/UnixDomainSockets` loopback 限制，统一改用普通 Windows Terminal / PowerShell 构建 APK。
5. **数据库变更闭环**：演示数据脚本必须执行 **Seed×2 → Rollback → 再 Seed**，并附带 Validator 校验。
6. **真实 API 为王**：首页组合策略、消息通知、数据页状态均以真实后端响应为准，不伪造联系人、会话或转会事实。

### 4.2 明确约束（不得违反）

- **不提交 / 推送 Git**：除非用户明确授权，否则只保留工作区/暂存区改动。
- **不修改后端源码**：后端契约是权威依据，前端只消费契约。
- **不实现排除能力**：手机号验证码、微信登录、私信/IM、Push、注销修改密码等不在本期范围。
- **不新增未授权依赖**：保持现有技术栈和依赖树。
- **不伪造数据或截图**：禁止绿色人工边框、禁止 Ahem 方框字体的 golden 基线、禁止用旧 APK 截图冒充当前版本。

---

## 5. 下一步建议

### 5.1 立即执行（优先级 P0）

1. **重启本地后端**
   - 进入 `D:\Football-APP`
   - 运行 `mvn clean package -DskipTests`（如 jar 缺失或过期）
   - 启动：`java -jar target/*.jar`
   - 验证：`curl http://127.0.0.1:8080/api/public/health`

2. **重启本地前端开发服务**
   - 进入 `D:\Football-APP-Front\apps\mobile`
   - 运行 `flutter pub get`（如依赖有变）
   - 启动：`flutter run --debug --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080`
   - 或针对 Android 模拟器构建验证 APK

3. **验证前后端启动成功**
   - 后端 health 通过
   - 前端 `flutter analyze` 无问题
   - 运行定向 smoke 测试

### 5.2 短期执行（优先级 P1）

4. **继续 VR14 复验**
   - 在 Windows Terminal 重新构建 APK
   - 确保设备参数为 1080×2400 / 420dpi / font scale 1.0
   - 采集标准、360dp、140% 字体及双栏对照证据
   - 提交 Plan 模型复验

5. **补齐视觉偏差表**
   - VR14-R3 执行记录已主动注明“卡片内部逐项偏差表尚未建立，不宣称视觉验收通过”。
   - 建议建立首页/数据/我的/消息四页的逐项偏差表，逐条关闭。

6. **更新交接文档**
   - 将前后端重启步骤、VR14 状态、最新 APK SHA-256 写入 `reports/FRONTEND_UI_ALIGNMENT_HANDOFF.md`

---

## 6. 关键路径、命令、APK/报告位置

### 6.1 关键目录

| 用途 | 路径 |
|---|---|
| 前端仓库 | `D:\Football-APP-Front` |
| 后端仓库 | `D:\Football-APP` |
| Flutter 源码 | `D:\Football-APP-Front\apps\mobile\lib\` |
| 管理后台源码 | `D:\Football-APP-Front\apps\admin\` |
| 后端源码 | `D:\Football-APP\src\main\java\com\southstand\` |
| APK 产物 | `D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk` |
| 前端报告总目录 | `D:\Football-APP-Front\reports\` |
| 后端 SQL/数据 | `D:\Football-APP\scripts\sql\`、`D:\Football-APP\scripts\data\` |

### 6.2 核心文档

| 文档 | 路径 |
|---|---|
| 前端原型对齐总计划 | `D:\Football-APP-Front\reports\PROTOTYPE_DATA_UI_ALIGNMENT_MASTER_PLAN.md` |
| 前端视觉审计矩阵 | `D:\Football-APP-Front\reports\PROTOTYPE_VISUAL_PARITY_AUDIT_2026-09-18.md` |
| 前端 UI 改进状态报告 | `D:\Football-APP-Front\reports\FRONTEND_UI_IMPROVEMENT_STATUS_REPORT.md` |
| 前端 UI 交接文档 | `D:\Football-APP-Front\reports\FRONTEND_UI_ALIGNMENT_HANDOFF.md` |
| 后端前端交接 V1 | `D:\Football-APP\docs\FRONTEND_BACKEND_HANDOFF_V1.md` |
| 后端 Quick Start | `D:\Football-APP\docs\FRONTEND_BACKEND_QUICKSTART_V1.md` |
| VR14-R3 证据 | `D:\Football-APP-Front\reports\VR14_R3_FINAL_EVIDENCE\` |

### 6.3 常用命令

**后端**
```powershell
cd D:\Football-APP
mvn clean package -DskipTests
java -jar target\*.jar
# 验证
curl http://127.0.0.1:8080/api/public/health
```

**前端 Flutter（开发）**
```powershell
cd D:\Football-APP-Front\apps\mobile
flutter pub get
flutter analyze
flutter test
flutter run --debug `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

**前端 Flutter（构建 APK，必须在 Windows Terminal 执行）**
```powershell
cd D:\Football-APP-Front\apps\mobile
flutter build apk --debug --no-pub `
  --dart-define=APP_ENV=development `
  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

**管理后台**
```powershell
cd D:\Football-APP-Front\apps\admin
npm ci
npm run lint:type-check:build
```

**数据库 Demo 数据（非破坏性增量）**
```powershell
cd D:\Football-APP
scripts\windows\init-demo-data.ps1
```

---

## 7. 接手时最需要注意的 5 件事

1. **APK 必须在 Windows Terminal / PowerShell 中构建，不能在 Codex 内构建**  
   Codex 环境存在 Windows JDK `PipeImpl/UnixDomainSockets` loopback 异常，会导致 Gradle 构建失败。养成“构建 APK 就切到普通终端”的习惯。

2. **所有视觉证据必须来自同一个新构建 APK，禁止复用旧截图**  
   Plan 模型会核对 APK SHA-256 和截图时间戳。旧证据即使看起来相似也会被打回。每次复验前重新构建并记录新 APK 哈希。

3. **数据库变更必须闭环：Seed ×2 → Rollback → 再 Seed**  
   Demo 数据脚本必须幂等、可回滚、不误伤非 Demo 数据。Rollback 必须覆盖 media、avatar、content_media、content_block 等全部修改字段。

4. **自动测试通过不等于阶段通过**  
   视觉验收以真实 APK 截图与原型图逐页对照为准。即使 `flutter test` 全绿，`flutter analyze` 无问题，也可能因像素级偏差被复验打回。

5. **严格遵守排除项，不扩大范围**  
   手机号验证码、微信登录、私信/IM、Push、注销/修改密码、后端源码修改都不在本期范围。遇到相关需求先确认用户授权，不要自行实现。

---

## 附录：当前最新 APK 信息

- **SHA-256**：`88dda1628622d07099e44b0203b0ed1257f6ae1b66cbc87fb6a090b105d99be6`
- **路径**：`D:\Football-APP-Front\apps\mobile\build\app\outputs\flutter-apk\app-debug.apk`
- **构建参数**：debug、开发环境、API 指向 `http://10.0.2.2:8080`
- **设备参数**：1080×2400 / 420dpi / font scale 1.0

---

*本简报为静态快照，后续状态变化请及时更新。*
