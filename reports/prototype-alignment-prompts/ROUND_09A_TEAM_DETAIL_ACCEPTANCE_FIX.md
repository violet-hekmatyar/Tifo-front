# Round 09A：球队详情真实验收收口

## 任务

继续在 `D:\Football-APP-Front` 当前主目录收口 Round 09。不要进入球员详情，也不要重做已经通过的球队详情主体。本轮必须修复复核确认的生产问题，并把 TEAM-01～TEAM-17 从“测试名包含编号”提升为实际行为证据。

当前 5 个球队详情测试文件共 10 项均通过，静态分析也通过；但这不等于 Round 09 已完成。除非发生缺少契约或权限等真正外部阻塞，否则持续修复、补测试并重跑，不能再次以“尚未覆盖”结束。

## 只处理以下范围

- `apps/mobile/lib/features/football/presentation/pages/team_detail_page.dart`
- `apps/mobile/lib/features/football/presentation/controllers/team_detail_controllers.dart`
- 只有测试暴露明确解析问题时才修改 `team_detail_api.dart` / `team_detail_models.dart`
- `apps/mobile/test/features/football/f13_team_detail_*`

不修改后端、数据库、API 契约、其他详情页、共享架构或依赖；不跑全仓测试、模拟器和 APK。

## 必修生产问题

### 1. ready 状态刷新失败反馈

`TeamPagedController.refresh()` 失败后保留旧 records 并写入 `state.message`，但当前 `_pagedBody` 在 ready 分支完全不渲染该 message。修复为：

- 动态、球员、赛程刷新失败后继续显示原列表；
- 列表顶部或合适位置出现可见、可重试的非阻塞错误提示；
- 重试调用 refresh，而不是清空数据后调用 loadInitial；
- 重试成功清除旧 message；
- 不与 append error 混淆，append error 仍在列表底部重试相同页。

### 2. 动态改为真实错落布局

当前 `_contentChildren` 使用固定 `childAspectRatio: .78` 的 `GridView`，会制造等高卡片和空白，并不能证明 Round 03 式双列错落。改为：

- 412px 常规字体下为两列独立高度内容流；不同封面/标题/摘要长度产生各自自然高度；
- 连续内容保持后端顺序，奇数最后一张保持半列宽；
- 360px 或 1.4x 大字体可安全降级单列；
- 不使用固定卡片高度、`IntrinsicHeight` 或超宽画布；
- 缺封面时图片区完全收起；长标题/摘要不越界；
- 内容 Key、点击和分页列表保持不变。

可以复用 Round 03 已有双列分配方式或抽取极小的 football 内部布局工具，但不要把 `TeamContentSummary` 伪装成缺字段的 Feed DTO。

### 3. 无日期赛程分组

当前 `_matchChildren` 的 `lastDate` 初始值为 null，首条 `matchTime == null` 时不会生成“日期待定”标题。修复并保证：

- 连续多条无日期比赛只出现一次“日期待定”；
- 有日期与无日期组均按现有排序稳定展示；
- 无日期比赛卡片仍可点击且不崩溃。

### 4. 关注状态边界

保持现有成功和 busy 防重复，同时验证并在必要时修复：

- 网络/业务失败后文案与按钮状态保持操作前值，并显示错误反馈；
- busy 在成功和失败后都恢复；
- 无效 teamId 按钮禁用且 repository 调用次数为 0；
- widget 更新为同一页面的新权威 followed 值时不得长期显示陈旧本地状态；若现有 provider 生命周期已保证页面重建，则用测试证明，否则实现最小同步，不要做乐观假成功。

### 5. 状态与极值安全

- 荣誉补齐 loading、empty、error/retry、ready；验证空年份、null 次数、unknown 类型不会出现错误次数或崩溃；
- Stats 测试必须覆盖所有实际字段至少一次，并覆盖负净胜球、0、null、NaN/Infinity、全空与部分有值；页面只能显示有限可解释值；
- unknown position/squadRole、租借无来源、长球员名、无效 playerId 均安全；
- 赛季没有真实候选列表时不出现可点击的假赛季选择器。

### 6. Tab 状态和响应式真实验证

- 在动态列表滚动到明显偏移，切换到其他 Tab 后返回；验证滚动位置基本保持、records 未清空、首屏请求次数仍为 1；
- 球员和赛程至少各验证一次切换返回不重复请求；
- 在 360px、412px、DPR 1、1.4x 字体下实际切换并渲染总览、动态、球员、数据、赛程，不是只在总览查五个 Key；
- 每个 Tab 调用 `tester.takeException()`，确保无 RenderFlex/Grid overflow；测试结束分别恢复 physicalSize、devicePixelRatio 和文字缩放。

## 强制测试修正

更新现有测试，使测试名称保持 TEAM 编号，但断言必须真正对应行为：

| 编号 | 本轮必须新增的实质证据 |
| --- | --- |
| TEAM-02 | 关注失败保持、busy 恢复、错误反馈、无效 ID 零调用；不能只有成功测试 |
| TEAM-05 | 荣誉 loading/empty/error/retry/ready 与 nullable/unknown；不能只有 error→ready |
| TEAM-07 | 412px 双列独立高度、奇数半列、缺封面收起，以及 360px/1.4x 单列降级的几何断言 |
| TEAM-09 | unknown/null position/role、租借/队长/统计、长文本、无效 ID；不能只查“门将/前锋”文字 |
| TEAM-11 | 全 stats 字段、负数、null、NaN/Infinity、部分空与全空的可见结果 |
| TEAM-14 | ready 刷新失败的页面可见提示、旧列表保留、原位重试成功并清除提示；补无日期分组 |
| TEAM-15 | 五个 Tab 分别在窄屏/大字体渲染并检查异常 |
| TEAM-16 | 实际滚动偏移恢复、三类分页 Tab 请求不重复；不能只验证 contentsCalls == 1 |

同时保持已有 TEAM-01、03、04、06、08、10、12、13、17 测试通过。如果新测试暴露生产问题，继续修复生产代码，不得删断言、skip 或只改测试夹具绕过。

## 完成标准

- 上述 6 组问题全部闭环；
- TEAM-01～TEAM-17 的测试名和实际断言一致；
- ready refresh error 用户可见且可恢复；
- 动态是独立高度错落流，不再是固定等高 Grid；
- 无日期比赛有且只有一个正确分组标题；
- 五 Tab 的滚动/请求缓存和大字体布局均有行为证据；
- 无生产 mock、假按钮、伪赛季选择和无关修改。

## 最小验证

完成后统一执行一次：

1. `flutter analyze`
2. `flutter test test/features/football/f13_team_detail_api_test.dart test/features/football/f13_team_detail_controller_test.dart test/features/football/f13_team_detail_widget_test.dart test/features/football/f13_team_detail_responsive_widget_test.dart test/features/football/f13_team_detail_sections_widget_test.dart`
3. `git diff --check`

不要运行整个 football 目录或全仓测试。

## 最终仅汇报

1. 修改文件；
2. 六组确定问题的修复结果；
3. TEAM-02、05、07、09、11、14、15、16 的实际测试名称与关键断言；
4. 最小验证实际通过数量；
5. 阻塞/剩余问题。

只有全部完成后输出一次：

`Round 09A Flutter team detail acceptance closure passed`

普通测试失败、测试夹具问题和布局异常不是阻塞；必须继续解决。存在真实外部阻塞时不得输出成功标志。
