# VR9-M1 关系数据执行记录

日期：2026-09-23

## 执行范围

仅执行后端 VR9 专属脚本，不修改 API、表结构、既有 P1～VR8 数据或非 DEMO 用户关系：

- `D:\Football-APP\scripts\sql\VR9_M1_USER_RELATION_SEED.sql`
- `D:\Football-APP\scripts\sql\VR9_M1_USER_RELATION_VALIDATOR.sql`
- `D:\Football-APP\scripts\sql\VR9_M1_USER_RELATION_ROLLBACK.sql`

固定目标用户为 `10002`；关系用户仅使用既有 DEMO 用户 `11000000000000001`～`11000000000000016`。

## 结果

| 检查项 | 第一次 | 第二次 | 结论 |
| --- | ---: | ---: | --- |
| VR9 保留关系行 | 20 | 20 | 幂等 |
| 目标用户关注数 | 10 | 10 | 通过 |
| 目标用户粉丝数 | 10 | 10 | 通过 |
| 互相关注 | 4 | 4 | 通过 |
| 仅本人关注 | 6 | 6 | 通过 |
| 仅本人粉丝 | 6 | 6 | 通过 |
| 非 DEMO 泄漏 | 0 | 0 | 通过 |

Seed 连续执行两次结果一致；Validator 连续执行两次通过。未执行 Rollback，因为当前阶段需要保留关系数据用于真实 API 和 Android 证据。

## API 复核

已使用已有完成 onboarding 的 DEMO 登录态只读复核：

- `auth/me`、`users/me/summary`、`users/me/stand`、本人内容、公开 profile、目标用户 followings/followers 均为 HTTP 200、`code=0`。
- 目标用户两个关系列表均返回 10 条真实记录，覆盖 `FOLLOWING`、`FOLLOWED_BY`、`MUTUAL`。
- 当前后端分页元数据对两个关系接口仍返回 `total=0/pages=0`，但 `records` 已真实返回 10 条；该现象未修改后端，留给 M6 客户端联调复核。

## 结论

M1 数据准备、幂等性、保护式校验和只读 API 复核通过，进入前端页面与 M6 证据阶段。
