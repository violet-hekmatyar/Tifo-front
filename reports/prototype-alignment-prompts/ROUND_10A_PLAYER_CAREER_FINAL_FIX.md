# Round 10A：球员生涯最终收口

## 任务

继续在 `D:\Football-APP-Front` 主目录收口 Round 10。当前球员详情主体及 5 个专项测试文件 12 项均已通过，不进入 Round 11，不扩大重构；只修复最终审查确认的生涯文案问题，并补齐 PLAYER-15 的双向错误隔离证据。

普通测试或夹具失败不是阻塞，持续修复至全部通过。

## 范围

- `apps/mobile/lib/features/football/presentation/pages/player_detail_page.dart`
- `apps/mobile/test/features/football/f14_player_detail_sections_widget_test.dart`
- 仅当测试暴露直接问题时，可修改对应 player detail controller/model

不修改后端、API 契约、其他页面、依赖或既有测试语义。

## 必须完成

### 1. 修复重复租借文案

当前 `_HistoryTile` 的 subtitle 对 `history.loan` 连续追加了两次“租借”，真实 UI 会显示“租借 · 租借”。删除重复来源并保证：

- loan 为 true 时仅出现一次“租借”；
- current + loan 同时存在时分别出现一次，顺序清晰；
- loan 为 false 时不出现；
- 其他赛季、日期、号码、位置、出场、进球、助攻信息不回归。

补充对 subtitle 完整字符串或“租借”出现次数的断言，不能只用 `contains('租借')`。

### 2. 补齐 PLAYER-15 双向隔离

现有测试只覆盖 career 请求失败、teams 成功。增加反向场景并验证：

- teams 请求抛出 `AppNetworkException` 或 `BusinessException` 时，career totals、球队/赛季分组和切换仍正常展示；
- teams 错误只在“效力球队”子模块显示，不能替换整页或遮蔽 career；
- 点击 teams 子模块自己的“重试”只重新请求 teams，不额外刷新 career；
- 重试成功后错误消失、历史球队出现，career 原状态保持；
- 同时保留现有 career 失败、teams 成功以及 career 原位重试场景；
- 若两个资源同时失败，各自拥有可识别的错误与重试入口，点击其中一个不会误触另一个。可以加入同一测试或单独测试，但须通过稳定 Key/明确 finder 区分两个“重试”按钮，不能依赖模糊 `.first/.last`。

如当前子模块没有稳定 Key，请添加最小 Key：career 状态/重试、teams 状态/重试。不要改变数据结构或创建新 controller。

### 3. 保持既有验收

- PLAYER-01～PLAYER-14、16～18 原测试全部继续通过；
- 生涯“球队/赛季”切换不得新增 repository 请求；
- 有效/无效球队跳转、current/loan、日期及统计展示不回归；
- 360/412px 与 1.4x 布局不回归。

## 完成标准

- 生产 UI 不再出现重复“租借”；
- PLAYER-15 对 career→teams 和 teams→career 两个错误方向都有实质断言；
- 两个子资源同时失败时重试目标明确且互不污染；
- 无测试弱化、skip、生产 mock 或无关修改。

## 最小验证

完成后统一执行：

1. `flutter analyze`
2. `flutter test test/features/football/f14_player_detail_api_test.dart test/features/football/f14_player_detail_controller_test.dart test/features/football/f14_player_detail_widget_test.dart test/features/football/f14_player_detail_responsive_widget_test.dart test/features/football/f14_player_detail_sections_widget_test.dart`
3. `git diff --check`

不要运行整个 football 目录、全仓测试、模拟器或 APK。

## 最终仅汇报

1. 修改文件；
2. 重复租借文案修复；
3. PLAYER-15 双向隔离和定向重试测试证据；
4. 最小验证实际测试数量；
5. 阻塞/剩余问题。

全部通过后输出一次：

`Round 10A Flutter player career closure passed`

存在真实外部阻塞时不得输出成功标志。
