# 第 05D 轮执行 Prompt：评论、回复与输入体系完整收口

## 任务

在当前已通过的内容详情、固定互动栏、分享及 LIKE/FAVORITE 推荐行为基础上，一次完成评论列表、楼中楼回复、输入联动和行为级测试。不得再次修改已通过的分享流程，除非新增测试证明存在真实回归。

## 强制执行协议

按以下顺序执行，不要先输出长篇计划，也不要在首个失败后停止：

1. **基线核对**：只读允许范围内的详情页、评论 Widget、interaction controller/state 和已有测试，确认下方 CMT-01～CMT-12 各自的现有入口。
2. **阶段一**：完成详情滚动聚焦、权威计数、基础状态和对应测试；本阶段测试通过后进入阶段二。
3. **阶段二**：完成排序分页、点赞删除和对应测试；通过后进入阶段三。
4. **阶段三**：完成回复预览/弹层、回复选择、输入提交/失败恢复和对应测试。
5. **最终自检**：逐项核对 CMT-01～CMT-12，运行规定的最小验证；范围内的编译错误、测试失败、布局溢出都必须继续修复，不得包装成“剩余问题”。

只有缺少既有契约/必要权限、依赖外部服务，或继续处理将超出允许文件范围时才可停止并报告阻塞。单纯“工作量较大”“尚未补测试”“现有逻辑应该可用”均不构成阻塞。

## 原型参考

- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-评论区.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-评论区回复.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-回复评论区.png`
- `C:\Users\hekmatyar\Desktop\足球APP\资讯主页-回复评论区回复.png`
- 内容详情整体排版继续参考 `帖子详情.png`

## 当前基线与禁止回退

- `content_detail_page.dart` 的分享按钮只在 `DetailStatus.ready` 可用；复制 `/contents/{id}`、取消、成功提示已通过测试。
- 底部评论/点赞/收藏稳定 Key 已存在；点赞、收藏成功后会分别上报 LIKE/FAVORITE。
- `comment_section.dart` 已有 `comment_input` Key 和 FocusNode，但详情底部评论按钮尚未真正聚焦该输入框。
- 不得用 `items.length` 冒充评论总数；它只表示当前已加载条数。
- 不得弱化、删除或绕过现有 `f05_detail_interaction_widget_test.dart`。

## 修改范围

允许修改：

- `apps/mobile/lib/features/content/presentation/pages/content_detail_page.dart`
- `apps/mobile/lib/features/interaction/presentation/widgets/comment_section.dart`
- 仅在现有状态确实无法表达 UI 行为时，最小修改 interaction presentation controller/state
- `apps/mobile/test/features/content/` 与 `apps/mobile/test/features/interaction/` 下的定向测试及测试 fake

禁止修改 Repository/API/domain 契约、Feed、发布页、路由、后端、数据库、依赖和其他页面；本轮继续使用现有本地模拟/测试数据，不把原型示例硬编码进生产 Widget。

## 一、详情页与评论输入真实联动

1. 让详情页与 `CommentSection` 通过明确、可释放的 FocusNode/控制入口协作；禁止通过全局查找、延时碰运气或重复创建 FocusNode。
2. 点击底部 `content_detail_comment` 后，滚动目标必须是实际输入区而不是评论区外框；动画结束后 `comment_input` 获得焦点并可直接输入。
3. 处理输入区尚未构建、页面正在加载、Widget 已销毁等边界，不抛异常；FocusNode/ScrollController 生命周期正确。
4. 键盘弹出时输入框、回复目标和发送按钮保持可见，不被固定底栏或安全区遮挡。

## 二、评论标题、排序、分页与状态

1. 按原型整理评论标题、总数、热门/最新切换、列表间距、分隔线和绿色选中态。
2. 评论总数从详情 `commentCount` 或既有权威总数字段传入；数据不可用时显示普通“评论”，不得展示错误数字。
3. 完整呈现 loading、empty、failure/retry、ready、loadingMore、分页失败重试和到底状态；隐私/权限错误不得伪装成空列表。
4. 切换热门/最新时重置旧页和旧错误，再加载第一页；分页沿用 controller 的去重规则，不重复插入相同 comment id，不让旧排序结果污染新排序。
5. 评论项展示头像、昵称、时间、正文、点赞、回复入口及本人删除入口；空头像、nullable 时间/用户、长昵称、长正文和未知字段安全降级。

## 三、点赞与删除完整行为

1. 点赞继续使用现有 optimistic 流程：立即更新图标/数量，busy 时阻止重复请求，失败时恢复原状态并给出可见反馈。
2. 只有当前用户自己的评论显示删除入口；点击后必须出现确认弹层。
3. 取消确认不得调用删除；确认成功后刷新/移除对应评论并同步总数；失败时保留评论并显示重试友好的错误反馈。
4. 不改变 interaction repository 方法签名，不新增伪接口。

## 四、回复预览与楼中楼弹层

1. 根评论下使用浅色圆角区域展示已有回复预览，包括回复者、可空的“回复 @昵称”、正文及安全省略。
2. `replyCount` 大于已展示数量时显示“查看全部 N 条回复”；计数为空或为零时不制造入口。
3. 点击查看全部后打开圆角底部弹层：包含拖动手柄、根评论摘要、回复列表以及 loading、empty、failure/retry、分页加载、分页失败和到底状态。
4. 弹层遵守 SafeArea 与键盘避让；长回复和 1.4 倍字体不溢出。
5. 点击“回复”或某条回复后，关闭弹层并等待退出完成，再滚动并聚焦详情输入框；输入区显示准确的“回复 @昵称”，并提供取消回复目标。
6. 提交继续使用现有 `parentId` / `replyToUserId` 语义：所有楼中楼回复归属根评论，不制造第三层数据结构。

## 五、输入、提交与失败恢复

1. 普通评论与回复共用输入区；稳定 Key 保持不变，保留既有最大长度规则、发送中禁用和防重复提交。
2. 纯空白内容不调用 repository；超长内容按现有规则阻止并提示，不静默截断。
3. 提交失败时保留文本、焦点和回复目标，使用户可以直接重试。
4. 提交成功后清空文本、退出回复态、刷新当前排序并调用现有 `onCommentCreated`，从而保留 COMMENT 推荐行为上报。
5. 普通评论和回复成功后都不得触发两次请求或两次行为事件。

## 六、必须补齐的行为级测试

完善 `f05_detail_interaction_widget_test.dart`，并新增或扩展 comment 专项 Widget 测试。测试使用可控制返回值和调用记录的 fake repository/controller，必须断言调用参数和用户可见状态，不能只断言 Widget 存在。

至少覆盖：

- 点击详情底部评论后滚动位置发生变化，且 `comment_input` 真正获得焦点。
- 权威评论总数显示正确；只加载一页时不误显示已加载条数。
- loading、empty、首屏失败→重试成功、热门/最新切换。
- 加载下一页成功且去重、分页失败→重试、到底状态。
- 点赞 optimistic、busy 防重复、失败回滚。
- 自己的评论删除取消/确认/失败；他人评论无删除入口。
- 回复预览、“查看全部”、回复弹层首屏失败重试、分页和到底。
- 选择根评论/具体回复后输入区显示正确对象，取消回复恢复普通评论态。
- 空白不提交；失败保留文本与回复目标；成功清空并只触发一次 COMMENT 回调。
- 412px、DPR 1、1.4 倍字体下无 overflow/exception，测试 teardown 正确恢复尺寸、DPR 和文本比例。
- 现有分享取消→再次打开→复制、ready/non-ready 分享状态、LIKE/FAVORITE attribution 测试继续通过。

## 验收矩阵（全部为强制项）

| 编号 | 可观察结果 | 必须提供的证据 |
| --- | --- | --- |
| CMT-01 | 底部评论按钮滚动到真实输入框并获得焦点 | Widget 测试断言滚动位置与 focus |
| CMT-02 | 评论标题使用权威总数，不使用已加载条数冒充 | 不等数量夹具测试 |
| CMT-03 | loading/empty/error/retry/ready 状态完整 | 状态切换 Widget 测试 |
| CMT-04 | 热门/最新切换清理旧结果 | repository 调用参数与页面结果断言 |
| CMT-05 | 分页去重、失败重试和到底正确 | 两页含重复 id 的行为测试 |
| CMT-06 | 点赞 optimistic、busy、防重复及失败回滚 | 延迟/失败 fake 调用测试 |
| CMT-07 | 删除权限、取消、确认成功与失败完整 | 当前用户/他人两组测试 |
| CMT-08 | 回复预览与“查看全部”计数正确 | replyCount 大于预览数测试 |
| CMT-09 | 回复弹层覆盖首屏和分页各状态 | 弹层 failure→retry 与 load more 测试 |
| CMT-10 | 选择回复对象、关闭弹层、聚焦输入及取消回复正确 | parentId/replyToUserId 断言 |
| CMT-11 | 空白、失败保留、成功清空及 COMMENT 回调正确 | 提交次数、文本与回调断言 |
| CMT-12 | 412px、1.4 倍字体无异常且既有详情互动不回归 | 布局测试 + 既有内容测试 |

## 执行约束

直接实现，只读取上述页面、interaction 调用链及对应测试所需文件。先补失败测试，再做最小生产修改；若现有 controller 已支持某行为则直接复用，不为测试新造生产抽象。

不得只报告“现有逻辑保持可用”后停止。只有评论滚动聚焦、排序分页、点赞删除、回复弹层、提交恢复和上述测试全部落地，05D 才算完成。若发现真实契约/状态模型阻塞，保留失败测试并报告准确文件、状态和缺口。

## 最小验证

- `flutter analyze`
- `flutter test test/features/content`
- `flutter test test/features/interaction`（若目录不能直接执行，则运行本轮所有 comment 定向测试文件）
- `flutter test test/features/content/f05_publish_return_route_test.dart`

不启动模拟器、不 build APK、不跑全仓测试、不运行旧阶段脚本。

## 最终仅汇报

1. 修改文件；
2. 评论/回复/输入完成结果；
3. CMT-01～CMT-12 对照表：每项填写实现文件、具体测试名称和通过/未通过；
4. 行为级测试数量；
5. 最小验证结果；
6. 阻塞/剩余问题；若有未完成项必须列编号且不得输出成功标志。

成功标志：
`Round 05D comment system completion passed`
