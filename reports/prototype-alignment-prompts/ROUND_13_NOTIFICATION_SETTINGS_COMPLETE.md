# Round 13：互动通知与可用设置完整原型对齐

## 任务

在 `D:\Football-APP-Front` 主目录完成消息入口、互动通知列表、未读状态和设置/账号信息页面的原型对齐。通知严格复用现有 Backend V1 `list / unread-count / mark-read / read-all`；设置只开放现有客户端真正可执行的资料编辑、账号信息查看和退出登录，不修改后端、数据库或 API。

按 Gate 0～6 连续实现和测试。编译、布局、测试、夹具问题不是阻塞；除真实缺少契约/外部服务外必须继续修复。不得用原型中的假会话或死设置项凑界面。

## 原型与范围

参考：

- `C:\Users\hekmatyar\Desktop\足球APP\消息.png`
- `C:\Users\hekmatyar\Desktop\足球APP\消息-互动消息.png`
- `C:\Users\hekmatyar\Desktop\足球APP\我的-设置.png`
- `C:\Users\hekmatyar\Desktop\足球APP\我的-设置-账号与安全.png`

`消息-对话框.png` 仅用于确认视觉边界，当前没有私信契约，禁止实现或伪造。

只修改：

- `apps/mobile/lib/features/notification/**`
- 必要的新 settings 表现层文件，优先放在现有 user_center/settings 合理目录
- `main_shell_page.dart`、`my_profile_page.dart`、router 的必要入口适配
- notification/settings 定向测试

不做私信/IM、聊天列表、发送消息、搜索会话、删除会话、推送开关、手机号绑定/修改、修改密码、注销账号、语言切换、主题切换、手机号/微信登录；不新增依赖。缺少真实能力的原型行应省略，不做 disabled 假按钮或“敬请期待”。

## Gate 0：契约与基线

- 核对 AppNotification、actor、targetPreview、target/secondaryTarget、read、时间、分页和 unknown 枚举；不修改线协议；
- 核对 AuthUser 当前只有 id/username/nickname/avatar/role/status/onboarding/mainTeamId，无 phone；账号页不得显示或推导脱敏手机号；
- 先运行现有 notification 与 shell/router 基线，范围内失败直接修复；
- `/app/messages`、`/messages`、设置入口和退出后的 auth redirect 必须清晰，无重复页面状态。

## Gate 1：消息入口

- 对齐原型的消息页视觉，但只展示一个真实“互动消息”入口：图标、未读数和可用的最新通知摘要；无最新记录时使用中性说明，不伪造用户会话或时间；
- 若为避免额外重复请求，允许 `/app/messages` 直接呈现互动通知列表并以“互动消息”为标题；选择哪种结构应复用同一 controller，不得 hub/list 各请求一次；
- 不显示搜索、写消息、删除会话按钮，因为当前没有闭环；
- 主 Shell 消息 Badge 与互动页未读数使用同一来源，0 隐藏、正数显示、超大数安全；进入页面不自动把全部消息标已读。

## Gate 2：通知列表与跳转

- 按原型行结构展示 actor 头像/昵称、真实动作语义、正文、相对或清晰时间、targetPreview 文本及可用 cover；缺头像/封面/时间/actor、长文本安全；
- 六类通知 CONTENT_LIKED、CONTENT_COMMENTED、COMMENT_REPLIED、COMMENT_LIKED、USER_FOLLOWED、SYSTEM 有明确但不虚构的视觉；unknown 中性展示；
- 只有 `targetAvailable == true` 且目标 ID > 0 才跳转：内容及评论关联内容进 `/contents/:id`，用户进 `/users/:id`；system、unknown、缺/负 ID、不可用目标不跳但仍可标已读；
- 行点击先完成 mark-read，成功才跳转；已读行不重复请求；失败保持未读并提示，不跳转。

## Gate 3：加载、分页、刷新与竞态

- 覆盖 loading/empty/error/retry、ready refresh 失败保留、分页去重、防重、append 失败保留并重试原页、到底；
- controller 增加请求代次保护：retry/refresh 的旧响应不能覆盖最新结果，append 结果不能并入已被 refresh 替换的代次；
- 刷新期间保留列表和滚动结构，失败反馈可原位重试；
- 页面从内容/用户详情返回保留 records、page、实际滚动偏移和 repository 调用次数。

## Gate 4：单条/全部已读并发正确性

- 单条标记增加按 notificationId 的 busy 防重；不同通知可并发；
- 不得用整份 previous state 回滚。两个通知逆序完成时，单条失败只恢复自己的 unread，不能撤销另一条成功，也不能清空另一条 busy；
- repository 返回 false 视为失败；Network/BusinessException 显示反馈并保持计数；无效 notificationId 零请求；
- 全部已读需明确 busy、防重复。成功后当前全部记录已读并刷新权威 unread count；失败保留原 read 状态；
- mark-all 与单条 mark-read 同时发生时，最终状态按各权威结果合并，不能出现负未读数、红点反弹或 busy 泄漏；
- unread provider 请求失败时列表本地 unread 仍可显示，不能导致页面失败。

## Gate 5：设置与账号信息

- 本人主页齿轮进入真实 SettingsPage；页面只保留：账号与安全、编辑个人资料、互动通知、退出登录；其中“账号与安全”是可进入的只读账号信息页；
- 账号信息只展示 AuthUser 真实 username、roleType、status 和当前资料中真实昵称/头像（若已有）；不得显示手机号、修改密码、注销账号入口；
- 编辑资料进入 R12 已通过页面；互动通知进入真实通知页；返回保持本人主页 Tab/滚动；
- 退出登录必须二次确认：取消零调用；确认时 busy 防重复；成功清理会话并由现有 auth redirect 回登录；异常时仍停留设置页并显示反馈。若 AuthController 当前无法暴露失败，应只按已有语义处理，不改后端；
- 页面使用浅灰底、白色圆角分组、统一图标和安全区，对齐原型层级。

## Gate 6：响应式与清理

- 消息入口、通知列表、设置、账号信息在 360/412px、DPR 1、1.4x 字体下无 overflow，长昵称/通知/账号状态可读；
- notification 图片用 `resolveMediaUrl`，加载失败降级；ISO/null/unknown 安全；
- 无 `MessagesPlaceholderPage` 生产路由残留，无私信/手机号/密码/注销/语言/通知开关死入口，无生产 mock、原型示例或 TODO。

## 强制验收矩阵

| 编号 | 必须验证 |
| --- | --- |
| MSG-01 | 消息入口只有真实互动通知，无假会话/搜索/写信/删除入口；未读 Badge 同源 |
| MSG-02 | 六类通知与 unknown、nullable、长文本、相对媒体安全展示 |
| MSG-03 | 内容/评论/用户有效跳转；system/unknown/不可用/缺失或负 ID 不跳 |
| MSG-04 | 首屏 loading/empty/error/retry 与 ready refresh 失败保留 |
| MSG-05 | 分页去重、防重、append retry 原页、到底和请求代次保护 |
| MSG-06 | 已读行零请求；未读成功后跳转；false/网络/业务失败不跳且回滚 |
| MSG-07 | 同 ID 防重、不同 ID 逆序并发成功/失败按条目合并 busy/read |
| MSG-08 | 全部已读成功/失败/busy；与单条并发不丢状态，未读数正确 |
| MSG-09 | unread-count 成功/0/大数/失败降级及 Shell Badge 更新 |
| MSG-10 | 详情往返保留 records、page、实际滚动 offset 和调用次数 |
| SET-01 | 本人齿轮→设置；仅四个真实入口，禁止能力完全不存在 |
| SET-02 | 账号页只展示 AuthUser 真实字段，无伪手机号/改密/注销 |
| SET-03 | 编辑资料、互动通知入口和返回状态正确 |
| SET-04 | 退出确认取消、busy 防重、成功 redirect、失败反馈 |
| SET-05 | API Result/PageResult、nullable、unknown、ISO、mark 返回值解析安全 |
| SET-06 | 360/412px、DPR 1、1.4x 下消息/通知/设置/账号页及 SafeArea 无异常 |

并发测试使用 Completer 逆序完成；状态测试让 fake 真实经历失败和重试；缓存测试断言 ScrollPosition 与调用次数；API 使用现有 MockWebServer。测试名有编号不等于通过，必须包含上述行为断言。

## 最小验证

开发中只跑必要单文件，完成后统一：

1. `flutter analyze`
2. 全部 `test/features/notification` 测试
3. 新增 settings 定向测试及受影响的 `f07_router_test.dart`
4. 若修改 Shell Badge，补跑 `f04_home_feed_widget_test.dart`
5. `git diff --check`

不跑全仓、模拟器或 APK。

## 最终仅汇报

1. 修改文件；
2. 消息、通知、未读与设置完成结果；
3. MSG-01～10、SET-01～06 的实际测试名、关键断言和结果；
4. 最小验证准确测试数；
5. 阻塞/剩余问题。

全部通过后输出：

`Round 13 Flutter notification and settings completion passed`
