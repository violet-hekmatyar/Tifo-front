# Round 14：账号登录、注册与首次关注引导完整对齐

## 任务

在 `D:\Football-APP-Front` 主目录完成现有用户名密码登录、注册、会话恢复及首次引导的原型对齐，形成“启动恢复 → 登录/注册 → 选择主队 → 关注球队 → 关注球员 → 首页”的完整可测试链路。

直接持续实现到全部验收通过。编译、测试、夹具、异步、键盘和布局问题不是阻塞；只有缺少不可替代的外部契约且已给出证据时才可停止。不得只写测试编号或保留未完成状态后结束。

## 原型与产品边界

参考：

- `C:\Users\hekmatyar\Desktop\足球APP\登录.png`
- `C:\Users\hekmatyar\Desktop\足球APP\登录-弹窗提示.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择主队.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择球队.png`
- `C:\Users\hekmatyar\Desktop\足球APP\选择球员.png`

`其他手机登录*.png` 只用于识别排除范围，不得实现。

必须明确：

- 不实现、不展示手机号验证码登录、一键手机号登录、微信登录或第三方授权入口；
- 当前注册接口仍要求 `phone`，注册表单保留该真实字段，但它只是账号注册资料，不得包装成验证码登录；不得修改现有注册协议；
- 不新增找回密码、短信验证码、扫码、游客登录或虚假协议页面；
- 协议弹层只完成本地“阅读并同意”的确认交互，不复制原型中的 `xxxxxxxx`，不创建打不开的链接；
- 不修改后端、数据库、Result/API 字段或新增依赖。

## 修改范围

只修改：

- `apps/mobile/lib/features/auth/**`
- `apps/mobile/lib/features/onboarding/**`
- 必要的 `auth_redirect.dart`、`app_router.dart` 和已有公共登录/选择组件
- auth/onboarding/router 定向测试
- `reports/FRONTEND_PROTOTYPE_ALIGNMENT_PLAN.md`

不修改首页 Feed、内容、数据榜单、详情、用户中心、通知或后端；不要做无关公共组件重构。

## Gate 0：现有契约与基线

- 保留现有用户名+密码 login、用户名+phone+密码 register、token restore/current-user/logout 和 onboarding options/preferences 契约；
- 保留 Backend V1 的用户名、密码、phone 长度/格式和业务错误语义，不自行增加会导致真实账号不可用的正则规则；
- 核对 AuthStatus 五态、registeredUsername、onboardingCompleted、mainTeamId、40101/40102/40103、Network/Timeout/BusinessException；
- 先跑现有 auth/onboarding/router 定向测试，范围内失败必须修复并继续，不得删除旧断言。

## Gate 1：绿色账号登录与注册

- 登录页对齐原型的绿色品牌头部、球形品牌标识、欢迎文案及底部白色大圆角操作面板；使用现有 Design Token，不引入截图背景或新图片依赖；
- 白色面板内只展示真实“用户名、密码、登录、注册”能力；用户名和密码有稳定 Key、键盘 next/done、自动填充、密码显隐和明确校验；
- 提交时按钮 loading 且防重复，表单值保持；登录失败区分普通业务错误、锁定、网络和超时，失败不清空密码或错误地跳转；成功由 AuthController/GoRouter 路由，不在页面写重复导航；
- 注册页沿用同一视觉骨架，保留 username/phone/password/confirmation；密码显隐与确认一致，验证失败零请求，提交 busy 防重复；
- 注册成功回登录并自动填入 registeredUsername，密码不得跨页保留；注册失败保留输入并展示真实错误；返回登录不制造额外请求；
- 所有输入、显隐、提交、切换登录/注册和错误反馈增加语义化稳定 Key。

## Gate 2：协议确认

- 登录和注册操作区显示未勾选/已勾选协议确认，初始为未勾选；文字使用“我已阅读并同意《用户协议》和《隐私政策》”；协议名称若没有真实文档路由则只作为文字，不做死链接；
- 未同意时点击登录/注册不发请求，打开原型风格圆角确认弹层；“不同意”关闭且仍不提交；“同意”更新勾选状态，并继续用户刚才触发的那一次合法提交；
- 已同意后正常提交，重复点击仍受 controller busy 保护；表单本身未通过校验时优先显示字段错误，不应弹协议窗或发请求；
- 弹层支持返回键/外部关闭的安全结果、SafeArea 和大字体，不硬编码原型占位协议内容。

## Gate 3：启动、会话和路由

- 无 token 冷启动进入 `/login`；有效 token 按 `onboardingCompleted` 进入 `/onboarding` 或 `/app/home`；
- 40101/40102 恢复失败清理会话并回登录；网络、超时和其他业务失败保留 token，BootstrapPage 显示失败与真实重试，不闪入登录或首页；
- 登录完成但 onboarding 未完成只进引导，已完成直接进首页；未登录访问受保护路由回登录；已登录访问 login/register 按状态重定向；
- login/register/restore 的重复请求、过期旧响应和页面 dispose 后回调不造成状态倒退、重复导航或异常；session invalidation/logout 继续可用。

## Gate 4：首次引导视觉与步骤

- 三步页面分别为“我的主队 / 关注的球队 / 关注的球员”，对齐绿色头部、标题说明、半透明圆角搜索框、白色大圆角结果面板、卡片列表、爱心选中态及底部固定操作区；
- 使用真实 options 数据和 `resolveMediaUrl`；队徽/头像缺失或加载失败自然降级，nullable league/country/team/position 不显示多余分隔符；
- 主队单选且必选，选择后自动包含在关注球队；当前主队在球队步骤保持选中且不可取消；其他球队和球员支持自由多选；
- 禁止加入原型中的“最多 4 支”或历史“最多 5 支”硬限制，页面文案也不得暗示不存在的限制；
- 第一步没有“上一步”；后两步可返回且保留每步选择、各自搜索词和实际滚动位置；Android 返回键在后两步先回上一步，第一步不能绕过未完成引导进入首页；
- 最后一步即使不选球员也允许完成，但没有主队绝不提交。

## Gate 5：搜索、状态与提交正确性

- 主队搜索、关注球队搜索、球员搜索使用三个独立本地查询，不发网络请求；trim、大小写和 name/league/country/team/position 可用字段匹配；清空恢复全量；
- 每步无搜索结果有明确局部空态，不把整页误判为接口 empty；options 无球队才是整页 empty，players 为空仍可完成引导；
- options 覆盖 loading/empty/error/retry；load/retry 增加防重复和请求代次保护，旧失败/旧成功不得覆盖新请求；
- controller 拒绝不存在、非正数的 team/player ID，不把无效 ID 写入 preferences；分页不是该契约能力，不自行增加；
- submit busy 防重；保存失败保留主队、球队、球员、搜索和当前步骤并可原位重试；成功刷新 AuthUser 后只进入首页一次；
- 若 preferences 已成功但 current-user 刷新失败，错误必须可见且可重试，不能伪装完成或清空选择；沿用现有幂等保存方式，不修改协议。

## Gate 6：响应式与清理

- login/register/协议弹层/Bootstrap/三步引导在 360px、412px、DPR 1、1.4x 字体下无 overflow、遮挡或异常；
- 键盘弹出时当前输入、错误和主提交按钮可滚动到达；底部操作区适配 SafeArea，不遮挡最后一项；
- 长用户名、长球队/球员名和可空副标题最多合理行数并省略；
- 生产路径无手机号验证码/微信按钮、原型示例球队球员、固定 mock、`TODO`、死按钮和旧硬限制。

## 强制验收矩阵

| 编号 | 必须验证 |
| --- | --- |
| AUTH-01 | 登录页只有用户名密码真实能力；无手机号验证码/微信/游客/找回密码死入口 |
| AUTH-02 | 空值、边界输入、done 提交、密码显隐；字段失败零请求 |
| AUTH-03 | 协议未选零请求并弹窗；不同意零请求；同意后只提交一次 |
| AUTH-04 | login busy 防重，成功按 onboarding 状态分别进引导/首页 |
| AUTH-05 | login 业务/锁定/网络/超时失败保留输入、留页和反馈 |
| AUTH-06 | 注册四字段校验、显隐、确认密码、busy 防重及失败保持 |
| AUTH-07 | 注册成功回登录并预填用户名，密码/phone 不跨页泄漏 |
| AUTH-08 | 注册 phone 仍按现有 API 发送，但不存在 phone-login 请求或入口 |
| AUTH-09 | 无 token、有效 token 两种用户状态、40101/40102、网络/业务 restore 路由正确 |
| AUTH-10 | Bootstrap loading/failure/retry；旧 restore 响应不能覆盖新状态 |
| AUTH-11 | 未登录受保护路由、已登录 login/register、session invalidation 跳转正确 |
| AUTH-12 | 360/412px、1.4x、键盘和协议弹层无布局异常 |
| ONB-01 | 三步视觉结构、标题、进度、按钮和稳定 Key 正确 |
| ONB-02 | 主队必选单选、自动关注且当前主队不可取消 |
| ONB-03 | 球队/球员多选无 4/5 支硬限制，重复点击集合正确 |
| ONB-04 | 三个独立搜索词及 trim/大小写/多字段过滤、清空和局部空态 |
| ONB-05 | 上一步、Android 返回、IndexedStack 状态、搜索与真实滚动偏移保持 |
| ONB-06 | loading/无球队 empty/error/retry；players 空仍可完成 |
| ONB-07 | load/retry 防重与逆序结果竞态保护 |
| ONB-08 | nullable 文本、相对/失败媒体、长名称安全展示 |
| ONB-09 | 无效/负 ID 不进入选择或请求，合法 ID 原样提交 |
| ONB-10 | submit 无主队零请求；球员可空；主队始终包含在 followTeamIds |
| ONB-11 | submit busy 防重、失败保留全部页面状态、重试成功 |
| ONB-12 | preferences 成功后 AuthUser 刷新成功只进首页一次；刷新失败可见可重试 |
| ONB-13 | 360/412px、1.4x、SafeArea、键盘和底栏无异常 |

测试必须包含真实操作和调用参数断言。竞态用 `Completer` 逆序完成；路由用真实 GoRouter；响应式设置真实 physicalSize/DPR/textScaler；不要以“能找到 Widget”替代状态、几何、请求次数或参数断言。

## 最小验证

开发中只跑相关单文件。完成后统一执行一次：

1. `flutter analyze`
2. `flutter test test/features/auth`
3. `flutter test test/features/onboarding`
4. `flutter test test/app/router/auth_redirect_test.dart test/features/user_center/f07_router_test.dart`
5. `git diff --check`

不跑全仓测试、旧阶段脚本、模拟器或 APK。

## 完成标准

- 用户名密码登录、现有注册、协议确认、会话恢复及三步引导形成完整闭环；
- AUTH-01～12、ONB-01～13 均有实质行为/API/路由/响应式证据并全部通过；
- 手机号验证码登录和微信登录完全不存在，注册 phone 契约不回归；
- 无生产 mock、示例数据、死入口、新依赖或后端修改；
- 更新总计划，只有全部验证通过才将 Round 14 标为“已通过”。

## 最终仅汇报

1. 修改文件；
2. 登录、注册、协议、会话恢复与三步引导完成结果；
3. AUTH-01～12、ONB-01～13 对应的具体测试名、关键断言和结果；
4. 最小验证准确测试数；
5. 手机号验证码/微信登录排除检查；
6. 阻塞/剩余问题。

全部通过后输出：

`Round 14 Flutter auth and onboarding completion passed`
