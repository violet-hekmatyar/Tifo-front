# Round 12A：用户中心验收缺口与并发状态收口

## 任务

在 `D:\Football-APP-Front` 主目录继续收口 Round 12。现有主体和全部测试可运行，不重做视觉；修复两个已确认的生产状态问题，并把 USER-01～20 中名称与断言不一致的验收补成真实行为证据。全部完成前不进入 Round 13。

普通编译、测试、布局和夹具问题必须继续修复，不算阻塞。禁止靠改测试名、skip、删除断言、超宽视口或直接调用 fake repository 来冒充页面闭环。

## 范围

只修改 `apps/mobile/lib/features/user_center/**`、必要的现有 user center 路由和 `apps/mobile/test/features/user_center/**`。不修改后端、数据库、API 契约、Feed/ContentCard 生产布局、设置、通知、登录或其他业务；不新增依赖。

## Gate 1：修复两个确认问题

### A. 收藏/评论并发删除合并

当前 `UserListController.removeItem` 保存整份 `previous`，不同项目同时删除时，任一失败可能恢复旧快照，从而重新插入另一项已成功删除的记录或清除另一项 busy。

- 同一项 busy 时拒绝重复删除，不同项允许并发；
- 成功只确认自己的移除；失败只把自己的原对象恢复到原有稳定顺序；
- 逆序完成时保留另一项的最新成功/失败结果、busy、分页、refresh 和错误状态；
- 收藏和评论分别调用自己的 endpoint；无效 ID 不请求；
- 用两个对象和两个 Completer 覆盖双成功、一成功一网络失败、一成功一 BusinessException，并断言中间/最终 items、顺序、busy 和调用次数。

### B. 关注球队/球员使用权威返回值

`toggleEntity` 返回 `followed`，页面不能只要请求未抛错就删除：

- 仅返回 `false` 时移除并刷新 stand/summary；返回 `true` 时项目继续可见并提示仍处于关注状态；
- 网络/BusinessException 保留原项，无效 ID 零请求；
- 球队和球员都覆盖确认取消、取消弹层、busy 防重、成功移除、权威 true 保留、失败保留及有效/无效详情跳转；
- 测试必须 pump `FollowedEntitiesPage` 真实点击，不能直接调用 repository 后断言原对象没变。

## Gate 2：补齐 USER-01～05

- USER-01：Widget 渲染本人头部真实字段、nullable、长名、大计数；实际点击有效主队进入球队详情，无效 ID 不跳。
- USER-02：summary 与 stand 分别覆盖初始失败→独立重试成功；ready refresh 失败保留旧值和各自错误；只重试失败资源不增加另一资源调用。
- USER-03：整合现有 F16 证据并补 busy 重入零重复上传、上传网络失败、绑定 BusinessException、结果不确定 reconciliation、成功后页面显示新头像并刷新 `MyProfileController` 权威 summary。
- USER-04：补保存 pending 按钮禁用/零重复、网络与业务失败保留输入、成功 pop 并触发主页重读。现有测试只有校验和失败。
- USER-05：逐个点击本人五 Tab，断言选中态和对应数据源；看台主队/球队/球员的有效与无效跳转；确认没有浏览记录死入口。

## Gate 3：补齐 USER-06～09

- USER-06：412px 常规字体断言双列列宽、左右位置、独立高度、奇数最后半列；360px 常规字体及 412px 1.4x 分别断言单列；无封面图片区完全收起。当前测试没有启用 1.4x，也没验证奇数宽度/独立高度。
- USER-07：四类本人列表至少各覆盖 loading/empty/error/retry；用 Completer 制造旧 refresh 后返回并证明不覆盖最新请求；覆盖分页去重、防重、append 重试原页、到底、ready refresh 失败保留。当前只有发布列表 append。
- USER-08：实际点击 visible=true 的 known/unknown 内容并验证路由；visible=false、无效 contentId 不跳；评论有效/无效 ID 同样点击验证。
- USER-09：收藏与评论各自通过 Widget 二次确认，覆盖取消零请求、确认后的 busy/乐观移除/成功、失败回滚；加入 Gate 1 的并发场景。公开列表无删除/取消收藏操作。

## Gate 4：补齐 USER-10～13

- USER-10：公开头部、有效/无效主队跳转、三个 Tab 数据源；SELF 无关注按钮；40401 与网络错误区别、retry 成功、ready refresh 失败保留旧 profile。
- USER-11：favorites 和 comments 分别抛 40301 并显示 restricted；分别返回空页时显示真实 empty；切回 posts 保留内容和调用次数。
- USER-12：Widget 分别渲染 SELF/NONE/FOLLOWING/FOLLOWED_BY/MUTUAL/unknown 的按钮与文案；unknown/SELF 零 follow 请求。
- USER-13：主页关注、回关、取消关注、取消互关都经过确认；取消确认零请求；pending 防重复；成功采用权威 UserProfile；网络/BusinessException 回滚关系和 followerCount。

## Gate 5：补齐 USER-14～17

- USER-14：真实切换关注/粉丝并断言两个独立请求与选中态；两边搜索词独立保持，清空恢复；过滤不修改 records、page、hasMore。
- USER-15：保留不同用户并发测试，补 Widget 中四类关系按钮、确认和有效/无效用户跳转；逆序一成功一失败不互相覆盖。
- USER-16：两边分别覆盖 loading/empty/error/retry、ready refresh 失败保留、pagination/append retry/end、去重和旧请求竞态；Tab 往返保持 records、搜索词、实际滚动偏移与调用次数。当前仅测单页去重和无效 ID。
- USER-17：按 Gate 1B 完整验证球队/球员页，同时覆盖首屏 loading/empty/error/retry、刷新和媒体 URL。

## Gate 6：补齐 USER-18～20

- USER-18 必须通过真实 `UserCenterApi + MockWebServer/现有 API 测试设施` 验证 Result/PageResult、summary/stand/profile、四类内容、followings/followers、follow、toggleEntity；覆盖 40301、40401、nullable、unknown、空数组、ISO 时间、相对媒体字段。手工构造 model 和调用 resolver 不算 API 契约测试。
- USER-19：本人五 Tab、公开三 Tab、关注/粉丝两 Tab分别滚动到非零 offset，切走返回后断言 offset、records、page、筛选和调用次数；至少验证一条内容详情往返状态恢复。
- USER-20：在 360px、412px、DPR 1、1.4x 下逐个渲染本人五 Tab、公开三 Tab、关注/粉丝、关注球队和球员页；每个场景检查 SafeArea 与 `tester.takeException()`。不能只测公开主页。

测试 teardown 分别恢复 physicalSize、devicePixelRatio 和文字缩放。几何测实际位置/宽度/高度；缓存测 ScrollPosition；权限和错误让 fake/API 真实抛异常。

## 验证

开发中只跑必要单文件，完成后统一：

1. `flutter analyze`
2. `flutter test test/features/user_center`
3. 本轮不修改 ContentCard；如确有必要，必须说明并补跑 `f04_home_feed_widget_test.dart` 与 `f10_feed_card_renderer_test.dart`
4. `git diff --check`

## 最终仅汇报

1. 修改文件；
2. 并发删除与实体权威关注修复；
3. USER-01～20 新增/加强的实际测试名称、关键断言和结果；
4. 用户中心测试准确总数；
5. analyze、diff check、阻塞。

全部完成后才能输出：

`Round 12A Flutter user center acceptance closure passed`
