# 缺陷清单 — 南看台 App 用户旅程测试

> 日期：2026-10-08
> 分级：Blocker / Critical / Major / Minor / Enhancement
> 修复策略：**本轮小修**（局部改动，不碰契约与架构） / **后续改进项**（进 `IMPROVEMENTS.md`）
> 证据目录：`reports/USER_JOURNEY_TEST_2026-10-08/shots/`

## 修复状态（2026-10-08 本轮小修已完成并实机验证）

改动文件（全部在 `apps/mobile/lib/`，**未改后端**）：

| 缺陷 | 改动 | 文件 | 验证 |
|---|---|---|---|
| DEF-01 | `ref.invalidate(myProfileControllerProvider)` → `await ref.read(myProfileControllerProvider).refresh()` | `features/football/presentation/pages/team_detail_page.dart` | ✅ 改主队后「我的」页立即显示新主队，无需重启 |
| DEF-02 | `invalidate(mySummaryProvider)` + 显式 `summary()` → `ref.refresh(mySummaryProvider.future)`（去掉冗余那一发） | 同上 | ⚠️ 冗余已消除，但**结构性重复仍在**（两个 provider 同源）→ IMP-03 |
| DEF-03 | `showSearchFilters` 判据补上 `\|\| state.keyword.isNotEmpty` | `features/search/presentation/pages/global_search_page.dart` | ✅ 切到无结果分类后分类栏仍在，可正常切回 |
| DEF-04 | 删除 `_AuthorFollowButton` 里对作者资料加载失败弹 SnackBar 的 `ref.listen` | `features/content/presentation/pages/content_detail_page.dart` | ✅ 内容详情页不再出现「用户或内容不存在。」 |
| DEF-05 | `selectMainTeam` 的 `followTeamIds` 改为「先剔除旧主队再加入新主队」 | `features/onboarding/presentation/controllers/onboarding_controller.dart` | ✅ 选错改选后，第 2 步只有新主队为已关注 |
| OBS-03 | 「加为主队 / 已是主队」按钮增加 `_isMainTeam` 禁用条件 | `features/football/presentation/pages/team_detail_page.dart` | ✅ 已是主队时 `enabled=false clickable=false` |
| 附带 | `myProfileControllerProvider` 改为**创建即加载**（`Future.microtask(controller.load)`） | `features/user_center/presentation/controllers/user_center_controllers.dart` | ✅ 修掉一个既有隐患：`edit_profile_page.dart:77`、`followed_entities_page.dart:68` 也 invalidate 该 provider，原设计下页面会**永久卡在「正在加载个人主页」**（本次实测复现过） |

验证方式：`flutter analyze` 无问题 → 重新构建并 `adb install -r` 覆盖安装 → 逐项在模拟器上复测。

### 第二轮小修（同样已实机验证）

| 缺陷 | 改动 | 文件 | 验证 |
|---|---|---|---|
| DEF-06 | 帖子页标题提示 `'请输入文章标题（20字内）'` → `'请输入标题（20字内）'` | `features/content/presentation/pages/publish_post_page.dart` | ✅ 截图确认提示已一致（`R1_01_publish_hint.png`） |
| DEF-07 | 成功分支的 `context.pop()` 改为 `WidgetsBinding.instance.addPostFrameCallback` 内延迟一帧执行 | `features/user_center/presentation/pages/settings_pages.dart` | ✅ 改号后自动返回账号与安全（改前复现稳定） |
| OBS-05 | `chooseAndUpload()` 的 `busy: true` 从「打开选择器之前」移到「选到图之后」 | `features/user_center/presentation/controllers/user_center_controllers.dart` | ⚠️ 改动已确认；本次系统相册为全屏抽屉遮住按钮，无法视觉复现原现象；取消选择后按钮正常恢复「更换头像」 |

**DEF-07 根因已由对照实验证实**：改密码页成功后 pop **正常**（该页不调 `refreshAfterOnboarding()`），
改手机号页 pop **被吞**（该页调了它 → 触发 `refreshListenable` 的整轮路由重算 → 同帧 pop 丢失）。

---

## 测试环境更正（重要，非 App 缺陷）

`tmp/runtime/f03-backend/` 里的 `backend-start-metadata.json` 与 `backend.stdout.log` **已失效**：
元数据指向 PID 87644（15:11 启动、15:18 后无输出），而 **8080 端口真实在跑的后端是 PID 43784**
（`java -jar D:\Football-APP\target\south-stand-server.jar --server.port=8080`，16:27:46 启动），
其日志在 `D:\Football-APP\backend_kimi.out.log`。

- 影响：按仓库文档排障时会读到过期日志，误判「请求没发出」。本轮已因此浪费一轮排查。
- 处理：**后续改进项**（修 `status-local-backend-f03.ps1` 的 PID/日志发现逻辑，或让 ensure 脚本滚动覆盖元数据）。

---

## DEF-01 改主队后「我的」页不刷新（Major｜本轮小修）

**页面**：球队详情 → 「加为主队」→ 返回「我的」
**操作**：
1. 首次设置选 Arsenal 为主队
2. 球队详情（Chelsea FC）→ 点「加为主队」
3. 返回「我的」页

**实际**：SnackBar 提示「已设为主队」，球队详情页按钮变为「已是主队」；但**「我的」页头像上的主队队徽、以及「我的主队」卡片仍显示 Arsenal**。
**预期**：「我的」页应立即显示 Chelsea。

**证据**：
- 截图 `S1_27_profile_main_team.png`（改后仍为 Arsenal 队徽）
- 后端已确认正确：`GET /api/app/users/me/summary` → `"mainTeam":{"teamId":61,"teamName":"Chelsea FC"}`
- 请求日志：`PUT /api/app/users/me/profile 200 (104ms)` → 随后 `GET /api/app/users/me/summary` ×2
- 重启 App 后恢复正常（截图 `S1_30_after_restart_profile.png` 显示 Chelsea）→ 证明是**客户端缓存未失效**，不是数据错误

**根因**：
「我的」页数据来自 `myProfileControllerProvider`（`MyProfileController`，自带 `state.summary` 缓存，
`load()` 有 `if (_started) return;`），**不是** `mySummaryProvider`。
而 `apps/mobile/lib/features/football/presentation/pages/team_detail_page.dart:212` 的 `_setMainTeam()` 只做了
`ref.invalidate(mySummaryProvider)`，**没有** invalidate `myProfileControllerProvider`。

对照：头像更新流程 `features/user_center/presentation/controllers/user_center_controllers.dart:813-814` 是
**两个都 invalidate** 的，所以头像能刷新、主队不能。

**建议小修**：在 `_setMainTeam()` 成功分支补一行
`ref.invalidate(myProfileControllerProvider);`（与头像更新保持一致）。

**补充观察**：「我的」页**没有下拉刷新**（`my_profile_page.dart` 中无 `RefreshIndicator`），
所以用户只能靠重启 App 才能看到新主队 —— 这一点放大了本缺陷的影响。是否补下拉刷新可作为小修一并考虑。

---

## DEF-02 切换主队后 summary 重复请求（Minor｜本轮小修）

**现象**：`PUT /api/app/users/me/profile` 成功后，`GET /api/app/users/me/summary` 被**连续调用两次**。
**日志**：
```
18:02:46.559  PUT  /api/app/users/me/profile   200  104ms
18:02:46.685  GET  /api/app/users/me/summary   200   34ms
18:02:46.721  GET  /api/app/users/me/summary   200   30ms
```
**根因**：`_setMainTeam()` 里 `ref.invalidate(mySummaryProvider)` 触发一次重建，紧接着
`await ref.read(userCenterRepositoryProvider).summary()` 又显式请求一次。
**建议**：改为复用 invalidate 后的 provider 结果，去掉显式 `summary()` 调用（或反之）。
**影响**：轻微，浪费一次请求。属 L7「避免重复网络请求」。

---

## OBS-01 首页热门评论存在测试数据（数据质量｜后续改进项）

**位置**：首页「推荐」→ 热门评论卡片
**实际**：显示一条评论，作者 `test06`、正文 `test06`、点赞 2（截图 `S1_21_after_onboarding.png`）
**判定**：不是代码里的 Demo 文案，而是**历史测试数据进入了真实 Feed**。
**建议**：清理测试数据；并评估是否需要内容过滤/审核策略（属后续项，非本轮小修）。

---

## OBS-02 接口耗时（体验观察｜待复测）

真实后端（PID 43784）日志实测：

| 接口 | 耗时 | 说明 |
|---|---|---|
| POST /api/auth/register | 352ms | |
| POST /api/auth/login | **5108ms** | 首次登录，明显偏慢，需复测确认是否预热导致 |
| GET /api/auth/me | 1115ms / 136ms / 17ms | 首次偏慢 |
| GET /api/app/users/me/stand | 1209ms | 首次 |
| GET /api/app/feed | 1281ms | 首次 |
| POST /api/app/recommendation/behaviors/batch | 2113ms | 首次 |
| GET /api/app/onboarding/options | 387ms / 59ms | |

**处理**：在阶段 4 复测（同一接口第二次调用）后定级，避免把 JIT 预热误判为缺陷。

---

## OBS-03 「已是主队」按钮可点但无反应（Minor｜本轮小修）

**位置**：球队详情页右上「加为主队 / 已是主队」按钮
**实际**：已是主队时按钮文案变为「已是主队」，但仍保持可点外观（`onPressed` 未置 null），
点击后 `_setMainTeam()` 内部 `if (_isMainTeam) return;` 静默返回，无任何反馈。
**期望**：要么置灰禁用，要么点击给出提示。属 X1「不可点元素不误导」。

---

## OBS-04 不支持取消主队（产品逻辑｜后续改进项）

**实际**：
- 首次设置中主队为**单选**，选中后点同一支为空操作，无法清空；只能改选另一支
  （`onboarding_page.dart:476` `selectMainTeam`，已选分支为 `() {}`）。
- 设置完成后仅球队详情页有「加为主队」，**没有「取消主队」**。
**判定**：可能是有意设计（账号必有主队），但需求与原型未说明。
**建议**：若产品确认允许「无主队」，需后端与前端同步支持（属后续项）。

---

## DEF-03 搜索：分类无结果时分类栏消失，无法切换分类（Minor｜本轮小修）

**页面**：全局搜索
**复现步骤**：
1. 搜索 `Arsenal`（全部 / 球队有结果）
2. 切到「内容」分类 → 无结果
3. 观察：**分类栏（全部 / 球队 / 球员 / 比赛 / 内容）整体消失**
4. 此时想切回「球队」已无入口；返回再进搜索，仍保留该状态

**实际**：只要当前分类无结果，分类栏就隐藏，用户被困在空结果分类里。
**预期**：分类栏在有关键词时始终可见，方便切换分类。

**证据**：`S2_03_search_state_now.png`（无分类栏 + 「搜索无结果」）；清空关键词后分类栏恢复（`S2_04_search_after_clear.png`）。

**根因**：
- `features/search/presentation/pages/global_search_page.dart:137`
  → `final showSearchFilters = state.status != GlobalSearchStatus.empty;`
- `features/search/presentation/controllers/global_search_controller.dart:181`
  → 当前分类 `page.records.isEmpty` 时即把 status 置为 `empty`

即：**「当前分类无结果」被当成了「整个搜索为空」**，于是连分类栏一起隐藏。

**建议小修**：改为按「是否有关键词」判断，例如
`final showSearchFilters = state.keyword.isNotEmpty;`
（或 `state.status != GlobalSearchStatus.empty || state.keyword.isNotEmpty`）。

**严重度说明**：可恢复（清空关键词后分类栏恢复），但路径反直觉，用户容易认为是「搜索坏了」。

---

## 本轮通过但值得记录的正面结论

- 搜索历史正常记录并可一键清空（`清空` 按钮）。
- 搜索「点结果 → 详情 → 返回」后，关键词、分类、结果列表均正确保留。
- 返回详情页未产生冗余 feed 请求。

---

## DEF-04 内容详情页出现「用户或内容不存在。」错误文案（Major｜本轮小修）

**页面**：首页「资讯」→ 打开任意内容详情（例：`门将站位：一次提前移动带来的收益`）
**实际**：
- 页面底部评论区域显示错误文案 **「用户或内容不存在。」**
- 作者名显示为 `user-11000000000000003`（生成 ID，不是昵称）
**预期**：正常内容详情页不应出现错误文案；作者信息应用内容接口已返回的作者信息。

**证据**：`S2_05_content_detail.png`；接口实测：

```
GET /api/app/contents/16000000000000203        → code 0，data.author = {userId:11000000000000003, nickname:"user-11000000000000003"}
GET /api/app/users/11000000000000003/profile   → {"code":40401,"message":"user not found"}   ← HTTP 状态仍是 200
```

**根因（两层）**：
1. **前端**：内容详情页在已有 `author` 内联信息的情况下，又去请求作者公开资料 `/api/app/users/{id}/profile`；
   该请求返回业务码 40401 后，前端用 `user_center_controllers.dart:781` 的
   `BusinessException(code: 40401) => '用户或内容不存在。'` 映射成页面可见文案。
   即：**作者资料这种「锦上添花」的请求失败，被当成了页面级错误展示**。
2. **数据**：该内容的 `authorId` 指向的用户在 `sys_user` 中已不存在（悬空引用），
   所以 profile 查询返回 40401。

**建议小修**：作者公开资料请求失败时静默降级（保留内容接口返回的 `author.nickname` / `avatarUrl` 兜底），
不向用户展示页面级错误文案。
**建议后续项**：清理内容表中指向不存在用户的悬空 `authorId`（数据修复）。

**备注**：HTTP 状态码恒为 200、业务错误放在响应体 `code` 里，导致仅看后端
`request_timing` 日志（只记录 HTTP status）无法发现此类错误 —— 排查时需同时看响应体。

---

## DEF-05 首次设置：选错主队再改选，旧主队被静默加入「我关注的球队」（Minor｜本轮小修）

**页面**：首次设置第 1 步「我的主队」→ 第 2 步「关注的球队」

**复现步骤**：
1. 第一步把 **Arsenal** 选为主队（选错）
2. 同一页改选 **Chelsea**（旧主队正确取消选中，切换本身没问题）
3. 点「下一步」进入第 2 步

**实际**：第 2 步里 **Arsenal 与 Chelsea 都显示为已关注**（语义树中两行 `selected="true"`：
`[63,836][1017,988]` = Arsenal、`[63,1345][1017,1497]` = Chelsea）。
用户从未在第 2 步选择 Arsenal，它只是被改掉的旧主队。
若用户没注意，提交后会**莫名关注一支球队**。

**预期**：改选主队后，旧主队不应被自动加入关注列表。

**证据**：
- 语义树实测（见上文 bounds 对照）
- 第 2 步可手动取消该队，取消后服务端状态正确：
  `GET /api/app/users/me/stand` → `followTeams = [Chelsea FC, Everton FC]`，**不含 Arsenal**
  → 说明副作用可补救，但需要用户自己发现

**根因**：`features/onboarding/presentation/controllers/onboarding_controller.dart`

```dart
void selectMainTeam(int id) {
  ...
  followTeamIds: {..._state.followTeamIds, id},   // 只增不减
}
```

**建议小修（优先第一个）**：
1. 直接去掉这行自动加入 —— 因为提交时 `features/onboarding/data/onboarding_repository.dart:29`
   已经做了 `followTeamIds: {...followTeamIds, mainTeamId}`，主队本来就会被关注，
   这里的自动加入是**冗余**的，删掉即可根治。
2. 或改成替换语义：`{..._state.followTeamIds.where((t) => t != _state.mainTeamId), id}`。

**备注**：`onboarding_page.dart:455` 的选中态判定本身是对的
（主队步骤只看 `mainTeamId`，关注步骤才看 `followTeamIds`），
所以「切换主队」的交互体验没问题 —— 问题只出在关注集合的副作用上。

---

## 本轮通过但值得记录的正面结论（补充）

- 首次设置第 1 步主队**可以随时改选**，旧主队自动取消选中，单选替换正确。
- 第 2 步「关注的球队」可以随时取消关注某支球队，状态即时生效。
- 第 2、3 步的 `selected` 状态在语义树中可读，便于自动化校验。

---

## DEF-06 发帖页标题提示文案写成「文章标题」（Minor｜本轮小修）

**页面**：首页 →「+ 发布」→ **帖子**模式
**实际**：标题输入框提示为 **「请输入文章标题（20字内）」**，但它上面是帖子内容框（提示「请输入帖子内容」）——同一页面里标题叫「文章」、正文叫「帖子」，命名自相矛盾。

**证据**：`features/content/presentation/pages/publish_post_page.dart:102`
```dart
hintText: '请输入文章标题（20字内）',
```
对照 `publish_post_page.dart:125`：`hintText: '请输入帖子内容'`。

**建议小修**：帖子模式的标题提示改为「请输入标题（20字内）」。

**附带待产品确认**：帖子**必须填标题**才能发布（`publish_post_controller.dart:197` → 「请填写标题」）。
`reports/F18_MANUAL_ACCEPTANCE_CHECKLIST.md` 里「发布 → 帖子 → 添加图片 → 发布」并未提到标题，需确认帖子是否应强制标题。

---

## DEF-07 更换手机号成功后不返回上一页（Minor｜本轮小修）

**页面**：设置 → 账号与安全 → 手机号 → 输入新号 → 确认更换
**实际**：手机号确实更新成功（掩码从 `138****8003` 变为 `138****8009`），但**页面停留在更换手机号表单，没有返回上一级**；输入框里还留着刚刚提交的号码。

**证据**：
- 后端两条请求均成功：`PUT /api/app/users/me/phone 200 (140ms)` → `GET /api/auth/me 200 (11ms)`
- 页面无任何错误提示（说明没走异常分支）
- 等待 6 秒后页面仍未返回
- 代码 `features/user_center/presentation/pages/settings_pages.dart` 的 `_ChangePhonePageState._submit()` 在成功分支末尾有 `context.pop()`，因此需要进一步确认 `context.pop()` 在此路由层级（`/settings/account/phone` 为 root navigator push）是否生效

**影响**：用户容易误以为没成功而重复提交。
**建议**：确认 `context.pop()` 是否被路由层级吞掉；必要时改用显式 `context.pop()` 前的挂载/层级判断，或改为成功后就地展示结果态。

---

## OBS-05 头像选择器打开时「更换头像」按钮已显示「上传中」（Minor｜待确认）

**页面**：编辑资料 → 更换头像
**现象**：点「更换头像」弹出系统相册选择器后，背后的按钮已变成转圈 + 「上传中」，但此时尚未选择任何图片。
**影响**：状态与实际进度不符，若用户取消选择，按钮可能停留在忙碌态。
**判定**：需要复核（可能是 picker 打开即置 busy 的实现细节）。证据：`S3_02_avatar_picker.png`。

---

## 数据缺口：本地库没有任何带阵容的比赛（影响用例 15）

**现象**：feed 与「重要比赛」列表中的比赛，`lineups` 与 `ratings` 接口均返回空数组；逐个探测 5+ 场比赛全部为空。
**影响**：**评分提交 / 修改 / 撤销无法验证**。`reports/F18_MANUAL_ACCEPTANCE_CHECKLIST.md` 明确要求准备「一场有阵容/统计/评分的比赛」，当前本地数据不满足。
**判定**：数据缺口，非 App 缺陷（阵容、评分、统计三处空态渲染均正确）。
**建议**：补种子数据；或确认该功能是否已被产品砍掉。

---

## OBS-02 修正：feed 耗时不是稳定偏慢，而是预热/连续翻页场景

**原记录**：feed 分页 925ms / 2020ms / 2376ms，怀疑偏慢。
**回归实测**：预热后 feed 接口稳定在 **72–73ms**（连续 3 次）。

**修正结论**：早前的高耗时集中在 app 冷启动后的首批请求与「连续快速上拉加载更多」场景。
**建议**：不改代码；若仍要优化，先定位到具体页码/数据量，列入性能专项（IMP-07 保留但降级）。

---

## OBS-06 注册页「确认密码」与协议行间距偏紧（Minor｜本轮未修）

**页面**：注册页
**现象**：「确认密码」输入框与下方协议行之间几乎贴住（实测间距约 40px），而同页其他字段之间约 72px；登录页同位置间距约 73px。属间距 token 未统一的视觉不一致（V1/V2）。

**证据**：`S1_09_form_ready.png`（注册页）；`S1_12_login_filled.png`（登录页对照）
**原因推断**：`register_page.dart` 中 `AuthAgreement` 前没有 `SizedBox`，而其他字段之间都有 `SizedBox(height: AppSpacing.md)`。
**建议小修**：在 `AuthAgreement` 前补一个 `SizedBox(height: AppSpacing.md)`，与登录页保持一致。
**本轮未修原因**：属纯视觉微调，不影响功能；已登记待与其它视觉项统一处理。
