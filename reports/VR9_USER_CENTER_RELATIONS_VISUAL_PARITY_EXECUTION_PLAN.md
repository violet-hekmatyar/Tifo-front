# VR9 用户中心与关注关系一比一视觉复刻执行计划

状态：**VR9-R2-E3 已通过 Plan 模型最终复验；VR9 已完成并关闭；VR10 尚未制定**
前置：VR8 已通过并关闭  
目标：使用真实 API 和受控 DEMO 数据，将本人主页、本人发布、公开用户主页、关注列表和粉丝列表对齐对应原型。

## 1. 本阶段原型与范围

纳入 5 张原型：

- `C:\Users\hekmatyar\Desktop\足球APP\我的-首页.png`
- `C:\Users\hekmatyar\Desktop\足球APP\我的-发布.png`
- `C:\Users\hekmatyar\Desktop\足球APP\我的-其他用户主页.png`
- `C:\Users\hekmatyar\Desktop\足球APP\我的-我的关注.png`
- `C:\Users\hekmatyar\Desktop\足球APP\我的-我的粉丝.png`

主要前端范围：

- `apps/mobile/lib/features/user_center/presentation/pages/my_profile_page.dart`
- `apps/mobile/lib/features/user_center/presentation/pages/public_user_page.dart`
- `apps/mobile/lib/features/user_center/presentation/pages/user_relations_page.dart`
- `apps/mobile/lib/features/user_center/presentation/pages/user_list_page.dart`
- 必要的用户中心 model/controller/API 解码调整及用户中心专用组件
- `apps/mobile/assets/ui/profile/` 与 `pubspec.yaml` 中该资产登记
- 用户中心定向测试和 VR9 证据目录

允许的数据库范围仅为一组 VR9 专属 DEMO 关系补数脚本：

- `D:\Football-APP\scripts\sql\VR9_M1_USER_RELATION_SEED.sql`
- `D:\Football-APP\scripts\sql\VR9_M1_USER_RELATION_VALIDATOR.sql`
- `D:\Football-APP\scripts\sql\VR9_M1_USER_RELATION_ROLLBACK.sql`
- `D:\Football-APP\scripts\sql\VR9_M1_USER_RELATION_MANIFEST.md`

明确排除：

- `我的-设置.png`、`我的-设置-账号与安全.png`、登录、协议弹窗、消息与互动通知；
- 手机验证码、一键手机号登录、微信登录；
- 私信、聊天会话、IM、WebSocket、Push；
- 完整杯赛淘汰树；
- Feed、内容详情、发布、足球数据与详情页的视觉改造；
- 新增浏览记录业务、伪造不可用按钮或修改现有 API 路径/字段语义。

## 2. 必须保留的业务边界

1. 继续使用现有用户中心 Repository、Controller、路由和 API；不得为视觉复刻新造接口。
2. `/api/app/users/me/stand` 已返回关注数、粉丝数、内容数和获赞数；允许在前端 `UserStand` 中补解码这些既有字段，不要求后端改契约。
3. 本人主页原型中的“浏览记录”当前没有业务能力，不得制作死按钮。保持相同三按钮布局，但使用真实可用动作：编辑资料、我的关注、我的粉丝。
4. 公开用户主页使用真实关注/取消关注状态；不得显示本人的设置或编辑入口。
5. 设置齿轮仅保持跳转现有 `/settings`，本阶段不改设置页面。
6. 内容列表继续复用 VR1 已验收的 `ContentCard`、真实封面和作者信息；用户中心只调整外层网格、间距与叠加元素。
7. loading、empty、error、restricted、retry、分页和返回后的 Tab/滚动状态不得回归。

## 3. 顺序执行模块

### M0：基线、原型量测与目标数据确认

1. 记录前后端当前 commit、工作树已有改动和当前 APK 哈希，不覆盖用户已有修改。
2. 对 5 张原型建立量测表，设计基准为 375×812dp；核心尺寸至少包括：
   - 沉浸式主页头部约 268dp；
   - 头像约 75dp，主队队徽为头像右下角小徽标；
   - 三个统计项、三枚半透明操作按钮和约 43dp Tab 区；
   - 关系页约 40dp 搜索框、约 44dp 头像、约 64～72dp 行高和右侧关系按钮；
   - 主页内容区双列间距、圆角和底部导航覆盖安全区。
3. 使用一个已有、完成 onboarding 的 DEMO 账号作为本人目标；选择一个非本人 DEMO 用户作为公开主页目标。记录业务 userId，不在报告中写密码或 token。
4. 登录态只读检查以下接口和媒体 URL，记录 records/total/pages：
   - `/api/app/users/me/summary`
   - `/api/app/users/me/stand`
   - `/api/app/users/me/contents`
   - `/api/app/users/{id}/profile`
   - `/api/app/users/{id}/contents`
   - `/api/app/users/{id}/followings`
   - `/api/app/users/{id}/followers`
5. 运行并记录用户中心现有定向测试基线；测试原本失败时先报告，不得用删断言或改假数据掩盖。

完成门槛：目标账号、公开用户、真实图片、内容和关系数据均可定位；量测表完成后才能改页面。

### M1：最小 DEMO 关系数据补齐

目标是让本人目标账号的关注和粉丝页各有不少于 8 条可见真实记录，并覆盖 `FOLLOWING`、`FOLLOWED_BY`、`MUTUAL` 等现有关系语义。

1. 只复用现有 DEMO 用户与头像，不新增账号，不修改密码、onboarding、P1～P3 数据或非 DEMO 数据。
2. Seed 只插入 VR9 专属 ID 范围内缺失的 `follow_record`；执行前必须验证目标和关系用户均属于既有 DEMO 数据，ID 冲突或目标不满足条件即 `SIGNAL` 停止。
3. 不删除、覆盖或停用既有关系；Seed 连续执行两次结果一致。
4. 如头部粉丝数使用 `user_profile.follower_count`，只允许将目标 DEMO 用户该字段重算为当前有效入向 USER 关系数；不得写固定展示数字。
5. Rollback 仅删除 VR9 专属关系行，并根据回滚后的有效关系重新计算目标 DEMO 用户粉丝数；不得恢复成硬编码旧值。
6. Validator 检查：专属行数、唯一性、两页各 ≥8 条、关系方向、目标账号统计与有效关系一致、非 DEMO 泄漏为 0。
7. Seed 和 Validator 各连续执行两次；未得到 Plan 指示不得执行 Rollback。

完成门槛：数据幂等、可回滚，两个关系列表和头部统计由真实 API 一致返回；不要求新增 Java 或数据库结构。

### M2：本人主页与看台结构复刻

1. 将普通 AppBar + 渐变块改为原型式沉浸头部：复用项目已有 `cover-stadium.png` 作为本地 profile 背景资产，叠加深青绿色遮罩，状态栏透明且图标清晰。
2. 头像、昵称、主队小队徽、关注/粉丝/获赞、简介、设置齿轮按原型层级排列；长昵称和长简介必须省略或自然换行。
3. 从既有 `/me/stand` 解码真实 `followingUserCount`、`followerCount`、`contentCount`、`likeReceivedCount`；接口字段缺失时安全回退 0，不硬编码。
4. 三枚半透明操作按钮使用真实入口：编辑资料、我的关注、我的粉丝；点击与返回正常。
5. 保留 5 个 Tab：看台、发布、点赞、收藏、评论；白色圆角内容面板从头部底部衔接，选中项绿色短下划线。
6. 看台页改为三张原型式大卡：我的主队、我关注的球队、我关注的球员。使用真实队徽/头像预览、绿色淡底图标、说明文案和箭头，分别进入现有详情或管理页。
7. 保留编辑资料、换头像、刷新、局部错误重试能力，但不要把它们堆成破坏原型的常驻大按钮；必要动作可放入设置或语义明确的弹层。

完成门槛：`我的-首页` 的头部、Tab、三张看台卡和底部导航结构与原型一致，所有展示来自真实 API。

### M3：本人发布与内容 Tab 收口

1. 发布 Tab 使用双列瀑布式内容卡，复用真实封面、标题、作者、点赞和评论数据；移除用户中心额外叠加的无意义右上角箭头。
2. 卡片圆角、列间距、纵向节奏、图片比例和浅灰背景向 `我的-发布.png` 对齐；不得复制原型中的固定文案和数值。
3. 单列降级仅用于宽度不足或 140% 字体确实无法安全双列的场景；标准 Pixel 8 必须双列。
4. 点卡片进入真实内容详情；刷新、分页、空态、失败重试和返回后的滚动位置保持。
5. 点赞、收藏、评论 Tab 沿用同一头部和 Tab 体系，不要求为本阶段额外制作原型证据，但不得发生布局或交互回归。

完成门槛：本人主页在看台/发布之间切换不重载头部，不丢滚动状态；发布页首屏密度与原型接近且封面可见。

### M4：公开用户主页复刻

1. 复用本人页的沉浸头部组件，但以公开用户数据呈现头像、主队徽标、昵称、简介、关注/粉丝/获赞。
2. 顶部提供可返回入口，不显示本人设置、编辑资料或换头像动作。
3. 三枚操作按钮使用真实能力：关注/已关注/回关状态、该用户关注、该用户粉丝；busy 时禁用，失败时回滚并显示可理解提示。
4. 保留公开页 3 个 Tab：发布、收藏、评论；发布默认选中并使用同一双列内容卡。
5. 自己、未关注、已关注、被关注、互相关注及不可关注未知状态均要有明确安全显示；不得把未知状态当成功。

完成门槛：`我的-其他用户主页.png` 的视觉结构成立，真实关注动作与头部计数状态一致，返回后列表关系状态同步。

### M5：关注与粉丝列表复刻

1. 页面改为白色顶部、左侧返回、居中的“关注/粉丝”双 Tab；去掉重复的“关注与粉丝”标题。
2. 搜索框使用原型浅灰胶囊样式，根据 Tab 显示“搜索已关注的人”或“搜索粉丝”；清空按钮和键盘返回正常。
3. 用户行使用约 44dp 真实头像、昵称、单行简介和右侧紧凑关系按钮；取消外层 Card 阴影，按原型留白排列。
4. `已关注` 使用浅灰按钮，`关注/回关` 使用绿色实心按钮，`互相关注` 使用明确但不过宽的状态；busy 防重复提交。
5. 切换 Tab、输入搜索、滚动并返回时分别保持状态；本地搜索只过滤已加载数据，不改变服务端分页源。
6. 保留 restricted、empty、failure、retry、分页到底和用户详情跳转；关注操作失败必须恢复原状态及原计数。

完成门槛：关注和粉丝两页首屏各至少展示 8 条真实记录，视觉密度接近原型，关注状态和 API 一致。

### M6：定向验证、最终 APK 与视觉证据

1. 新增 VR9 视觉/几何测试，至少断言：
   - 主页头部、头像、Tab 和操作区在原型目标 ±8% 内；
   - 三张看台卡顺序和路由正确；
   - 标准宽度发布为双列，360dp/140% 无 overflow；
   - 本人/公开主页动作隔离；
   - 关注、取消关注、回关、busy、失败回滚和计数更新；
   - 关注/粉丝 Tab 的查询、滚动与选择状态保持；
   - loading/empty/error/restricted/retry/pagination 不回归。
2. 运行本阶段相关测试：用户中心 F16/F17/F18、VR9 新测试、路由与共享 `ContentCard` 回归；记录准确通过项数。只修复本阶段引入的失败。
3. 运行 `flutter analyze` 与前后端 `git diff --check`。
4. 真实 API smoke 覆盖 M0 七个只读接口及头像/队徽/封面；关注动作使用一个 DEMO 目标完成一次真实切换并恢复原状态，前后关系和计数必须一致。
5. 从最终源码构建并安装同一个 APK，记录完整 SHA-256。所有正式图必须来自该 APK。
6. 证据目录：`reports/VR9_USER_CENTER_RELATIONS_VISUAL_PARITY_EVIDENCE/`。至少采集：
   - `01_my_stand.png`
   - `02_my_posts.png`
   - `03_public_user_posts.png`
   - `04_following.png`
   - `05_followers.png`
   - `06_public_follow_state.png`
   - `07_360dp_my_profile.png`
   - `08_360dp_relations.png`
   - `09_140_percent_my_profile.png`
   - `10_140_percent_relations.png`
7. 生成 5 张直接双栏 comparison：每张只能使用对应原型原始 PNG 和当前 APK 原始截图，等宽保持比例，不得嵌套旧 comparison 或使用 fixture。
8. `VISUAL_COMPARISON.md` 逐图记录结构、几何目标/实际/误差、真实数据来源及差异；核心几何超过 ±8% 不得宣布完成。
9. 结束后恢复设备为 1080×2400、density 420、font scale 1.0。

完成门槛：代码/API/数据验证、5 张标准原型证据、360dp/140% 证据、同 APK 哈希和人工逐图对照全部闭合。

## 4. 阶段通过条件

以下条件必须同时满足：

- 5 张纳入原型均有当前最终 APK 原始截图和直接双栏对照；
- 本人主页、公开主页、关注与粉丝均使用真实 API，不在 Widget 中写死演示业务数据；
- 用户头像、主队队徽和内容封面实际可见，失败时安全降级；
- 关系补数脚本幂等、可回滚、非 DEMO 泄漏为 0；
- 关注操作、计数、分页、搜索、返回和滚动状态正确；
- 360dp、140% 字体无 overflow、遮挡或不可点击；
- 定向测试、`flutter analyze`、真实 API smoke 和两仓 `git diff --check` 通过；
- 未修改设置、登录、消息、IM、淘汰树或其他已验收页面；
- 执行模型只提交 Plan 模型复验，不自行宣布 VR9 通过或进入 VR10。

## 5. 交给执行模型的精简提示词

任务：执行 `D:\Football-APP-Front\reports\VR9_USER_CENTER_RELATIONS_VISUAL_PARITY_EXECUTION_PLAN.md`，完成本人主页、本人发布、公开用户主页、关注和粉丝 5 张原型的真实 API 视觉复刻。

范围：仅修改用户中心页面/model/controller/API 解码、profile 背景资产、VR9 测试与证据；数据库只允许 VR9 专属 DEMO 关系 Seed/Validator/Rollback/Manifest。设置、登录、消息、IM、Feed、足球页和淘汰树均排除。

要求：复用现有用户中心契约和 `ContentCard`；从既有 `/me/stand` 解码获赞等统计，不新增 API。本人头部使用真实编辑资料/关注/粉丝入口，不伪造浏览记录。关系数据只补目标 DEMO 账号，双跑幂等、可回滚、非 DEMO 泄漏为 0。按 M0→M6 顺序执行，每个模块完成后再进入下一模块。

完成标准：5 张当前 APK 标准图、5 张直接双栏对照、360dp/140% 证据、定向测试、analyze、真实 API/媒体、关系切换恢复、两仓 diff 和 APK 哈希全部通过。完成后仅提交 Plan 复验，不进入 VR10。

执行：直接按计划修改；只读取本阶段必要文件，不做全仓扫描或无关重构。最终仅汇报修改文件、完成结果、验证结果和阻塞/剩余问题。
