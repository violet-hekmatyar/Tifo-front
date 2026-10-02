# VR3 比赛详情后端最小支撑说明

状态：**纳入 VR3，先验证再最小实现**

目标比赛：`15000000000000060`（尤文图斯 2:0 AC 米兰）

本说明只列出完成比赛详情原型所需、当前契约确有缺口的后端能力。阵容、球队统计、球员统计和评分主体接口已经存在，不得重复造接口或修改既有含义。

## 1. 比赛关联内容查询

P1-M3 已有 5 条 `relation_type=MATCH` 的关联内容，但客户端没有按比赛读取它们的冻结接口。后端增加与球队/球员内容查询一致的只读分页接口：

`GET /api/app/football/matches/{matchId}/contents?contentType=&pageNum=1&pageSize=10`

要求：

- 复用现有 `content_relation` 与 ContentSummary 映射，不新增表；
- 仅返回 ACTIVE、未删除且客户端可见内容，按发布时间或关系 ID 稳定倒序；
- 支持 POST/ARTICLE 过滤、标准 PageResult、匿名读取；
- 对不存在比赛返回现有错误码，对无内容返回空页；
- 不在 `overview` 中塞入另一个不分页的大列表。

## 2. 球员单场评分讨论目标

API 文档声明评论支持 `PLAYER_RATING`，但当前 `CommentService.validateTargetType` 实际只接受 `CONTENT`。VR3 若要实现评分详情和评分输入中的评论，需要先消除这一契约冲突。

建议复用 `football_match_player_stat.id` 作为稳定 `ratingTargetId`：

- `/matches/{matchId}/ratings` 的每个球员评分项增加 nullable `ratingTargetId`；
- `GET/POST /api/app/comments` 接受 `targetType=PLAYER_RATING` 和该 ID；
- 后端校验目标记录存在、有效且属于对应比赛球员，不能仅放宽字符串白名单；
- 评论分页、回复、登录写入和现有 CONTENT 评论行为保持兼容；
- 点赞若当前契约仍不支持 PLAYER_RATING，不在 VR3 假装可用。

若评估后无法在本阶段安全建立稳定目标 ID，执行模型必须在报告中登记为后端阻塞，不得把 `matchId` 或 `playerId` 临时冒充评论目标。

## 3. 演示数据

- 复用 P1-M3 已有关联内容，不新增重复资讯；
- 可为旗舰比赛 1～2 名已有球员统计记录增加少量 DEMO `PLAYER_RATING` 根评论及回复；
- 新增数据必须使用独立 ID 区间、幂等 seed、validator、rollback 和 manifest；
- 不修改非 DEMO 评论，不改 P1-M1～M3 既有脚本。

## 4. 明确不做

- 不实现完整杯赛淘汰树业务模型或接口；
- 不增加视频上传/转码/播放能力；没有真实视频类型时，前端只把关联封面作为内容卡，不伪装可播放视频或虚构时长；
- 不修改比分、阵容、统计、评分数值或 Feed 排序。
