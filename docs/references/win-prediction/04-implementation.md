# 比赛详情「预测」模块：实现与运行

> 状态：前后端已实现并在本机跑通；2026-11-16 完成 Android 模拟器截图比对。
> 原型与规则来源：`docs/references/win-prediction/01-business-rules.md`、`02-ui-spec.md`。

## 1. 实现范围

- 比赛详情新增第 6 个 Tab「预测」，位置、间距、卡片、底部 CTA 沿用现有设计系统。
- 赛前：球迷共识、我的预测、看台挑战、更多预测、免责声明、`写下我的判断`。
- 判断面板：三项概率滑杆（合计恒为 100）、快捷选项、看台豆 0/10/30/50、提交。
- 赛后：赛后复盘、预测得分、挑战结果、赢在哪里、赛前判断轨迹。
- 后端：详情查询、提交判断、自动结算、返奖/扣豆、钱包流水、共识更新、轨迹记录。
- 数据：以 `match_info` 中已同步的真实比赛结果为种子，不另造一套赛事数据。

## 2. 数据模型

SQL：`D:\Football-APP\scripts\sql\prediction_module.sql`（幂等，可重复执行）。

| 表 | 用途 |
| --- | --- |
| `match_prediction` | 用户对某场比赛的判断、概率、洞察分、挑战豆、结算状态 |
| `match_prediction_consensus` | 每场球迷共识与参与人数 |
| `prediction_wallet` | 用户看台豆余额，首次参与赠送 1,000 |
| `prediction_bean_log` | 投入、锁定、返还、奖励流水 |
| `prediction_trajectory` | 用户自己的赛前判断轨迹 |
| `prediction_market` | 「更多预测」条目 |

种子数据：

- `575370` Real Madrid 4-1 RB Leipzig（真实赛果）：64/22/14、50 豆、洞察分 90、命中、+30 豆，余额 1,030。
- 真实比赛扩展样本（全部为 `match_info` 中的真实赛果，免费预测、stake 0）：
  - `575374` Aston Villa 3-1 Viking：58/24/18 主胜，洞察分 87，命中。
  - `575372` Bayern 2-2 Arsenal：55/25/20 主胜，洞察分 55，未命中。
  - `575368` Como 4-1 Man United：20/25/55 客胜，洞察分 50，未命中。
  - `575367` PSG 4-2 Barcelona：52/24/24 主胜，洞察分 83，命中。
  - `575375` Sporting 2-3 LASK：55/25/20 主胜，洞察分 50，未命中。
  - `575363` Liverpool 4-3 Villarreal：60/22/18 主胜，洞察分 88，命中。
- `700001` Bayern vs Real Madrid（2026-11-25，欧冠）：预置的**演示场**，使用真实球队与赛事，用于展示赛前交互；`remark` 已标注「预测面板演示场：真实球队与赛事」。
- 演示账号：`prediction_demo` / `Prediction123!`（昵称「预测体验官」，余额 1,030）。

## 3. 后端接口

模块目录：`D:\Football-APP\src\main\java\com\southstand\prediction\`。

```
GET  /api/app/football/matches/{matchId}/prediction
POST /api/app/football/matches/{matchId}/prediction
```

POST 请求体：

```json
{"homeProbability":64,"drawProbability":22,"awayProbability":14,"stake":30}
```

- GET 公开；已登录时返回 `myPrediction` / `postMatch`。
- POST 需要登录；概率合计必须 100，`stake` 仅允许 0/10/30/50。
- 同一用户同一场只能提交一次；开赛、结束、取消后不可提交。
- 结算使用 Brier 分：`B = Σ(p_i - y_i)²`、`S = round(100 × (1 - B/2))`。
- 奖励：`floor(stake × min(0.8, max(0, (S-60)/50)))`；命中返还本金 + 奖励，未命中扣除本金。

## 4. 前端接入

- 页面入口：`apps/mobile/lib/features/football/presentation/pages/match_detail_page.dart`
  - `_MatchTabs` 增加 `('match_tab_prediction', '预测', Icons.auto_graph_outlined)`。
  - `IndexedStack` 增加 `PredictionTab(matchId: widget.matchId)`。
- 功能目录：`apps/mobile/lib/features/prediction/`
  - `domain/prediction_models.dart`
  - `data/prediction_api.dart`、`data/prediction_repository.dart`
  - `presentation/widgets/prediction_tab.dart`、`prediction_sheet.dart`
- 颜色 token 增加在 `apps/mobile/lib/shared/design_system/app_colors.dart`：
  `predictionDeepGreen #197C4E`、`predictionGreenText #338C62`、`predictionGreenSoft #E9F9F0`、`predictionOrange #EB5008`、`predictionOrangeSoft #FFF0E4`。

## 5. 本机运行

### 5.1 数据库

```powershell
cmd /c "docker exec -i apihub-mysql mysql -uroot -p123456 --default-character-set=utf8mb4 -D south_stand < D:\Football-APP\scripts\sql\prediction_module.sql"
```

### 5.2 后端

```powershell
cd D:\Football-APP
$env:JAVA_HOME='D:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot'
$env:MYSQL_PASSWORD='123456'
& 'D:\Program Files\apache-maven-3.9.16\bin\mvn.cmd' -q "-Dmaven.test.skip=true" spring-boot:run
```

健康检查：`http://127.0.0.1:8080/api/public/health`。

### 5.3 前端（Android 模拟器）

```powershell
# 启动模拟器（Pixel 8 / API 36）
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd Pixel_8_API_36 -no-snapshot-load -no-boot-anim -no-audio -gpu swiftshader_indirect

# 构建并安装
cd D:\Football-APP-Front\apps\mobile
D:\Flutter\bin\flutter.bat build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-debug.apk
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell am start -n com.southstand.tifo/.MainActivity
```

- Android 模拟器访问宿主机后端使用 `10.0.2.2:8080`，不是 `127.0.0.1`；真机改为电脑局域网 IP。
- 登录 `prediction_demo` / `Prediction123!`。
- 赛前：底部「数据」→「重要」→ `FC Bayern München vs Real Madrid CF`（2026-11-25）→「预测」。
- 赛后：`575370` Real Madrid 4-1 RB Leipzig（2026-10-22）。可从球队页进入；本地截图时临时把 `initialLocation` 指向 `/matches/575370`，验证后已还原为 `/bootstrap`。
- 本次截图在 `Pixel_8_API_36`、1080×2400 / density 420 下获得。

## 6. 验证结果

| 项目 | 结果 |
| --- | --- |
| 后端主代码编译 | 通过（`mvn -q -DskipTests compile`） |
| 单元测试代码 | `PredictionScoreCalculatorTest` 已补；Maven testCompile 仍被仓库既有 `FootballQueryServiceTests` 签名错误阻塞，与本次模块无关 |
| `flutter analyze`（预测 + 比赛详情） | 0 issues |
| Android debug APK 构建 | 通过 |
| 提交判断 | Android 模拟器 UI 实测通过，写入 `match_prediction`，钱包扣减、共识 +1、按钮进入已提交态 |
| 赛前/面板/赛后截图 | 见 `implementation/` |

截图（Android 模拟器 1080×2400，Pixel 8 / density 420）：

- `implementation/01-pre-match.png`
- `implementation/02-prediction-sheet.png`
- `implementation/03-post-match.png`
- `implementation/04-submitted-state.png`

并排比对图在 `implementation/comparisons/`：`01-pre-match-compare.png`、`02-prediction-sheet-compare.png`、`03-post-match-compare.png`（左为蓝湖原型，右为本机实现）。

## 7. 数据查询脚本

`D:\Football-APP\scripts\prediction\query_prediction_data.py`

```powershell
py -3 D:\Football-APP\scripts\prediction\query_prediction_data.py --from 2026-10-15 --to 2026-10-22
py -3 D:\Football-APP\scripts\prediction\query_prediction_data.py --from 2026-10-01 --to 2026-10-31 --format json
```

- 默认最近 30 天；`--from/--to` 支持任意区间，最长 183 天（约 6 个月）。
- 输出比赛、比分、共识、参与人数、预测数、结算数、均分、命中数、投入豆、奖励豆。
- 已验证 2026-10-15~2026-10-22 共 67 场真实比赛，`575370` 返回 90.0 分、命中、投入 50、奖励 30。

## 8. 已知差异与说明

- 球队短名沿用数据源的英文（Bayern / Real Madrid），因此文案为 `Bayern胜`；原型为中文队名。后续可补球队中文短名映射。
- 演示账号余额为 1,030（真实命中 +30 后），原型为 1,000。
- 赛后页没有恢复原型中的 `写下我的判断` 按钮：比赛已结束，按钮不可用；该冲突已记录在 `03-open-questions.md`。
- 真实数据源没有赛前事件/阵容，比赛详情其它 Tab 的空状态属于既有数据限制，与预测模块无关。
- 原型中「收益 50 豆」与「+30 豆」矛盾，本实现采用净奖励 +30 豆，与规则公式一致。
