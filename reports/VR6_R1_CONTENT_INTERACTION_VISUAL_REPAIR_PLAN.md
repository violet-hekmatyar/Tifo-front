# VR6-R1 内容互动视觉收口计划

状态：**已执行；Plan 复验仍有关注样式与测试覆盖缺口，转入 VR6-R2**  
前置：VR6 数据、API、分享、评论/回复与输入功能成果保留  
唯一目标：关闭详情白色头部、评论全屏层、作者关注可见性和证据覆盖四项阻塞，使 VR6 可提交最终复验。

## 1. 修改范围

- `apps/mobile/lib/features/content/presentation/pages/content_detail_page.dart`
- `apps/mobile/lib/features/content/presentation/pages/content_interaction_page.dart`
- `apps/mobile/test/features/content/f05_detail_interaction_widget_test.dart`
- VR6 证据目录、执行记录和视觉对照记录

只有现有结构确实无法测试关注状态时，才允许最小调整直接相关的 public profile provider 注入点；不得复制用户 API 或修改契约。

禁止修改后端、数据库、VR6 Seed、API、Feed、发布编辑、选择器、搜索、登录、用户中心、消息、足球页面及 VR1～VR5 成果。不得借返修重排评论数据、增加第三方分享按钮或扩展功能。

## 2. R1-M1：详情与评论页面层级

1. 详情页状态栏和头部改为白色，返回、`南看台`和系统图标使用深色；标准、滚动后、360dp 和 140% 字体状态保持一致。
2. 根评论列表改为真正的独立全屏页面或全屏高层级层：覆盖详情页绿色/白色头部，顶部从系统安全区开始，底部到屏幕安全区结束。
3. 删除根评论入口中的 `.92` 高度限制或等价露底实现；评论工具栏保持返回、居中真实数量和分享，返回后保留详情滚动状态。
4. 回复列表仍使用接近全屏的圆角层，不把它强行改成根评论页面样式。

完成门槛：详情头部为白色；评论截图不再露出任何详情页头部或背景，且无额外顶部空白。

## 3. R1-M2：作者关注可见性与状态

1. 正式取证使用与内容作者不同的测试账号，使作者行显示真实“关注”或“已关注”按钮。
2. 未关注态按原型使用紧凑绿色圆角按钮；已关注态可使用较弱的描边/浅色状态，但尺寸和作者行基线不得跳动。
3. 继续复用 `UserCenterRepositoryContract.profile/follow`；成功后以服务端回读状态为准，busy 防重复，失败恢复旧状态并提示，自身作者隐藏。
4. 关注 smoke 必须成对恢复初始状态，不污染测试账号关系数据。

完成门槛：`01_detail_top.png` 清楚展示作者头像、昵称和关注按钮，按钮可操作且回读正确。

## 4. R1-M3：定向测试补强

在现有 VR6 测试上增加或收紧以下断言：

- 详情 AppBar/状态栏为浅色，文字与图标为深色；
- 根评论层顶部位于安全区、覆盖完整可用高度，底层详情头部不可见；
- 非作者显示关注、自己隐藏关注；关注成功、失败回滚和 busy 防重复在详情集成层可验证；
- 360dp 与 140% 字体分别实际打开分享、根评论、回复、根评论输入和指定回复输入，检查无异常、无 overflow，并验证返回链。

执行原 VR6 的 6 个测试文件。若未修改共享 `CommentSection`，不扩大到 F15；若触碰该共享组件，补跑直接相关 F15 section/widget 测试。执行 `flutter analyze` 和前后端 `git diff --check`。

完成门槛：原 29 项不得回退，新增断言全部通过；不得用扩大视口、降低字体、skip 或删除旧断言绕过。

## 5. R1-M4：真实运行与同 APK 证据

1. 固定内容 detail、hot/latest、replies、author profile 与至少 1 张 PNG 继续 `HTTP 200 + code=0`/`image/png`；不重复执行或修改 Seed。
2. 从最终源码重建、安装 APK，记录完整 SHA-256；除历史 `00_before_content_detail.png` 外，`01`～`09` 正式截图必须来自该 APK。
3. 必须重采：
   - `01_detail_top.png`：白色头部和真实关注按钮可见；
   - `02_detail_lower.png`：正文、关系和固定底栏完整；
   - `04_comments.png`：评论页真正全屏；
   - `08_width_360dp.png`、`09_font_140.png`：无 overflow。
4. 为证明互动层适配，新增 `responsive_360dp_layers.png` 和 `responsive_font_140_layers.png` 联系表；每张由同一 APK 的分享、评论、回复、根评论输入、指定回复输入五个实机画面组成。
5. 重新生成 6 张对照图；`comparison_01.png` 必须同时包含详情上半段和下半段，`comparison_03.png` 必须展示全屏评论结构。过程图移入 `debug/`。
6. 更新 `EXECUTION_RECORD.md` 与 `VISUAL_COMPARISON.md`，采证后恢复设备尺寸、density 和 font scale。

完成后只提交 Plan 模型复验，不自行宣布 VR6 通过，不进入 VR7。

## 6. 交给执行模型的精简提示词

任务：执行 `reports/VR6_R1_CONTENT_INTERACTION_VISUAL_REPAIR_PLAN.md`，关闭 VR6 四项视觉/证据阻塞。

范围：只改内容详情、内容评论层、F05 直接测试和 VR6 证据。详情改白色状态栏/头部；根评论改真正全屏；用非作者测试账号展示并验证绿色关注按钮；补齐关注集成、全屏几何及 360dp/140% 下分享/评论/回复/两种输入层测试。禁止修改后端、数据库、Seed、API、其他页面或下一阶段功能。

完成标准：原 29 项不回退且新增断言通过，analyze、API、成对关注恢复和两仓 diff 通过；新 APK 下重采 `01`～`09`、两张响应式联系表和 6 张对照，`comparison_01` 同时覆盖长页上下半段。完成后仅提交 Plan 复验。
