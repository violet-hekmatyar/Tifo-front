# Round 13A：通知并发与验收证据最终收口

## 任务

在 `D:\Football-APP-Front` 主目录继续完成 Round 13，不进入登录/引导或其他模块。现有代码和测试均须保留，修复通知刷新与已读操作交错时的真实状态覆盖，并把 MSG-01～10、SET-01～06 中尚未形成实质断言的项目补齐。

必须持续执行到本轮全部验证通过。编译、测试、夹具、异步时序和布局问题都不是阻塞；只有缺少不可替代的外部契约或环境且已给出证据时才可停止。不要只增加编号或弱化断言来宣称完成。

## 已确认问题

当前 `NotificationController` 存在以下竞态：

1. `markRead` 请求未完成时启动 refresh；refresh 返回旧的 unread 行后，`markRead` 成功只清 busy，没有重新合并该行的 read=true，最终会错误显示未读；
2. refresh 先发出、`markAllRead` 后成功时，较晚返回的旧 refresh 响应仍可把全部通知覆盖回未读；
3. 现有 MSG-05 测试名写了 append retry，但没有制造 append 失败；MSG-06 没有覆盖 false/网络/业务失败后“不跳转”；请求代次、Shell Badge 同源和设置入口往返证据也不完整。

## 范围

只修改：

- `apps/mobile/lib/features/notification/**`
- 必要的 `main_shell`、settings/router 小范围修正
- notification/settings/router/Shell 定向测试
- `reports/FRONTEND_PROTOTYPE_ALIGNMENT_PLAN.md`

不修改后端、数据库、API 契约，不做私信、手机号/微信登录、登录/引导页面，不做视觉重构或新增依赖。

## 实现要求

### A. 请求与操作合并

- list retry/refresh 继续使用代次保护；旧首屏、旧 refresh、旧 append 均不得覆盖新结果；
- refresh/replace 响应必须与正在进行或已成功完成的单条/全部已读结果安全合并，不允许 read 状态回退、busy 泄漏或红点反弹；
- 两个不同 notificationId 的单条操作可并发，同 ID 防重；成功/false/NetworkException/BusinessException 只影响对应行；
- mark-all 与单条、refresh 三方交错时按已经成功的权威操作合并；失败不得撤销另一项成功；
- 刷新失败保留 records/page/滚动结构，append 失败保留 records 并重试原 page；分页继续去重、防重复加载、正确到底。

不要靠延迟、固定完成顺序或页面强制重载规避竞态。优先在 controller 中建立清晰的小范围操作版本/已读覆盖记录；刷新获取到新的权威页面后可清理已不需要的本地覆盖，但不得无限积累。

### B. 页面与路由闭环

- 未读行只有 mark-read 成功才跳转；repository 返回 false、网络或业务失败均回滚、显示反馈且零跳转；已读行零 read 请求但仍可按有效 route 跳转；
- system/unknown/targetAvailable=false/缺失、0 或负 ID 均不误跳；有效内容、评论关联内容、用户目标正常跳转；
- Shell Badge 与 unread provider 同源：0 隐藏、正数显示、大数安全；单条和全部已读成功触发刷新，失败不伪减；unread-count 失败不破坏本地通知列表；
- 设置页保持且仅保持四个真实入口；本人页→设置→账号/编辑资料/通知→返回链路正确；退出取消、busy、防重、成功重定向和失败留页保持有效。

## 强制新增/强化测试

测试必须用 `Completer` 控制逆序完成并检查中间态，不得只 `pumpAndSettle` 后看最终文案。

| 编号 | 必须形成的实质断言 |
| --- | --- |
| R13A-01 | markRead pending→refresh 返回旧 unread→markRead 成功，最终该行 read=true、busy 清空 |
| R13A-02 | refresh pending→mark-all 成功→旧 refresh 后返回，全部行仍 read=true、未读不反弹 |
| R13A-03 | 两次 retry/refresh 逆序完成，旧响应不能覆盖新 records/page |
| R13A-04 | append 明确失败，records/page 不变并显示 retry；重试仍请求原页且去重 |
| R13A-05 | markRead 返回 false、NetworkException、BusinessException 分别回滚且不导航；成功才导航 |
| R13A-06 | 已读行零请求但有效 route 可跳；无效目标零误跳 |
| R13A-07 | Shell Badge 0/普通/大数/失败；单条和全部成功触发权威刷新，失败不触发成功更新 |
| R13A-08 | 本人设置入口及账号/编辑/通知往返；退出双击只调用一次，失败留页 |
| R13A-09 | 360/412px、DPR 1、1.4x 下通知、设置、账号页无 overflow/exception |

同时逐项核对原 MSG-01～10、SET-01～06：若既有测试已有等价实质断言可复用；没有就补齐。编号不等于证据，不要求“一编号一文件”，但最终报告必须映射到具体测试名。

## 最小验证

开发中只跑相关单文件。完成后统一执行一次：

1. `flutter analyze`
2. `flutter test test/features/notification`
3. `flutter test test/features/user_center/f19_settings_acceptance_test.dart test/features/user_center/f07_router_test.dart test/app/router/auth_redirect_test.dart`
4. `flutter test test/features/feed/f04_home_feed_widget_test.dart`
5. `git diff --check`

不跑全仓测试、旧阶段脚本、模拟器或 APK。

## 完成标准

- R13A-01～09 和原 MSG/SET 矩阵都有真实行为证据并全部通过；
- 刷新、单条已读、全部已读任何完成顺序均不使成功状态回退；
- 不新增假功能、生产 mock、协议字段或无关修改；
- 更新总计划：只有上述验证全部通过，Round 13/13A 才可标记“已通过”。

## 最终仅汇报

1. 修改文件；
2. 两个已确认竞态的根因和修复；
3. R13A-01～09 对应的具体测试名、关键时序与结果；
4. 原 MSG-01～10、SET-01～06 缺口补齐情况；
5. 最小验证的准确测试数；
6. 阻塞/剩余问题。

全部通过后输出：

`Round 13A Flutter notification concurrency acceptance closure passed`
