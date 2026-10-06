# 数据来源报告：哪些是真实数据，哪些还是模拟数据

- 日期：2026-10-06
- 库：`south_stand`（MySQL 8.0.46，容器 `apihub-mysql`）
- 数据源：football-data.org v4 **免费套餐**（10 次/分钟，8 个赛事）
- 采集范围：2026-01-01 ~ 2026-10-01（跨 2025/26 与 2026/27 两个赛季）
- 产物：`D:\Football-APP\scripts\sql\seed_football_data_2026.sql`（1.99 MB）
- 备份：`D:\Football-APP\tmp\backup-south_stand-before-real-data-20261006-1341.sql`
- 校验：`D:\Football-APP\scripts\sql\validate-retired-demo-data.sql`

---

## 0. 结论速览

| 域 | 状态 |
|---|---|
| 足球域：联赛 / 赛季 / 阶段 / 球队 / 球员 / 阵容 / 积分榜 / 射手榜 / 球队榜 / 赛程 | ✅ **真实数据**（football-data.org），演示数据已软删退役 |
| 足球域：比赛事件 / 首发阵容 / 出场统计 / 战报 / 球衣号 / 球员头像 / 身价 / 身高体重 / 比赛场地 | ❌ **没有真实数据**（接口不提供或本次未抓），字段为空 |
| 内容域：帖子 / 文章 / 评论 / 点赞 / 收藏 / 关注 | ⚠️ **全部是模拟数据**（T13/T14/VR 测试夹具生成，仍可见） |
| 用户域：账号 | ⚠️ 385 个测试账号 + 4 个 dev smoke 账号可见；36 个演示账号已停用 |
| 通知 / 行为日志 / 静态素材 | ⚠️ **模拟数据** |
| 图片：球队队徽 = 真实外链；**球员头像 = 本地统一占位图**（真实数据 0 个头像） | 见 §5 的替换方案 |

---

## 1. 已替换为真实数据（足球域）

行数取自 `south_stand` 实测；「演示行」= T14 演示集（≥1.1e16 段）+ `seed.sql` 本地 smoke 小 ID + P1-M2/VR14 夹具。

| 表 | 真实行 | 演示/夹具行 | 演示是否已退役 | 说明 |
|---|---:|---:|---|---|
| `football_league` | **8** | 11 | ✅ 全部软删 | 英超 2021 / 西甲 2014 / 德甲 2002 / 意甲 2019 / 法甲 2015 / 欧冠 2001 / 世界杯 2000 / 欧洲杯 2018 |
| `football_season` | **14** | 22 | ✅ | 5 大联赛 + 欧冠各 2 个赛季（2025/26、2026/27），世界杯 1 个，欧洲杯 1 个（2024） |
| `football_competition_stage` | **25** | 22 | ✅ | 中文阶段名：常规赛 / 联赛阶段 / 小组赛 / 32强 / 附加赛 / 16强 / 8强 / 4强 / 三四名决赛 / 决赛 |
| `football_team` | **192** | 30 | ✅ | 含队徽外链、国家、主场、建队年；85 支有主教练名 |
| `football_player` | **4050** | 286 | 部分（154 已删） | 夹具球员行保留（父行已退役，App 看不到） |
| `team_player` | **4530** | 286 | 部分 | plan 里的阵容表 |
| `football_team_season_player` | **5428** | 490（夹具） | — | **App 球队/球员详情实际读的阵容表** |
| `football_standing` | **312** | 57 | 部分（55 已删） | 只取 TOTAL 表 |
| `football_player_competition_stat` | **1296** | 490 | 部分（358 已删） | 射手榜，每赛季前 100 名 |
| `football_team_competition_stat` | **312** | 57 | 部分 | 由积分榜派生（场次/进球/失球） |
| `match_info` | **1403** | 86 | ✅ | 比赛时间按北京时间写入 |
| `match_event` | **0** | 298 | 部分 | 事件未抓（`--with-events` 成本高） |

**真实行的字段填充率（实测）**

| 字段 | 填充情况 | 原因 |
|---|---|---|
| 球队 `logo_url` | 192 / 192 ✅ | 接口给 football-data 队徽外链 |
| 球队 `founded_year` | 187 / 192 ✅ | 接口有 |
| 球队 `coach_name` | 85 / 192 | 免费套餐里部分赛事返回 `coach.name = null` |
| 球队 `city` / `market_value` | 0 / 192 | 接口不提供 |
| 球员 `avatar_url` | **2937 / 4050（72.5%，2026-10-06 补）** | football-data 不提供照片，改用 TheSportsDB（见 §3）；其余 1113 人用本地首字母头像兜底 |
| 球员 `height_cm` / `weight_kg` / `market_value` / `shirt_number` | 0 / 4050 | 接口不提供 |
| `match_info.venue` | 0 / 1403 | 接口不提供场地 |
| 比赛事件 / 首发 / 出场统计 | 0 | 未抓取（每年约 1400 场 × 1 次请求 ≈ 2.5 小时） |
| 战报 `match_report` | 0（32 行均为演示） | 需自研内容或第三方 |

---

## 2. 仍是模拟数据

### 2.1 内容与互动域（App 里**看得见**）

| 表 | 行数 | 可见 | 来源 |
|---|---:|---:|---|
| `content` | 287 | 283 | T13/T14/VR 测试夹具生成；发布时间 2026-07-03 ~ 2026-09-30 |
| `content_media` | 293 | 239 | 本地 demo 素材（`/demo/contents/*.svg`） |
| `content_block` | 257 | 180 | 同上 |
| `content_relation` | 601 | — | 帖子与球队/球员/比赛的关联（指向演示或真实对象） |
| `comment` | 634 | 602 | 测试账号评论 |
| `like_record` | 1482 | 1438（ACTIVE） | 测试点赞 |
| `favorite_record` | 706 | 705 | 测试收藏 |
| `follow_record` | 926 | 926 | 测试关注 |
| `match_report` | 32 | 32 | 演示战报（关联演示比赛） |
| `football_user_player_rating` | 386 | 384 | 测试玩家评分 |
| `notification` | 62 | 62 | 测试通知 |
| `user_behavior_log` | 10066 | — | 推荐行为日志（测试产生） |
| `content_publish_subject` / `file_resource` / `admin_operation_log` | 12 / 202 / 1 | — | 本地素材与运维记录 |

### 2.2 用户域

| 分组 | 行数 | 可见 | 说明 |
|---|---:|---:|---|
| `test_user_*` / `football_user_*` / `feed_user_*` / `file_user_*` / `storage_user_*` 等雪花 ID 账号 | 385 | ✅ ACTIVE | check-*/smoke-* 脚本创建，会在搜索、作者、评论区出现 |
| T14/T13 演示账号（1.1e16 段） | 36 | ❌ 已停用 | `status=DISABLED, is_deleted=1` |
| `seed.sql` 本地 smoke 账号 10001-10004 | 4 | ✅ ACTIVE | 密码 `password`，**故意保留**（仓库工具链依赖登录） |

### 2.3 未退役的夹具行（App 看不到，因父行已退役）

P1-M2 / VR14 等夹具残留：132 名球员、132 条阵容、2 条积分榜、2 条球队榜、若干比赛事件与评分。
保留原因：`check-t15~t22` 等冒烟脚本依赖它们；其联赛/赛季/球队父行已退役，App 查询自带 `is_deleted=0`，不会显示。

---

## 3. 图片资源现状（2026-10-06 更新：球员头像已换成「真照片优先 + 本地兜底」）

| 类型 | 现状 | 说明 |
|---|---|---|
| 球队队徽（192 支） | 真实外链 | `https://crests.football-data.org/{id}.png`（国家队 `.svg`），未做本地镜像 |
| **球员头像（4050 人）** | **2937 人有真实照片（72.5%）**，其余 1113 人用**本地生成的首字母头像** | 见下方「实施细节」 |
| 内容封面 / 作者头像 | 演示资源 | `/demo/**` 是 classpath 静态资源（可用）；`/uploads/**` **后端没有静态映射**（实测返回 JSON，不是图片） |

### 3.1 实施细节

**真实照片来源：TheSportsDB**（`https://www.thesportsdb.com`）

| 候选来源 | 结论 |
|---|---|
| football-data.org | ❌ 不提供球员照片（`/crests.football-data.org/{id}.png` 全部 404） |
| Wikidata / Wikipedia（P18） | ❌ **国内网络不可达**（`query.wikidata.org` 超时，实测 000） |
| **TheSportsDB（免费 key）** | ✅ 可用：按球队批量取阵容，含 `strCutout`（透明 PNG）、`dateBorn`（生日可校验）、`strCreativeCommons` + 署名 |
| media.api-sports.io / images.fotmob.com | ✅ 图片 CDN 可达，但需要付费/别家的球员 ID 才能定位 |

**工具**：`scripts/data-sync/player_photos.py`（产出 `scripts/sql/update_player_avatars.sql`）

- 第一遍「按球队」：`searchteams` + `lookup_all_players`，192 支球队 ≈ 350 次请求（约 13 分钟）→ **844 人**；
  实测 TheSportsDB 的免费阵容列表**每队只返回 10 人**，所以必须跑第二遍。
- 第二遍「按球员」：`searchplayers?p=<姓名>`，逐人查（3101 人，2.1 秒/次，实跑约 110 分钟）→ **再补 2093 人**，
  合计 **2937 人 / 4050（72.5%）**，另有 319 人在 TheSportsDB 里没有照片字段。
  按「射手榜球员优先」排序，可随时中断、**缓存可续跑**（响应按 URL 落地到 `cache/thesportsdb/`，重跑零请求）。
- 匹配规则（宁缺毋滥）：姓名归一化（去音标/标点，`Kovačić`≡`Kovacic`）必须一致；**双方生日都存在时必须相等**；
  只有单方生日且队内同名唯一时才接受；球队名支持退化搜索（`FC Bayern München` → `Bayern Munich`），
  硬性只接受 `strSport = Soccer`（否则会命中 `Bayern München Basketball`、`Hamburger SV` 冰球队这类同名条目）。
- 图片取 **small 变体**（200×200，39 KB；原图 228 KB），URL 形如
  `.../images/media/player/cutout/small/{file}.png`。详情页圆形头像约 200px → 1:1 清晰；列表 48px 富余。
- **有真图时不挂兜底 + 纯色底**：原结构是 `Stack(兜底, 图片)`，而扣像照片是透明的 → 下面的首字母和彩色底
  会透出来，看起来像「兜底图 + 真图」两张叠着。现在有 `imageUrl` 时只渲染图片、底色用
  `AppColors.surface`（纯白）让照片更醒目；兜底只在**加载中 / 加载失败**时短暂出现。
- **裁剪改为顶部对齐（人脸必须完整）**：图片源优先 `strCutout`（透明底头肩照），实测都是方图、脸在画面上部；
  但卡片（如曼城阵容卡）给的是「宽 > 高」的紧约束，`BoxFit.cover` **居中裁会把头顶切掉**。
  现在 `AppEntityAvatar` 增加 `imageAlignment`，`AppPlayerAvatar` 传 `Alignment.topCenter`
  → 切掉的是下半身，**脸完整露出**（报告截图 13 的前后对比很明显）。
- **图片可用性校验**：生成 SQL 前逐个 URL 校验（HTTP 200 且 `Content-Type: image/*`），坏图直接剔除、
  不留空白框；结果缓存在 `cache/thesportsdb/image_checks.json`。本次 844/844 全部可用。
- **授权留痕**：每条 UPDATE 同时写 `football_player.remark`，例如
  `photo:TheSportsDB idPlayer=34169116 license=Yes credit=By Br…`，便于后续署名核查。

**顺带修掉的队徽缺陷（同一类问题）**：55 支国家队的队徽是 **SVG**
（`crests.football-data.org/770.svg`，CDN 没有 PNG 版本），而 `AppEntityAvatar` 用 `Image.network`
解不了 SVG → App 日志一直报 `Exception: Invalid image data`，这些国家队只能看到**兜底徽标**。
现在头像组件对 `.svg` 走 `SvgPicture.network`（App 里本来就有这个依赖和写法），
世界杯/欧洲杯的国旗全部正常（截图 14）。

**本地兜底头像**（无照片时）：改前端，不再用统一占位图

- `lib/shared/widgets/app_player_avatar.dart`：去掉 `fallbackAsset: neutral-player-avatar.png`，
  改为 `playerInitials(name)`（`Bukayo Saka` → `BS`，`林远航` → `林`）；
- `lib/shared/widgets/app_entity_avatar.dart`：兜底内容包一层 `ExcludeSemantics`，
  保证无障碍标签仍是「姓名 球员头像」（否则首字母会被并进标签）；
- 颜色仍由 `stableEntityColor(identity)` 按 id 稳定生成 → **每个人颜色固定且互不相同**，零图片资源、离线可用。
- 相关测试已同步更新：`test/shared/widgets/p1_media_widgets_test.dart`、
  `test/features/football/f12_football_rankings_widget_test.dart`（均通过）。

### 3.2 模拟器验收（截图见本目录 11~13）

| 截图 | 显示 |
|---|---|
| `11-player-ranks-real-photo-plus-initials.png` | 英超球员榜：哈兰德/伊萨克/若昂·佩德罗/布鲁诺·费尔南德斯/萨卡 = **真实照片**；帕斯卡尔·格罗斯 → `PG`、谢尔基 → `RC`、罗杰斯 → `MR`、塔弗尼耶 → `MT`、布罗贝 → `BB` = **本地首字母头像** |
| `12-player-detail-real-photo.png` | 球员详情页：圆形头像，真实照片、脸部完整（约 1:1 像素），纯白底让照片从品红页头里跳出来 |
| `14-important-svg-crests.png` | 重要 tab：西班牙/法国/英格兰等**国家队国旗（SVG）正常渲染**（修复前是兜底徽标） |
| `13-team-roster-real-photo-plus-initials.png` | 曼城阵容卡：鲁利等 = 真照片、**头部完整**、**纯白底**（修复前头顶被切、且首字母从透明区透出来像两张图叠着）；科瓦契奇 → `MK` 等 = 本地首字母头像（彩色底） |

> 覆盖率说明：第一遍（按球队）只有 844 人，因为 TheSportsDB 免费阵容列表每队只给 10 人；
> 补跑第二遍（按球员搜索，3101 人）后再导入，覆盖率提升到 **2937/4050 = 72.5%**——
> 阵容页里鲁利/科瓦契奇/多纳鲁马/贝蒂内利现在**全部是真照片**，球员榜前 4 名也一样。

---

## 4. 后续可选（提高真实照片覆盖率 / 降低外链依赖）

| 方案 | 说明 | 成本 |
|---|---|---|
| ~~跑完第二遍「按球员搜索」~~ | ✅ 已完成：844 → **2937 人（72.5%）** | 已投入约 2 小时 |
| 付费源 | API-Football / Sportmonks 有球员照片；可用 TheSportsDB 里的 `idAPIfootball` 字段做映射 | 订阅费 |
| 队徽/头像本地镜像 | 把外链图片下载到 `runtime-uploads` + `file_resource`，或 `src/main/resources/static/demo/`（后者需重新打包 jar） | 0.5 天，换离线可用 |
| 进一步美化兜底 | 首字母换成「姓氏首字 + 位置图标」或队徽色底 | 1 小时 |

---

## 5. 验证方式与证据

```sql
-- 演示数据是否清干净（所有 remaining 应为 0）
source D:/Football-APP/scripts/sql/validate-retired-demo-data.sql;
-- App 可见联赛应只剩 8 个真实赛事
SELECT id, league_name FROM football_league WHERE status='ACTIVE' AND is_deleted=0 ORDER BY sort_order, id;
```

接口（后端 `localhost:8080`）：`/api/app/football/leagues`、`/leagues/{id}/seasons`、`/leagues/{id}/seasons/{id}/stages`、
`/standings`、`/player-ranks`、`/team-ranks`、`/matches/important`、`/matches`、`/matches/{id}`、
`/teams/{id}`、`/teams/{id}/players`、`/players/{id}/overview` —— 全部 200 且返回真实数据。

App 截图（本目录）：

| 文件 | 内容 |
|---|---|
| `01-home-real-standings-card.png` | 首页卡片：真实英超积分榜（曼城 15 / 阿森纳 12 / 布莱顿 10） |
| `02-data-5tabs-important.png` | 数据页 5 个 tab（重要/关注/联赛/欧冠/杯赛）+ 2026 世界杯淘汰赛 |
| `03-league-picker.png` | 选择联赛：恰好 5 个真实联赛，无演示重复项 |
| `04-pl-standings.png` | 英超积分榜（真实名次/胜平负/进失球） |
| `05-pl-player-ranks.png` | 球员榜（哈兰德 5、伊萨克 4…）——**头像为统一占位图** |
| `06-pl-fixtures.png` | 英超赛程（埃弗顿 2:4 布伦特福德…） |
| `07-cl-player-ranks.png` | 欧冠射手榜 |
| `08-player-detail.png` | 球员详情（费兰·托雷斯 / PSG） |
| `09-team-detail.png` | 球队详情（曼城：主场 Etihad、成立 1880、队内射手/助攻榜） |
| `10-team-roster.png` | 球队阵容（真实球员名单）——**头像同样为占位图** |

---

## 6. 风险与待办

1. **队徽外链依赖**：192 支球队 + 头像都指向 football-data CDN，建议镜像到本地（§4 方案 A/B 顺带做）。
2. **385 个测试账号仍 ACTIVE**：会出现在搜索/作者/评论区；如要"干净"环境需要停用（`username LIKE 'test_user\_%' OR ...`）。
3. **演示帖子仍在信息流**（内容域未退役）：`retire-demo-data.sql` 里有可选段落说明了注意事项
   （`like_record` / `favorite_record` 没有 `is_deleted` 列，只有 `status`，要置 `CANCELLED`）。
4. **6 个依赖演示 ID 的脚本**（`smoke-demo-data`、`smoke-football-ranks`、`smoke-recommendation`、
   `smoke-backend-v1-final`、`check-demo-encoding`、`benchmark-backend-api`）会缺数据；
   需要时用 `init-demo-data.ps1` 重建，但重建会**再引入演示联赛**，要再跑一次退役脚本。
5. **空字段的来源**：比赛事件/首发/出场统计/战报/球衣号/球员身价身高 → 需要 `--with-events`（约 2.5 小时/年）
   或付费数据源；球员榜只有每赛季前 100 名，所以阵容页里大部分人显示 0 场 0 球。
6. **欧洲杯没有积分榜**（接口对 EC standings 返回 404），只有射手榜，且赛季是 2024。
7. **回滚**：`scripts/sql/retire-demo-data-rollback.sql` 恢复演示数据；整库回滚用 `tmp` 里的 mysqldump。
