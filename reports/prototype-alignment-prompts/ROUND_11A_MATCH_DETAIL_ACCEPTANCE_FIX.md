# Round 11A：比赛详情验收缺口与评分并发收口

## 任务

在 `D:\Football-APP-Front` 主目录继续收口 Round 11。现有主体与测试已能通过，不重做页面；只修复本 Prompt 明确列出的真实缺口并补实质测试。全部完成前不得进入 Round 12。

除真实契约或权限阻塞外持续执行。测试失败、夹具不足和范围内代码缺陷不是阻塞，必须修复并重跑；不得用修改测试名称、合并编号、skip 或弱化断言代替覆盖。

## 范围

只读取/修改：

- `apps/mobile/lib/features/football/presentation/controllers/match_detail_controllers.dart`
- 确有必要时修改 `presentation/pages/match_detail_page.dart`
- 六个现有 F15 比赛详情测试文件，重点是 controller、sections、rating
- 不修改后端、数据库、API 契约、其他页面或共享架构，不新增依赖

## 必须完成

### 1. MATCH-09：阵容刷新失败保留

- 在已有成功阵容上触发 refresh 网络或 BusinessException；旧的主客阵容必须继续可见，并出现刷新错误与原位重试；
- 重试成功后错误消失且阵容更新；初始失败/重试能力继续保留；
- 测试断言旧记录、错误 Key、重试调用次数和成功后的新值，不能只检查初始失败。

### 2. MATCH-11：排名独立失败与刷新

- 对 ranking 所使用的独立 overview controller 建立可控失败夹具；
- 覆盖初始失败→只重试排名→成功；
- 覆盖已有 `CURRENT_STANDING` 后刷新失败仍保留旧排名、显示刷新错误、原位重试后更新；
- 证明排名失败不遮蔽其他 Tab，其他资源调用次数不因排名重试增加。

### 3. MATCH-15：球队统计与球员统计完整双向隔离

用 Widget 行为测试分别覆盖：

1. team stats 失败、player stats 成功；
2. player stats 失败、team stats 成功；
3. 两者同时失败。

每种场景都要断言成功模块仍可见、失败模块错误与 retry Key 可见；在同时失败场景，先重试其中一个只能增加该资源调用并恢复该模块，另一错误继续保留，再独立恢复另一个。现有泛型 controller 状态测试不能替代这三种页面行为。

### 4. MATCH-16/MATCH-18：评分读取、筛选与刷新竞态

- 真实点击“全部/主队/客队”筛选，断言 repository 收到 `null/homeTeamId/awayTeamId`，列表只显示最后筛选结果；
- 用两个可控 Completer 让旧筛选后返回，证明旧响应不能覆盖最新筛选；
- 覆盖 ratings 初始网络失败和 BusinessException 后重试；
- 覆盖已有列表刷新失败保留旧记录、显示反馈、重试成功更新；
- nullable、空 distribution、NaN/Infinity/负评分保持安全显示；有效/无效球员跳转继续正确。

### 5. MATCH-17/MATCH-18：不同球员并发评分不能互相覆盖

当前 `_write` 基于各请求开始前的 `before.records/busyPlayerIds` 回写；两个不同球员同时提交且逆序完成时，后完成请求可能覆盖先完成结果或清掉另一请求 busy 状态。修复为按完成时的当前 state 合并：

- 同一球员 busy 时拒绝重复写；不同球员允许并发；
- 任一成功只更新自己的记录、移除自己的 busy，保留另一球员的最新记录和 busy；
- 任一网络/BusinessException 失败只回滚自己的写操作并移除自己的 busy，不回滚另一球员已成功的权威值；
- `clearMessage` 等状态复制不能意外清空仍在进行的 busy、refresh 或筛选上下文；
- 无效 matchId/playerId 仍为零请求。

至少用两个球员、两个 Completer 覆盖：逆序双成功；一成功一网络失败；一成功一 BusinessException；并断言每一步 records、busy 集合、请求次数和错误反馈。

## 验收

原有 MATCH-01～MATCH-22 测试不得回归。新增测试名称准确标记对应编号，但以行为断言为准。不要为凑测试数量拆分空测试。

完成后统一执行：

1. `flutter analyze`
2. 一条命令显式运行以下六个文件：
   - `f15_match_detail_api_test.dart`
   - `f15_match_detail_widget_test.dart`
   - `f15_match_detail_controller_test.dart`
   - `f15_match_detail_sections_widget_test.dart`
   - `f15_match_detail_responsive_widget_test.dart`
   - `f15_match_rating_controller_test.dart`
3. `git diff --check`

## 最终仅汇报

1. 修改文件；
2. 五项缺口的修复结果；
3. MATCH-09、11、15、16、17、18 的新增实际测试名称、关键断言与结果；
4. 六文件联合测试的准确测试总数；
5. analyze、diff check 与阻塞。

仅在上述全部完成后输出：

`Round 11A Flutter match detail acceptance closure passed`
