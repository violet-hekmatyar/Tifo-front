# tifo（南看台）全面缺口梳理 — 对照原型图 + 需求文档

> 日期：2026-10-08
> 前端仓库：`D:\Football-APP-Front`（Flutter，`apps/mobile`）
> 后端仓库：`D:\Football-APP`（Spring Boot，`com.southstand`）
> 原型图：`C:\Users\hekmatyar\Desktop\足球APP\`（60 张）
> 需求文档：`tifo需求文档.pdf`，43 页 → 已抽取为 `tmp/tifo_req/req.txt`，逐页渲染图 `tmp/tifo_req/pages/p01..p43.png`

---

## 0. 判定口径（按你的要求严格执行）

- **缺口** = 原型图 **和** 需求文档**都**明确提出，且当前未实现（或仅部分实现）。
- 只有一方提到 → 进 **§3 待讨论**。
- 已实现但与原型/文档不一致 → 进 **§4 偏差**。
- 未能核实到的 → 进 **§6 未核验**，不冒充结论。

---

## 1. 三条必须先看的结论

### 1.1 「浏览记录」不在需求文档里 → 不实现

- 需求文档全文 grep：**`浏览记录` 出现 0 次**。
- 原型侧：`我的-首页.png` 里它是**三个胶囊按钮之一**，原型目录中**没有独立的「浏览记录」页面原型**（60 张里无此文件）。
- 后端：无任何浏览历史接口。

→ 按你的口径，**不作为缺口，本期不实现**，已列入 §3 待讨论。

### 1.2 你上一轮点名的那批（编辑资料/用户名/头像/改手机号/改密码/注销/设置页）**也都不在需求文档里**

需求文档全文逐词 grep 结果：

| 关键词 | 文档中出现次数 |
|---|---|
| 账号 | 0 |
| 密码 | 0 |
| 注销 | 0 |
| 手机 | 0 |
| 用户名 | 0 |
| 编辑资料 | 0 |
| 通用 / 通知 / 语言 / 隐私 / 反馈 / 缓存 | 0 / 0 / 0 / 0 / 0 / 0 |
| 浏览记录 | 0 |
| 设置 | 2（均为「用户**设置**的主队」「**设置**三个项目」） |
| 头像 | 7（均为展示位：用户头像 / 球员头像 / 裁判头像，无「修改头像」） |
| 昵称 | 1（资讯卡片展示字段） |

「设置」章节在文档中**完全不存在**——文档的「我的」章只有第 38–41 页，内容是五个 tab、看台、粉丝关注三态、其他用户主页对比，**没有任何关于设置页/账号安全的描述**。

→ 按你的口径，**这批应进 §3 待讨论**，而不是缺口。但它们对应的原型页（`我的-设置.png`、`我的-设置-账号与安全.png`）是**明确画出来的**，且你在第一轮明确说「应该支持」。**这是需要你拍板的口径问题**，见 §5.1。

### 1.3 反过来，文档明确写了、我们也确实没实现的硬缺口有 7 项

见 §2，其中 **G1 淘汰赛分组树**、**G4 队内榜单解围/抢断**、**G5 最多关注 5 个球队** 三项是文档里写得很硬、当前完全没做的。

---

## 2. 缺口（原型 + 需求文档都要求，未实现 / 仅部分实现）

| # | 需求点 | 需求文档出处 | 原型 | 现状证据 | 具体缺失 | 归属 |
|---|---|---|---|---|---|---|
| **G1** | 杯赛/欧冠积分榜顶部三级 tab 的「总览」＝传统淘汰赛分组树（一颗淘汰赛树） | p13：「这里顶部三级tab有一个"总览"，用于传统方式显示完整的淘汰赛信息【一颗淘汰赛分组树】」「所以这里考虑采用两种展示形式，需要ui着重设计一下」 | `数据-欧冠-积分榜总览.png` | `app/router/app_router.dart:369` → `KnockoutTreePlaceholderPage`（`features/football/presentation/pages/knockout_tree_placeholder_page.dart`，**占位页**） | 分组树整体未实现；需后端提供对阵树数据 | **前端**（+后端 bracket 数据） |
| **G2** | 数据 tab 的**赛季下拉选择**（如 23-24） | p11：「赛季下拉选择 （23-24）」「所有类型赛事的赛程展示规则一致」 | `数据-西甲-赛程.png` | `features/football/presentation/controllers/football_rankings_controller.dart:144-145` 自动取 `seasons.where(current).first`，**无用户可选 UI** | 赛季切换器 | **前端**（后端 `seasons()` 接口已存在） |
| **G3** | 比赛详情「评分」tab 的三切换 **主队 / 客队 / 其他**，其中「其他」＝**主裁判评分入口**；无选择时默认主队 | p28：「评分tab分别可以切换"主队"，"客队"，"其他"」「"其他"用于展示主裁判的评分入口」「无选择时默认选择主队球员评分」 | `比赛详情-评分.png` | `features/football/presentation/pages/match_detail_page.dart:1922-1945` 只有「全部 + 各球队」ChoiceChip；**全仓库 grep `裁判`/`referee` 无任何匹配**（前端与后端都没有） | 三态切换语义、主裁判评分入口、裁判实体与评分接口 | **前后端都需** |
| **G4** | 球队总览「队内榜单」五类：**射手榜、助攻榜、评分、解围、抢断** | p18：「展示榜单类型包括五类：射手榜，助攻榜，评分，解围，抢断」 | `球队详情-总览.png` | 后端 `football/detail/service/FootballDetailService.java:282-289` 只返回 4 类：`GOALS 射手榜 / ASSISTS 助攻榜 / APPEARANCES 出场榜 / RATING 评分榜`；**全后端无 `clearance`（解围）字段**，球员数据模型只有 `tackles/interceptions`；前端 `team_detail_page.dart:604` 还额外只 `leaderboards.take(2)` | 解围榜、抢断榜；「出场榜」为文档外多余项；前端展示条数 | **后端为主**（数据+榜单）+ 前端 |
| **G5** | 「每个用户**至多关注五个球队**，超出无法关注并弹窗提示」；已关注时按钮变「已关注」 | p16 | `球队详情-总览.png` | 前端 `features/**` grep 无任何关注上限代码；后端 `follow` 包 grep 无 `max/limit/上限/至多/最多`。**前后端都没有这条规则** | 上限校验（后端强制）+ 越限弹窗（前端） | **前后端都需**（后端必须兜底） |
| **G6** | 资讯卡片需显示「**帖子**」角标，让用户在预览界面区分帖子/文章 | p2：「帖子的资讯卡片需要显示"帖子"角标，帮助用户区在预览界面就可以分帖子或是文章」 | `首页.png` | `features/feed/presentation/**` 中 grep `帖子` **0 匹配**（卡片里只有「转会快讯」角标，`content_card.dart:102`） | 帖子角标 | **前端** |
| **G7** | 首启「我的主队」应可选到大联赛球队（现有德甲球队不能作为主队的反例） | p1：主队决定主页/头像展示并驱动推荐；p2 明确 App 覆盖 欧冠/德甲/法甲/意甲/西甲/英超/中超/沙特联/美职联 | `选择主队.png`（原型示例为**西甲**球队「巴塞罗那／西班牙甲级足球联赛」） | 实测 `GET /api/app/onboarding/options` 只返回 6 支球队且全部 `leagueName=德甲`（teamId 1..6） | 后端 options 数据源 | **后端**（详见 §7） |

---

## 3. 待讨论（只有原型 或 只有文档）

| # | 需求点 | 来源 | 现状 | 建议 |
|---|---|---|---|---|
| D1 | **浏览记录**（我的页三个按钮之一） | **仅原型**（`我的-首页.png` 一个按钮；无独立页面原型）；文档 0 次 | 无页面、无入口、无接口 | **不做**（§1.1） |
| D2 | **设置页**四项：账号与安全 / 通用设置 / 通知设置 / 语言设置 + 退出登录 | **仅原型**（`我的-设置.png`）；文档 0 次 | 布局已与原型一致；通用/通知/语言＝SnackBar「暂未开放」（`settings_pages.dart:116-133`） | 需拍板：按你的第一轮要求 → 升级为缺口；按文档口径 → 只保留布局 |
| D3 | **账号与安全**：手机号（`+86 185****9583`）/ 修改密码 / 注销账号 | **仅原型**（`我的-设置-账号与安全.png`）；文档 0 次 | 三项全部 SnackBar「暂未开放」（`settings_pages.dart:207-222`）；后端无接口 | 同上；严格按文档则不做 |
| D4 | **编辑资料**：用户名、头像、昵称、简介的修改 | **仅原型无**（原型目录**没有**编辑资料页）；文档 0 次；但你的第一轮要求明确 | 现有页只支持 昵称+简介；头像控制器与接口齐备但**无 UI 引用** | 需拍板。头像部分成本极低（纯前端挂 UI），建议做 |
| D5 | **短信验证码登录**（`其他手机登录` 三张原型） | **仅原型**；文档 0 次 | 只有用户名+密码登录（`login_page.dart:137-154`） | 与 D3 手机号换绑共用短信底座，需产品决策通道 |
| D6 | **私信 IM**（会话列表 + 聊天页，可发文字/图片/表情） | **仅原型**（`消息.png`、`消息-对话框.png`）；文档「消息：」后**无任何正文**（p42-43） | `notifications_page.dart:72-79` 只有两个占位 tooltip（「私信搜索」「私信相关功能」→ 暂未开放）；后端无私信表/接口 | 文档未提，建议本期不做；若要做得先补需求 |
| D7 | 消息页右上角 **搜索 / 筛选** 图标 | 仅原型（`消息.png`） | 占位，暂未开放 | 随 D6 一起决策 |
| D8 | 球员**卡片化/球星卡**展示 | **仅文档**，且是疑问句：p23「ui备注：不知道有没有可能去尝试下球员卡片展示的形式…龙霄可以评估一下」 | 当前为列表展示 | 属「评估项」非需求，不做 |
| D9 | 转会资料库入口 | **仅文档**，p72「后续这部分可以做成…」明确是后期 | 首页有转会快讯卡片，无资料库入口 | 后期 |
| D10 | 全场集锦视频（嵌入 B 站/微博视频） | **仅文档**，p32「这块也只是目前的想法…可以考虑合作下」 | `match_detail_page.dart:627` 有「比赛集锦」区块 | 已有占位/区块，是否接真实视频源需决策 |
| D11 | 「关注」tab 冷启动穿插高热度博主内容做引导 | 文档 p2，但注明「这块的判断标准主要靠琛清那边详细制定了」 | 关注流为空时显示「关注流暂时为空」（`home_feed_page.dart:526`） | 规则未定，待算法侧 |
| D12 | 「数据-重要」tab 的重要比赛判定规则 | 文档 p10「展示规则判断/人为判断重要的比赛…此处规则待确定」 | `football_data_page.dart:477` 已区分「关注球队赛程」/「重要比赛」 | 规则待定 |
| D13 | 首页「热门赛事」联赛快捷位（欧冠/德甲/法甲/意甲/西甲/英超/中超/沙特联/美职联） | 文档 p2 提及，但现有首页是 推荐/资讯/关注/我关注的球队 + 联赛分类（数据页） | 首页有 `FeedFilter.recommend/news/following` + `followed_team_bar` | 需确认是否要单独的热门赛事快捷位 |

---

## 4. 已实现但与原型/文档有偏差

| # | 需求点 | 原型/文档要求 | 现状 | 影响 |
|---|---|---|---|---|
| P1 | 我的页三个胶囊按钮 | 原型＝浏览记录 / 我的关注 / 我的粉丝 | 实现＝**编辑资料** / 我的关注 / 我的粉丝（`my_profile_page.dart:85-101`） | 见 §5.2 |
| P2 | 我的关注 / 我的粉丝 | 原型是**两个独立页面**（`我的-我的关注.png`、`我的-我的粉丝.png`） | 两个按钮**跳同一个路由** `/users/me/relations`（`my_profile_page.dart:94,99`） | 需确认是否可接受 |
| P3 | 关注关系按钮文案 | 原型三态：**已关注 / 互相关注 / 回关** | 实现：`FOLLOWED_BY→回关`、`FOLLOWING→取消关注`、默认`→关注`（`public_user_page.dart:223-226`），**无「互相关注」态** | 与文档 p40 不一致；确认弹窗已实现 ✓ |
| P4 | 评分 tab 三切换 | 主队 / 客队 / **其他（主裁判）** | 全部 + 各球队（`match_detail_page.dart:1922-1945`） | 同 G3 |
| P5 | 队内榜单条数 | 五类 | 前端只展示 2 条（`team_detail_page.dart:604` `take(2)`） | 同 G4 |
| P6 | 比赛详情排名 tab 名称 | 文档/原型＝「排名」 | 实现＝「当前排名」（`match_detail_page.dart:334`） | 文案微差 |
| P7 | 球员详情 tab | 文档 p24＝总览/帖子/数据/赛程（比赛）/生涯 | 实现＝总览/帖子/数据/(第4项)/生涯（`player_detail_page.dart:120-124`） | 已含生涯 tab ✓，「已退役」以「身份」字段展示（`:482`）✓ |

---

## 5. 需要你拍板的决策点

### 5.1 【最重要】口径：文档没写但原型画了的功能，算不算缺口？

严格按你给的口径，**D2 设置页 / D3 账号与安全（改手机号、改密码、注销账号）/ D4 编辑资料（用户名、头像）/ D5 短信登录** 都应进「待讨论」而不是缺口——因为需求文档全文 0 次提及。

但你在第一轮明确要求「编辑资料中用户名、头像应该支持修改；修改手机号和密码、注销账号都应该支持」。两者冲突，需要你选：

- **口径 A（严格）**：只做 §2 的 7 项缺口，D2–D5 暂不做。
- **口径 B（原型优先）**：把 D2/D3/D4 一并升级为缺口照做（D5 短信登录成本最高，建议单独排期）。

我倾向 **B**：这些页面原型已经画得很明确（`我的-设置.png`、`我的-设置-账号与安全.png` 是完整可点设计），且属于账号体系基本功；但工作量大头在后端（短信通道、注销数据处置策略），需要你确认。

### 5.2 编辑资料入口

原型我的页里**没有**「编辑资料」按钮，但有「浏览记录」。按原型，编辑资料应收到**点头像**进入。是否按原型调整？

### 5.3 其余
1. **注销账号的数据处置**：软删 / 匿名化 / 物理删除？（决定后端工作量级）
2. **短信通道**：哪家服务商？开发期能否先用固定测试码？（否则 D3/D5 无法联调）
3. **改密后是否强制下线**：当前无 token 吊销机制，要做需引入黑名单或 token 版本号。
4. **后端源码约束**：`PROJECT_HANDOFF_KIMI.md` §4.2 原约束为「不修改后端源码」，且把「注销修改密码」列为本期排除项。G3/G4/G5/G7 与 D2–D5 **都必须改后端**，这条约束需要正式解除。

---

## 6. 未核验（本轮未取得证据，不写入结论）

时间/额度所限，以下项未逐一核验，列出以便后续补测：

1. 「数据-重要」冷启动是否默认定位到最近一场比赛、当前日期是否置顶（文档 p10）。
2. 资讯卡片图片比例上下限裁切、标题是否严格两行（文档 p2）。
3. 首页讨论卡片 / 热门评论卡片 / 排名卡片 / 赛后球员评分卡片的实际渲染细节。
4. 比赛详情「阵容」tab 的球场阵型图与文档描述一致性。
5. 球员详情「数据」tab 的 总计/场均 二级筛选与顶部 6 项基础数据（文档 p26-27）。
6. 球队详情「数据」tab 的 一级赛季赛事 + 二级 总计/场均 筛选。
7. 首页「推荐」tab 的卡片混排比例与主队/关注球队/关注球员权重（文档 p2）。

已核验为**已实现**的主要项（供对照）：评论二级回复 + 评论点赞 + 热门/最新排序（后端 `CommentService.sortHot` 实现了文档的热度分=点赞×1+回复×2 与时间衰减公式）、发布帖子/文章双形态 + 图片横滑 + 话题/热点事件关联、首页 推荐/资讯/关注 + 我关注的球队、7 类卡片（content/match/hotComment/discussion/ranking/playerRating/transferBrief 全部有渲染分支）、比赛详情 5 tab（战报/集锦/简要统计/事件线/阵容/统计）、球员详情 5 tab 含生涯（球队/赛季双维度、国家队）、球队详情 5 tab、其他用户主页 3 tab、关注三态按钮与确认弹窗、互动消息通知。

---

## 7. G7 深挖：主队选择只出德甲的实测根因（纯后端）

### 7.1 复现证据

新注册账号取得 token 后调用 `GET /api/app/onboarding/options`：

```json
{"code":0,"data":{
  "recommendedTeams":[{"teamId":1,"teamName":"1. FC Köln","leagueName":"德甲","country":"Germany"},
                      {"teamId":2,"teamName":"TSG 1899 Hoffenheim",...},
                      {"teamId":3,"teamName":"Bayer 04 Leverkusen",...},
                      {"teamId":4,"teamName":"Borussia Dortmund",...},
                      {"teamId":5,"teamName":"FC Bayern München",...},
                      {"teamId":6,"teamName":"FC Schalke 04",...}],
  "hotTeams":[ ...与 recommendedTeams 完全相同的 6 条... ]}}
```

- 只有 **6 支**，且**全部 `leagueName=德甲`**；`teamId` 恰为 `1..6`（football-data.org 的德甲 id 段）。
- 对照：`GET /api/app/football/leagues` 实际有 8 个联赛；`GET /api/app/football/teams/81` 能取到西甲的 FC Barcelona；`GET /api/app/search/entities?keyword=Real&entityType=TEAM` 能返回 Real Madrid CF 等跨联赛球队。

### 7.2 根因

`D:\Football-APP\src\main\java\com\southstand\onboarding\service\OnboardingService.java`

```java
private static final int OPTION_LIMIT = 6;            // ← 硬上限 6 条

List<FootballTeam> teams = footballTeamMapper.selectList(new LambdaQueryWrapper<FootballTeam>()
        .eq(FootballTeam::getStatus, STATUS_ACTIVE)
        .eq(FootballTeam::getIsDeleted, 0)
        .orderByDesc(FootballTeam::getFollowerCount)   // ← 种子数据 follower_count 全为 0 → 该排序失效
        .orderByAsc(FootballTeam::getId)               // ← 退化成按 id 升序
        .last("LIMIT " + OPTION_LIMIT));               // ← 取前 6 条 = football-data.org id 1..6 = 德甲 6 队

vo.setRecommendedTeams(teamOptions);
vo.setHotTeams(teamOptions);                           // ← 两栏同一份数据
```

**与前端无关**：前端 `onboarding_page.dart` 只是把后端返回值全量展示，其搜索框（`:426-434`）也只在这 6 条里做本地过滤，所以搜「巴塞罗那」永远为空。

### 7.3 同文件的次要缺陷

```java
private String guessLeagueName(FootballTeam team) {
    if ("Spain".equals(team.getCountry()))   return "西甲";
    if ("England".equals(team.getCountry())) return "英超";
    if ("Germany".equals(team.getCountry())) return "德甲";
    return "";                                // ← 意甲/法甲/欧冠球队联赛名为空
}
```

且用 `country` 猜联赛，而 `FootballTeam` 本已关联联赛表，属重复且不完整的实现。

### 7.4 修复方向（后端）

1. 去掉「单联赛退化」：按联赛分组各取 N 支（大五联赛各 6 支），或放大 `LIMIT` 至 60–100；
2. `recommendedTeams` 与 `hotTeams` 若要区分，需两套规则，否则前端应只用一个字段；
3. `guessLeagueName` 补齐 `Italy→意甲`、`France→法甲`，或直接 join 联赛表取 `league_name`；
4. 给种子数据填充差异化 `follower_count`，否则「热度」排序永远等于 id 排序；
5. 可选：前端把「搜索球队」改为调用已存在的 `GET /api/app/search/entities?entityType=TEAM`，实现真正的全库搜索（实测可用）。

---

## 8. 实施顺序建议

**P0 — 纯前端，零后端改动**
1. G6 资讯卡片「帖子」角标。
2. G2 数据 tab 赛季下拉（后端 `seasons()` 已就绪）。
3. D4 头像修改 UI 接入（`avatarUpdateControllerProvider` 已实现、接口已就绪，只差挂 UI）。

**P1 — 后端小改 + 前端半页**
4. **G7 主队选择只出德甲**（后端 1 处查询 + 1 个函数，收益最大）。
5. **G5 最多关注 5 个球队**（后端校验 + 前端弹窗）。
6. **G4 队内榜单五类**（后端补解围/抢断数据与榜单；若数据源无解围字段则需先补字段）。
7. G3 主裁判评分入口（需先定义裁判实体与评分接口契约）。
8. G1 淘汰赛分组树（工作量最大，需后端 bracket 接口 + 前端树形组件；文档也承认「需要 ui 着重设计」）。

**P2 — 待 §5.1 口径拍板后再排**
9. D2/D3 设置页与账号与安全（改密码 → 换绑手机 → 注销，依次依赖短信底座与数据处置策略）。
10. D5 短信验证码登录。
11. D6/D7 私信 IM（文档未提，建议先补需求或明确不做）。

---

## 9. 证据索引

| 结论 | 证据 |
|---|---|
| 需求文档无「浏览记录/账号/密码/注销/手机/用户名/编辑资料/设置页」 | `tmp/tifo_req/req.txt` 逐词 grep 计数（见 §1.2 表） |
| 淘汰赛总览为占位页 | `apps/mobile/lib/app/router/app_router.dart:369`；`features/football/presentation/pages/knockout_tree_placeholder_page.dart` |
| 无赛季下拉 | `features/football/presentation/controllers/football_rankings_controller.dart:144-145` |
| 无主裁判评分 | `features/football/presentation/pages/match_detail_page.dart:1922-1945`；全仓库 grep `裁判`/`referee` 0 匹配 |
| 队内榜单只 4 类且无解围字段 | `D:\Football-APP\...\football\detail\service\FootballDetailService.java:282-289`；全后端 grep `clearance` 0 匹配 |
| 队内榜单前端只展示 2 条 | `features/football/presentation/pages/team_detail_page.dart:604` |
| 无关注上限 5 队 | 前端 `features/**` 与后端 `follow/**` grep 均无匹配 |
| 资讯卡片无「帖子」角标 | `features/feed/presentation/**` grep `帖子` 0 匹配 |
| 主队只出德甲 | 实测 `GET /api/app/onboarding/options` 返回 teamId 1..6 全德甲；根因 `OnboardingService.java` `options()` |
| 设置页 3 项为占位 | `features/user_center/presentation/pages/settings_pages.dart:110-133` |
| 账号与安全 3 项为占位 | 同上 `:207-222` |
| 头像控制器无 UI 引用 | `features/user_center/presentation/controllers/user_center_controllers.dart:807-901`；全仓库无 `avatarUpdateControllerProvider` 引用 |
| 私信仅占位 | `features/notification/presentation/notifications_page.dart:72-79` |
| 评论排序公式已实现 | `D:\Football-APP\...\interaction\service\CommentService.java:381-387`、`397`（`calculateHotScore`） |
