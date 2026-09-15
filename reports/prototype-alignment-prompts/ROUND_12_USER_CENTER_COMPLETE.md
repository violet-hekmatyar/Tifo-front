# Round 12：Flutter 用户中心与关注关系完整原型对齐

## 任务

在 `D:\Football-APP-Front` 主目录完整对齐本人主页、公开用户主页、内容列表、关注/粉丝列表、关注球队/球员及资料编辑。复用当前 Backend V1 `summary / stand / profile / contents / likes / favorites / comments / followings / followers / follow / avatar` 契约，不修改后端、数据库或接口。

本轮不是只改头部样式。按 Gate 0～7 连续完成生产实现和行为测试；除真实缺少契约、权限或外部服务外，不得因编译、布局、测试或夹具问题停止。全部 USER 编号通过前不得进入设置/通知轮次。

## 原型与范围

参考：

- `C:\Users\hekmatyar\Desktop\足球APP\我的-首页.png`
- `C:\Users\hekmatyar\Desktop\足球APP\我的-发布.png`
- `C:\Users\hekmatyar\Desktop\足球APP\我的-其他用户主页.png`
- `C:\Users\hekmatyar\Desktop\足球APP\我的-我的关注.png`
- `C:\Users\hekmatyar\Desktop\足球APP\我的-我的粉丝.png`

只修改：

- `apps/mobile/lib/features/user_center/**`
- 必要的 `app_router.dart` 路由适配
- 为复用已完成内容卡片、头像、媒体 URL、Design Token 所需的最小共享改动
- `apps/mobile/test/features/user_center/**`

不做设置页、账号安全、浏览记录、通知、私信/IM、手机号/微信登录；不新增依赖。原型中的“浏览记录”当前无正式契约，不能做死按钮、假列表或本地伪记录。本轮不改内容、球队、球员详情业务。

## Gate 0：契约、基线与路由

- 核对现有模型和十余条 repository/API 调用，不新增重复数据层，不把原型示例写进生产代码；
- 核对 SELF/NONE/FOLLOWING/FOLLOWED_BY/MUTUAL、40301、40401、nullable、相对媒体 URL、ISO 时间和分页语义；unknown relation 使用中性文案且不可误操作；
- 运行现有 `f07_*user_center*`、`f16_user_center_*` 基线，范围内失败直接修复；
- 无效 userId 不发 profile/list/follow 请求；本人相关路由必须使用真实登录用户 ID；保留现有深链 `/users/me/*`、`/users/:id/*`。

## Gate 1：本人沉浸式主页

- 按原型建立绿色沉浸式头部：设置入口、头像、昵称、用户名、简介、主队、关注数、粉丝数及真实可用统计；没有 `likeReceivedCount` 时不得把其他计数冒充“获赞”；
- 缺头像、空简介、空主队、超长中英文名和大数值安全；主队有效 ID 可进入球队详情，无效 ID 不响应；
- 头像点击或明确入口继续完成选择→上传→绑定，busy 防重；取消选择不报错，上传/绑定失败保留旧头像，成功刷新权威 summary；
- 简介/昵称进入现有编辑页，校验、保存 busy、失败保留输入、成功返回并刷新；
- header summary 支持 loading/empty/error/retry 和下拉刷新；ready 刷新失败保留旧主页并显示可重试反馈。

## Gate 2：本人五 Tab 与看台

- 在主页内形成稳定 Key 的“看台、发布、点赞、收藏、评论”五 Tab，选中态、内容区域和原型层级一致；窄屏可滚动；
- 看台使用真实 `mainTeam` 与 `UserStand.teams/players` 组合“我的主队、关注的球队、关注的球员”；空数组显示模块级空态，有效实体跳转，无效 ID 不跳；不得显示无能力的浏览记录入口；
- 发布、点赞、收藏、评论直接显示真实分页记录，不要求用户先进入第二层列表页；原有深链仍可打开同类列表并复用同一渲染组件；
- 五 Tab 首次按需加载，返回和切换保留已加载 records、页码、实际滚动偏移，不重复首屏请求。

## Gate 3：内容与互动列表

- 发布/点赞/收藏采用与首页一致的自然高度内容卡片或安全紧凑变体；412px 常规字体双列，360px 或 1.4x 字体单列，奇数项不拉伸；无封面收起图片区；
- 评论记录使用独立评论行，展示真实评论正文、内容标题和时间；有效内容 ID 跳详情，无效/不可见内容不误跳；
- likes 的 `visible=false` 明确展示不可见状态，不能伪装为空或允许进入；unknown contentType 安全；
- 我的收藏取消、我的评论删除必须二次确认、busy 防重、乐观移除、失败回滚并提示；公开用户列表不得出现删除/取消收藏操作；
- 每个列表覆盖 loading/empty/error/retry、refresh 失败保留、分页去重、防重、append 失败保留并重试原页、到底；快速切 Tab/路由时旧响应不覆盖当前请求。

## Gate 4：公开用户主页

- 使用同一视觉语言展示头像、昵称、用户名、简介、主队、发布/关注/粉丝/获赞真实计数和关系状态；有效主队可跳转；
- 公开主页仅有“发布、收藏、评论”三个 Tab；SELF 应安全回到本人语义或隐藏关注操作，不制造两套本人主页状态；
- 40401 显示用户不存在；网络/业务错误可重试；ready 刷新失败保留旧资料；
- favorites/comments 的 40301 必须显示独立隐私受限态，不能显示“暂无内容”，也不能影响公开发布 Tab；
- Tab 切换与内容详情返回保持 Tab、records、页码和滚动位置。

## Gate 5：主页关注关系

- 完整展示 SELF、NONE、FOLLOWING、FOLLOWED_BY、MUTUAL；按钮语义分别为无操作、关注、已关注/取消、回关、互相关注/取消；unknown 不允许发请求；
- 关注/回关和取消前使用清晰确认；提交时 busy 防重复；乐观状态与 followerCount 不能小于 0；
- 成功使用后端返回的权威 UserProfile；网络/BusinessException 失败回滚关系和计数并提示；快速重复操作不能串状态；
- 从公开主页进入子详情再返回不重复 profile 请求。

## Gate 6：关注与粉丝列表

- 对齐原型顶部“关注/粉丝”切换、搜索框和用户行；搜索只做当前已加载记录的本地昵称/用户名/简介过滤，不发明搜索接口，不破坏分页源数据；清空恢复完整列表；
- 用户头像、昵称、简介、关系按钮和详情跳转使用真实字段；无效/SELF ID 不跳转或发关注请求；
- 每行按 relationStatus 显示关注、回关、已关注、互相关注；取消需确认，busy 以 userId 隔离，不同用户可并发且结果不能互相覆盖；
- 行操作成功使用 follow 返回的权威 relationStatus 更新该用户；失败只回滚目标行，保留其他行结果；
- followings/followers 分别具备 loading/empty/error/retry/refresh/pagination/append retry/end、去重和竞态保护；切换及返回保持各自搜索词、records 和滚动偏移。

## Gate 7：关注球队/球员及响应式收口

- 看台卡片进入关注球队/球员页；展示真实图片、名称、subtitle，并可进入实体详情；无效 ID 不跳转或取消关注；
- 取消关注需要确认，按实体 ID busy 防重；成功刷新 stand/summary 并从当前列表移除，失败保留原项并提示；球队和球员错误、空态互不伪装；
- 本人/公开主页、五/三 Tab、内容双列、关注/粉丝和实体列表均在 360/412px、DPR 1、1.4x 字体及 SafeArea 下无 overflow；
- 不出现生产 mock、原型人物/数字、TODO、“后端未提供”、死按钮或隐私态伪装。

## 强制验收矩阵

在现有用户中心测试基础上新增 controller/profile/lists/responsive 行为测试。一个测试可覆盖关联场景，但每个编号必须有实际断言，不能仅检查文字存在。

| 编号 | 必须验证 |
| --- | --- |
| USER-01 | 本人沉浸头部真实字段、nullable、长名、大计数、主队有效/无效跳转 |
| USER-02 | summary 初始错误/重试及 ready 刷新失败保留；无效本人状态安全 |
| USER-03 | 头像取消、busy、成功、上传/绑定网络与业务失败保留旧头像并刷新权威值 |
| USER-04 | 编辑昵称/简介校验、busy、失败保留、成功刷新返回 |
| USER-05 | 本人五 Tab Key/选中态；看台主队、球队、球员真实空态与跳转；无浏览记录死入口 |
| USER-06 | 发布/点赞/收藏在 412px 自然双列、奇数项、无封面收起，360px/1.4x 单列 |
| USER-07 | 四类本人列表 loading/empty/error/retry/refresh/append/end、去重、防重与竞态 |
| USER-08 | likes visible/unknown；内容/评论有效与无效跳转安全 |
| USER-09 | 收藏取消、评论删除确认/busy/乐观/失败回滚；公开列表无删除操作 |
| USER-10 | 公开主页真实字段、三个 Tab、SELF/404/error/retry、主队跳转 |
| USER-11 | 公开 favorites/comments 的 40301 隐私态与真实 empty 严格区分，发布不受污染 |
| USER-12 | 五种关系及 unknown 的按钮/文案/零误请求 |
| USER-13 | 主页关注/回关/取消确认、busy、防重、权威成功、网络/业务失败回滚计数 |
| USER-14 | 关注/粉丝顶部切换、本地搜索、清空、分页源数据不被过滤破坏 |
| USER-15 | 用户行关系操作、有效/无效跳转、不同用户并发成功/失败状态隔离 |
| USER-16 | followings/followers 全状态、分页重试/去重/竞态及切换返回保持 |
| USER-17 | 关注球队/球员真实展示、实体跳转、取消确认/busy/成功移除/失败保留 |
| USER-18 | API 的 Result/PageResult、40301、40401、nullable、unknown、ISO 时间、相对媒体安全 |
| USER-19 | 本人五 Tab、公开三 Tab、关注/粉丝和实体页保持实际滚动偏移、筛选与调用次数 |
| USER-20 | 360/412px、DPR 1、1.4x 逐页面/Tab 渲染，SafeArea 与 `tester.takeException()` 无异常 |

几何测试必须断言列宽、列位置或单列降级；缓存必须断言实际滚动偏移和 repository 调用次数；权限测试必须让 fake 抛 40301；并发测试必须使用可控 Completer 逆序完成。测试结束分别恢复 physicalSize、devicePixelRatio 和文字缩放。

## 最小验证

开发中只跑必要单文件。完成后统一执行：

1. `flutter analyze`
2. 显式运行全部 `test/features/user_center` 测试文件
3. 若修改共享 ContentCard，补跑 `f04_home_feed_widget_test.dart` 和 `f10_feed_card_renderer_test.dart`
4. 若修改路由，补跑 `f07_router_test.dart`
5. `git diff --check`

不跑全仓、整个 football 目录、模拟器或 APK。

## 最终仅汇报

1. 修改文件；
2. 本人主页、公开主页、内容列表、关系列表、实体关注和资料编辑完成结果；
3. USER-01～USER-20 的实际测试名称、关键断言、结果；
4. 最小验证命令和准确测试数量；
5. 阻塞/剩余问题。

只有全部通过后输出：

`Round 12 Flutter user center completion passed`
