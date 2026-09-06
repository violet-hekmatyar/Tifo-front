# F18.3 推荐效果专项报告

## 核心结论

推荐链路真实可用：A 桶稳定使用 RULE_V2，B 桶在 Python 模型正常时使用 CF_V1；Python 停止后 B 桶不报错并自动降级到 RULE_V2，恢复后重新使用 CF_V1。不同主队偏好的两个用户 Top10 重合 5/10，已经有可见个性化差异；Top20 内容占 12/20，符合“内容为主”；Top30 六类卡片齐全。

效果仍有两个风险：样本用户的 Top10 仍有 50% 公共内容，且一次真实 EXPOSE 后 Top10 没有变化；另有过期比赛仍以 LIVE 状态获得高权重。这两项不影响服务可用性，但影响“推荐确实及时、持续变好”的业务证明。

## 运行模型

| 项目 | 实际值 |
|---|---|
| 健康状态 | UP |
| algorithmVersion | CF_V1 |
| modelVersion | CF_V1_b2da84652c |
| modelReady | true |
| 训练窗口 | 30 日 |
| 用户数 | 108 |
| 内容数 | 152 |
| 有效训练行为 | 2174 |
| 原始行为日志 | 7006 条，109 用户、230 个目标；六类行为均存在 |

## A/B 与样本选择

对 36 个现有 demo 用户逐一真实登录并读取 Feed attribution：16 个进入 A，19 个进入 B，1 个未完成可判定的实验上下文。选取主队不同的两个完成偏好用户进行对照。

| 项目 | A 样本 | B 样本 |
|---|---|---|
| 用户 | demo_user_04 | demo_user_01 |
| 主队 | 巴塞罗那 | 阿森纳 |
| 实验桶 | A | B |
| 算法 | RULE_V2 | CF_V1 |
| 模型 | 无 | CF_V1_b2da84652c |
| Top20 总候选 | 103 | 93 |
| 主队关联命中 Top20 | 4 | 4 |
| attribution 完整 | 20/20 | 20/20 |
| 相同用户重复 Top20 | 完全一致 | 完全一致 |

“完全一致”指相同用户、未插入新行为时重复请求的 20 个 cardKey 顺序一致；requestId/impressionId 每次重新生成，符合一次请求一组归因标识的预期。

## Top10 对照

| 排名 | A：巴塞罗那 / RULE_V2 | B：阿森纳 / CF_V1 |
|---:|---|---|
| 1 | CONTENT:16000000000000004 | CONTENT:16000000000000001 |
| 2 | CONTENT:16000000000000007 | CONTENT:16000000000000004 |
| 3 | CONTENT:16000000000000005 | CONTENT:16000000000000049 |
| 4 | DISCUSSION:16000000000000002 | DISCUSSION:16000000000000002 |
| 5 | CONTENT:16000000000000008 | CONTENT:16000000000000025 |
| 6 | CONTENT:16000000000000028 | CONTENT:16000000000000073 |
| 7 | CONTENT:16000000000000076 | CONTENT:16000000000000010 |
| 8 | HOT_COMMENT:17000000000000007 | HOT_COMMENT:17000000000000007 |
| 9 | CONTENT:16000000000000040 | CONTENT:16000000000000007 |
| 10 | MATCH:15000000000000012 | MATCH:15000000000000012 |

Top10 重合 5 项，重合率 50%。前三位明显随主队/模型变化；热门讨论、热门评论和直播比赛属于两人的公共探索内容。

## 类型与理由分布

### 卡片类型

| 范围 | A | B | 判断 |
|---|---|---|---|
| Top20 | CONTENT 12、MATCH 3、DISCUSSION 1、HOT_COMMENT 1、RANKING 3 | 相同 | 内容占 60%，为多数 |
| Top30 | CONTENT 18、MATCH 6、DISCUSSION 1、HOT_COMMENT 1、RANKING 3、PLAYER_RATING 1 | 相同 | 六类 renderer 均能拿到真实数据 |
| Match Top30 | LIVE 2、SCHEDULED 4 | LIVE 2、SCHEDULED 4 | 缺 FINISHED；且 LIVE 数据存在时效风险 |

### Top20 推荐理由

| 理由 | A | B |
|---|---:|---:|
| MAIN_TEAM | 5 | 4 |
| FOLLOWED_TEAM | 2 | 4 |
| FOLLOWED_AUTHOR | 6 | 5 |
| LIVE_MATCH | 2 | 2 |
| RANKING | 3 | 3 |
| HOT_DISCUSSION | 1 | 1 |
| HOT_COMMENT | 1 | 1 |

两位用户都明确命中主队、关注球队和关注作者，个性化理由不是空壳 attribution。

## Feed 四入口

| 入口 | 首屏记录/总数 | 类型 |
|---|---:|---|
| recommend | 20/93 | CONTENT 12、MATCH 3、DISCUSSION 1、HOT_COMMENT 1、RANKING 3 |
| news | 20/100 | CONTENT 20 |
| following | 20/88 | CONTENT 14、MATCH 6 |
| team（阿森纳） | 20/35 | CONTENT 20 |

四个入口均为真实 Backend V1 返回，均带页面 requestId；未制造前端卡片数据。

## 行为与 attribution

本轮对 B 用户首页第一条 CONTENT 执行了一次真实 batch EXPOSE：

| 字段 | 值 |
|---|---|
| algorithmVersion | CF_V1 |
| modelVersion | CF_V1_b2da84652c |
| experimentId / bucket | REC_HOME_V1 / B |
| requestId | 非空 UUID |
| impressionId | `requestId:CONTENT:16000000000000001` |
| position | 0 |
| 首次上报 | received 1 / saved 1 / duplicated 0 / rejected 0 |
| 原事件重复上报 | received 1 / saved 0 / duplicated 1 / rejected 0 |

数据库历史同时确认 CLICK、DETAIL、LIKE、FAVORITE、COMMENT、EXPOSE 六类均有真实记录，且现有 App 会把首页 EXPOSE 与请求 attribution 一起写入。需要注意：本轮单次 EXPOSE 后下一次 Top10 没有变化，因此近期曝光惩罚的“可感知效果”尚未由一次操作证明。

## Python 降级与恢复

以同一个 B 桶用户连续验证：

| 阶段 | algorithm | bucket | model | 首位 |
|---|---|---|---|---|
| Python 正常 | CF_V1 | B | CF_V1_43cc2077a8 | CONTENT:16000000000000001 |
| Python 停止 | RULE_V2 | B | null | CONTENT:16000000000000001 |
| Python 恢复 | CF_V1 | B | CF_V1_b2da84652c | CONTENT:16000000000000001 |

结论：降级可靠且实验桶保持 B，没有把服务不可用伪装为 A；恢复后模型重新加载成功。Flutter 全程只访问 8080，没有直连 8100。

## 推荐问题与建议

| 优先级 | 观察 | 下一步验证 |
|---|---|---|
| P1 | 过期日期的比赛仍为 LIVE 并获得 LIVE_MATCH 权重 | 修正比赛状态/演示数据时间后复测 Top30 |
| P2 | 两种主队 Top10 仍有 50% 重合 | 扩充球队/球员相关内容，观察重合率是否进一步下降 |
| P2 | 一次 EXPOSE 后 Top10 不变 | 连续滚动、实际曝光 3～5 次，记录每次 Top10 和分数变化 |
| 观察项 | Top30 没有 FINISHED 比赛 | 准备近期完赛且有赛后内容的数据，验证赛后提升分支 |

## 专项判定

**服务可用性通过，个性化基础通过，效果充分性有条件通过。** A/B、CF、RULE、降级、归因和幂等均真实闭环；但实时比赛状态和曝光抑制仍需下一轮用修正后的数据证明。

