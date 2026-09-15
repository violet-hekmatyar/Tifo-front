# Round 14A：登录与首次引导视觉、几何及交互证据收口

## 任务

在 `D:\Football-APP-Front` 主目录继续收口 Round 14。现有认证、协议、请求代次、非法 ID、提交防重和 API 契约已经通过，必须保留；本轮重点完成尚未落实的原型视觉结构、滚动/键盘/媒体边界及真实几何验收。

必须持续修复到本轮全部验证通过。测试、布局、夹具和异步问题不是阻塞；不得只增加测试编号、仅断言 Widget 存在或再次报告“主体已完成”。

## 已确认缺口

1. 当前引导 ready 页面仍是旧的标准 AppBar、白色进度区域和普通 ListView，没有实现原型的绿色说明头、头部搜索、白色大圆角结果面板、爱心选中态与一体化底部操作结构；
2. AUTH-12 目前只渲染 LoginPage，没有覆盖 RegisterPage、BootstrapPage 和协议弹层；
3. ONB-05 只证明输入文本和集合保持，没有验证三个步骤的真实 ScrollPosition；
4. ONB-08 没有形成 nullable 长文本、相对媒体与图片失败的 Widget 证据；搜索清空、局部无结果、键盘遮挡也缺少实质断言。

## 范围

只修改：

- `apps/mobile/lib/features/auth/presentation/**`
- `apps/mobile/lib/features/onboarding/presentation/**`
- 必要时为 `AppSelectionCard` 增加向后兼容的可选视觉参数
- auth/onboarding 定向 Widget 测试
- `reports/FRONTEND_PROTOTYPE_ALIGNMENT_PLAN.md`

除发现明确回归外，不重写 AuthController、OnboardingController、Repository、API 或 domain；不修改后端、数据库、路由协议和其他业务模块，不新增依赖。

继续排除手机号验证码登录、一键手机号登录、微信登录、游客登录和找回密码。注册 `phone` 字段必须保留。

## Gate 1：登录、注册与协议视觉收口

- 保留绿色品牌头与白色圆角操作面板，调整整体比例、间距和层级，使 360/412px 下首屏重点与 `登录.png` 一致；用户名密码能力必须清晰，不照搬原型的脱敏手机号、一键登录或微信按钮；
- 登录/注册表单在键盘弹出时可滚动到当前错误、协议与提交按钮，关闭键盘后不丢输入；长业务错误不造成横向或底部 overflow；
- 协议行支持明确的未选/已选视觉，也允许用户取消已同意状态；点击主按钮未同意时仍打开圆角确认弹层，同意只触发一次提交，不同意/返回/下滑关闭零请求；
- 协议弹层在 360px、1.4x 下按钮和正文完整可达，不使用原型 `xxxxxxxx`，协议名称没有真实路由时不可伪装成可点击链接；
- RegisterPage、Bootstrap loading/failure、LoginPage 均使用相同品牌和 Design Token 语言；不因视觉修改改变现有路由或请求参数。

## Gate 2：三步引导原型结构

严格参考：

- `选择主队.png`
- `选择球队.png`
- `选择球员.png`

ready 状态重构为同一响应式页面骨架：

1. 顶部绿色区域：当前步骤的大标题、清晰说明、独立搜索框；搜索框为半透明圆角样式并保持足够对比度；
2. 下部白色大圆角结果面板：顶部“搜索结果/可选球队/可选球员”标题，下面为可滚动卡片列表；
3. 结果卡：真实队徽/头像、主标题、可用副标题、右侧爱心或等价收藏语义；选中/未选中有明确动画和 Semantics.selected；
4. 底部操作：固定在白色面板底部并适配 SafeArea；第一步单个“下一步”，第二、三步“上一步 + 下一步/完成”；列表末项不可被遮挡；
5. 步骤进度可保留为轻量信息，但不能单独占用一整块白色顶部区域破坏原型层级；ready 页面不得继续显示旧标准 AppBar 结构。

不要使用原型截图作背景，不硬编码示例球队、球员、联赛或数量。背景若需层次，只能用现有颜色、渐变或轻量代码图形，不新增位图资产。

## Gate 3：步骤交互与状态保持

- 主队、关注球队、关注球员继续使用三个独立搜索 Controller；切换步骤与返回后文本、过滤结果、选择集合和各 ListView 的真实滚动偏移均保持；
- 每个步骤使用独立稳定 PageStorageKey/ScrollController，测试实际拖动至 offset>0，跨步骤往返后比较恢复值，不能只检查搜索文本；
- 搜索 trim、大小写、多字段匹配继续有效；清空后恢复全量；无匹配时在白色面板内显示局部空态且底部按钮仍可操作；
- 主队必选/单选/自动关注、当前主队不可取消、球队球员不限 4/5 支、球员可空、非法 ID 零影响等已通过语义不得回归；
- loading/整页 empty/error/retry 也使用统一绿色品牌背景与安全区，但不伪造 ready 数据；提交失败反馈必须在当前步骤可见且不改变布局骨架。

## Gate 4：媒体、长文本、键盘与响应式

- 对 TeamOption/PlayerOption 构造相对 URL、null URL、失败 URL；断言经过现有媒体解析并在加载失败时出现稳定降级且无异常；不发真实互联网请求；
- 覆盖 null/空 leagueName、country、teamName、position，不能出现孤立 `·`；超长名称/副标题限行或省略，不能挤掉选择按钮；
- 在 360px 与 412px、DPR 1、1.4x 字体分别进入三个 ready 步骤，检查标题、搜索框、结果面板、底部按钮的 Rect 均在屏幕内且互不遮挡；
- 分别在 LoginPage、RegisterPage、协议弹层和引导搜索框显示测试键盘，滚动/ensureVisible 到主操作，断言可点击且无 overflow/exception；
- Bootstrap loading 与长错误/traceId 在上述宽度和大字体下完整可滚动或可达。

## 强制验收矩阵

| 编号 | 必须形成的实质证据 |
| --- | --- |
| R14A-01 | 三个引导步骤共享绿色头 + 头部搜索 + 白色圆角结果面板 + 固定操作区，旧 ready AppBar/独立白进度块不存在 |
| R14A-02 | 选中/未选中爱心或等价语义、Semantics.selected、主队不可取消及多选视觉正确 |
| R14A-03 | 三个步骤分别滚动到 offset>0，跨步骤和 Android 返回后恢复各自精确 offset、搜索与选择 |
| R14A-04 | 搜索多字段、trim/大小写、清空恢复、局部空态，三个查询互不污染 |
| R14A-05 | null/空/长字段无孤立分隔符或挤压；相对、缺失、失败媒体安全降级 |
| R14A-06 | 360/412px、1.4x 下三个步骤的关键 Rect 在屏幕内且列表末项不被底栏遮挡 |
| R14A-07 | Login/Register/Bootstrap loading+failure/协议弹层均在 360/412px、1.4x 下无异常 |
| R14A-08 | 登录、注册和引导分别显示键盘后，输入/错误/协议/主按钮可滚动到达并可操作 |
| R14A-09 | 协议同意、取消同意、不同意、返回/下滑关闭和双击主按钮请求次数正确 |
| R14A-10 | 原 AUTH-01～12、ONB-01～13 全部回归，无手机号验证码/微信入口、无 4/5 支限制、注册 phone 不变 |

几何测试必须读取 `tester.getRect`/ScrollPosition 并断言相对关系；媒体测试使用可控测试环境；键盘测试设置 `viewInsets` 或真实 testTextInput。仅 `findsOneWidget` 和 `takeException == null` 不足以单独证明 R14A-03、05、06、08。

## 最小验证

开发中只跑相关单文件。完成后统一执行一次：

1. `flutter analyze`
2. `flutter test test/features/auth`
3. `flutter test test/features/onboarding`
4. `flutter test test/app/router/auth_redirect_test.dart`
5. `git diff --check`

不跑全仓测试、旧阶段脚本、模拟器或 APK。

## 完成标准

- 控制器/API 已通过能力不回归；
- 三步引导在结构、层级、选择反馈和底部操作上真正接近原型，而非只换颜色；
- R14A-01～10 均有实际视觉结构、行为、几何或调用次数断言并通过；
- 无生产示例数据、死入口、新登录方式、硬限制、新依赖或后端修改；
- 只有全部验证通过后，才能把 Round 14/14A 标记为“已通过”。

## 最终仅汇报

1. 修改文件；
2. 引导旧结构如何重构为原型结构；
3. R14A-01～10 的具体测试名、几何/滚动/键盘/请求关键断言；
4. AUTH、ONB 回归准确测试数；
5. 排除能力与契约保持；
6. 阻塞/剩余问题。

全部通过后输出：

`Round 14A Flutter auth and onboarding visual acceptance closure passed`
