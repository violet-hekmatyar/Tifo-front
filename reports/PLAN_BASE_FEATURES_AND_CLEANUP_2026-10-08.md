# 实施计划：基础功能补齐 + 「半吊子功能」清理

> 日期：2026-10-08
> 依据：`D:\Football-APP\docs\13_REAL_DATA_FOOTBALL_DATA.md`（真实数据能力）、原型图 60 张、需求文档（辅助）、线上实测
> 前端：`D:\Football-APP-Front\apps\mobile`　后端：`D:\Football-APP`

---

## 0. 判定结论（有证据，非推断）

### 0.1 G1–G4 是否支持

| 缺口 | 数据文档依据 | 判定 | 处置 |
|---|---|---|---|
| **G1** 淘汰赛「总览」分组树 | `match_info` 1403 场（含 9 场半决赛及之后）；`football_competition_stage` 25 个阶段且 `stage_name` 已中文化；每场对阵双方都在 `match_info` 里 | **可支持（简化版）** | 按阶段分组的对阵视图；完整「一颗树」的 bracket 结构接口需新增 |
| **G2** 数据 tab 赛季下拉 | `football_season` 14 行；`/leagues/{id}/seasons` 接口已存在 | **完全支持** | 纯前端实现 |
| **G3** 主裁判评分入口 | 文档无裁判表；§3.2 `football_user_player_rating` 仅演示行；免费套餐不提供裁判数据 | **不支持** | 不做；保持现状（本就没做），不新增入口 |
| **G4** 队内榜单五类 | §3.2 `football_match_player_stat` = 0 行（无抢断/解围）；§3.1 `football_player_competition_stat` 只有 `appearances/goals/assists`，`rating` = 空 | **解围/抢断/评分 不支持** | 榜单改为「有数据的三类」：射手榜 / 助攻榜 / 出场榜 |

### 0.2 文档顺带暴露的「半吊子」现状（实测）

`GET /api/app/football/matches/537966`（英超已结束）：

```
eventList=[]  report=null
lineupsAvailable=false  teamStatsAvailable=false
playerStatsAvailable=false  ratingsAvailable=false
```

`GET /api/app/football/teams/5/overview`（拜仁）：

```
honors=[]            ← 永远空（§3.2 football_team_honor 仅演示行）
city=null            ← 球队信息「地区」永远空
leaderboards=[GOALS, ASSISTS, APPEARANCES, RATING]   ← RATING 无数据
topScorers/topAssists/recentMatches 有数据 ✅
```

→ **比赛详情 5 个 tab 里 4 个永远空白**；球队荣誉模块永远空白；队内榜单含无数据项。这是本项目最大的「半吊子」来源。

### 0.3 后端已提供 capability 标志

`MatchDataService.java:146`：

```java
detail.setLineupsAvailable(!ls.isEmpty());
detail.setTeamStatsAvailable(!ts.isEmpty());
detail.setPlayerStatsAvailable(!ps.isEmpty());
detail.setRatingsAvailable(!rs.isEmpty());
```

**因此「有数据才显示」不需要新增接口**，前端据此隐藏即可，且将来后端同步到阵容数据后 tab 会自动出现。

⚠️ 唯一例外：`ratingsAvailable` 的语义是「**已有**评分行」，用它控隐藏会导致**第一个用户永远无法评分**（鸡生蛋）。评分 tab 必须改用「比赛已结束 + 已知球员」判定。

---

## 1. 工作包

### P0 · 可展示性判定（capability-first，「有数据才显示」）

> 原则：隐藏是为了不留半吊子，且必须**由数据驱动**而非写死，数据补齐后自动恢复。

| 位置 | 条件 | 动作 |
|---|---|---|
| 比赛详情 | `lineupsAvailable == false` | 隐藏「阵容」tab |
| 比赛详情 | `teamStatsAvailable == false && playerStatsAvailable == false` | 隐藏「统计」tab |
| 比赛详情 | `eventList.isEmpty` | 隐藏关键事件时间线模块 |
| 比赛详情 | `report == null` | 隐藏「查看战报」入口（当前已判断，复核） |
| 比赛详情 | `matchStatus == FINISHED` | 显示「评分」tab（**不用 ratingsAvailable**） |
| 球队详情总览 | `honors.isEmpty` | 隐藏「球队荣誉」模块 |
| 球队详情总览 | `city == null` | 不渲染「地区」行 |
| 队内榜单 | 与 P3-G4 合并 | 见下 |

涉及文件：`features/football/presentation/pages/match_detail_page.dart`、`team_detail_page.dart`、`features/football/presentation/controllers/match_detail_controllers.dart`

### P1 · 基础账号功能（前端 + 后端）

> 均无原型页，按现有设置页风格（白卡片列表 + 统一顶部栏 `_SettingsHeader`）开发。

| # | 功能 | 前端 | 后端 |
|---|---|---|---|
| P1-1 | **头像修改** | `edit_profile_page.dart` 加头像点击 + 「更换头像」；接 `avatarUpdateControllerProvider`（`user_center_controllers.dart:807-901` 已实现、当前全仓库无 UI 引用）；`my_profile_page.dart` 头像可点 | **无需改动**（`POST /api/app/files/upload` + `POST /api/app/users/me/avatar` 已就绪） |
| P1-2 | **用户名修改** | 编辑资料加用户名字段（3–64 位、`[A-Za-z0-9_]`、唯一冲突提示）；删除「用户名、角色、主队和头像不在本表单中修改」文案（`edit_profile_page.dart:104-107`） | `UpdateMyProfileRequest` 增加 `username` + 唯一性校验（`sys_user.username`） |
| P1-3 | **修改密码** | 新增 `change_password_page.dart`（原密码/新密码/确认）；账号与安全页接线 | 新增 `PUT /api/app/users/me/password`，BCrypt 校验旧密码后更新 `password_hash` |
| P1-4 | **修改手机号（简单实现，无验证码）** | 新增 `change_phone_page.dart`（显示当前手机号 → 输入新手机号 → 保存） | 新增 `PUT /api/app/users/me/phone`，唯一性校验后更新 `sys_user.phone` |
| P1-5 | **注销账号** | 新增 `delete_account_page.dart`（风险说明 + 二次确认 + 成功后清 token 回登录页） | 新增 `DELETE /api/app/users/me`（处置策略待确认，见 §2.1） |
| P1-6 | 账号与安全页接线 | `settings_pages.dart:207-222` 三个 `_showUnavailable` → 真实路由 | — |
| P1-7 | 退出登录 | 已实现，保持 | — |

### P2 · 设置页收敛

- **保留**：账号与安全、退出登录（原型一致）
- **隐藏**：通用设置、通知设置、语言设置 —— 理由：语言需完整 i18n；通知需新增偏好表 + 服务端过滤；通用设置无定义内容。属「改动大 → 隐藏」。
  - `settings_pages.dart:116-133`
- **删除死路由** `/settings/notifications`（`app_router.dart:218-222` 当前错误指向消息页）
- 结果：设置页 = 账号与安全 + 退出登录（与原型布局风格一致，只是少了 3 个不可用入口）

### P3 · 缺口修正

| # | 内容 | 归属 | 说明 |
|---|---|---|---|
| P3-1 | **G7 主队只出德甲** | 后端 | `OnboardingService.options()`：`follower_count` 全空导致 `orderByDesc` 失效 → 退化为 id 升序 + `LIMIT 6`。改为按联赛分组各取 N 支（大五联赛）或放大 limit；`guessLeagueName()` 补 `Italy→意甲`/`France→法甲`（或 join 联赛表）；`recommendedTeams`/`hotTeams` 拆成两套规则或前端只用一个 |
| P3-2 | **G6 帖子角标** | 前端 | `feed` 卡片加「帖子」角标（`features/feed/presentation/widgets/content_card.dart`） |
| P3-3 | **G2 赛季下拉** | 前端 | 数据 tab 加赛季选择器；`football_rankings_controller.dart:144-145` 当前自动取 current |
| P3-4 | **G4 队内榜单** | 后端 + 前端 | 后端 `FootballDetailService.leaderboards()` 去掉无数据的 `RATING`，保留 射手/助攻/出场；前端 `team_detail_page.dart:604` 的 `take(2)` 改为展示全部返回项 |
| P3-5 | **G1 淘汰赛「总览」** | 前端（+后端可选） | 按 `football_competition_stage` 分组渲染各阶段对阵（当前是 `KnockoutTreePlaceholderPage` 占位页，`app_router.dart:369`）。完整 bracket 结构接口如需另开 |
| P3-6 | G5 关注上限 5 队 | — | **本期不动**（按你的指示） |

### P4 · 开发者用语清理

全仓库 18 处命中，用户可见的 8 处需改写：

| 文件:行 | 现文案 | 建议 |
|---|---|---|
| `home_feed_page.dart:188` | 当前没有可展示的真实内容，下拉或稍后重试。 | 暂时没有内容，下拉刷新试试 |
| `match_detail_page.dart:1950` | 暂无真实评分数据。 | 还没有人评分，来做第一个 |
| `player_detail_page.dart:1695` | 正在读取真实数据… | 加载中… |
| `team_detail_page.dart:1624` | 正在读取真实数据… | 加载中… |
| `global_search_page.dart:283` | 正在查找真实球队、球员、比赛和内容… | 搜索中… |
| `followed_entities_page.dart:92` | 正在读取真实关注关系。 | 加载中… |
| `user_list_page.dart:118` | 正在读取真实数据。 | 加载中… |
| `user_list_page.dart:200` | 这里还没有可展示的真实记录。 | 这里还没有内容 |

另需复查空态文案：`player_detail_page.dart:411,420`（暂无能力值数据 / 暂无球员荣誉数据）、`team_detail_page.dart:780,1178`、`match_detail_page.dart:787`。

### P5 · 隐藏清单（汇总）

| 项 | 现状 | 处置 |
|---|---|---|
| 设置页：通用 / 通知 / 语言 | SnackBar「暂未开放」 | 移除入口 |
| 消息页：私信搜索 / 私信相关功能 | 两个 tooltip SnackBar「暂未开放」（`notifications_page.dart:72-79`） | 移除（私信未实现） |
| 比赛详情：阵容 / 统计 tab、事件、战报 | 永远空 | 按 P0 条件隐藏 |
| 球队荣誉 | 永远空 | 按 P0 条件隐藏 |
| 队内榜单评分榜 | 无数据 | 后端移除 |
| 浏览记录 | 原型有按钮、文档无 | **不实现** |
| 短信验证码登录 | 原型有 3 张、不实现验证码 | 登录页本无入口，无需处理 |
| 我的页「编辑资料」vs 原型「浏览记录」 | 原型三个按钮为 浏览记录/我的关注/我的粉丝 | 保留「编辑资料」（基础功能必须可达），并按原型补头像点击入口；「浏览记录」不做 |

---

## 2. 需要你确认的点

1. **注销账号的数据处置**：软删（`status=DELETED` + `is_deleted=1`，保留内容）/ 匿名化（保留内容但清空昵称头像手机号）/ 物理删除（级联内容、评论、关注）。
2. **手机号简单实现**：是否允许「只输新手机号直接改」，旧手机号也不验证？（无验证码）
3. **设置页三入口**：确认按「隐藏」处理，还是保留占位。（我按你说的「改动大就隐藏」执行隐藏）
4. **比赛详情永远空的 tab**：确认为「隐藏」（推荐，数据补齐后自动恢复），而不是保留空态。
5. **淘汰赛「总览」**：确认做「按阶段分组的对阵视图」（推荐），还是本期先隐藏该入口。
6. **后端源码**：G7 与 P1-2/3/4/5 都必须改后端，确认解除 `PROJECT_HANDOFF_KIMI.md` §4.2 的「不修改后端源码」约束。
7. **演示数据表**（`honors` / 球员生涯 / 战报 / 用户评分）：是否统一按「无真实数据则隐藏」处理。

---

## 3. 验证方式

- 前端：`flutter analyze` + 受影响页面的定向测试 + 模拟器截图（不跑全量套件）。
- 后端：`mvn -Dtest=<受影响测试> test` + 真实接口 curl 复核（如 `onboarding/options` 必须返回多联赛球队；`teams/5/overview` 不得再含 RATING 榜）。
- 端到端：重打 APK 后在模拟器走一遍「注册 → 选主队 → 编辑资料 → 改头像 → 改密码 → 改手机号 → 注销」主链路。
- 每个工作包完成后单独验证并汇报，不批量收口。

---

## 4. 建议执行顺序

```
P0 可展示性判定（消除永远空白）
 → P3-1 G7 主队德甲（后端，影响注册主链路，收益最大）
 → P1 基础账号功能（P1-1 头像最省力，可先做）
 → P3-2/3/4 小缺口
 → P2 设置页收敛
 → P4 开发者用语（可并行）
 → P3-5 淘汰赛总览（工作量最大，最后）
```

阻塞项：§2 的确认点 1/2/6 未定则 P1-4/P1-5 无法开工。
