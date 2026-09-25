# VR9-M0 基线与目标数据记录

日期：2026-09-23

## 工作树与 APK 基线

- 前端 commit：`16c640e0d0d892a4f0d1053fd3ae2452b63ccc5d`
- 后端 commit：`343eac4a27a6a433e522bf8da2b226fdd153e5fe`
- 当前 APK：`apps/mobile/build/app/outputs/flutter-apk/app-debug.apk`
- 当前 APK SHA-256：`AA726522D8A9AFC6FD6CBA3A9EAC609E521D18E00DABE6C2FF74A991228798F9`
- 本阶段开始前保留工作树已有改动，不覆盖或回滚既有成果。

## 原型量测基准

五张原型均为 `750×1624` PNG，按计划以 `375×812dp` 作为设计基准。已确认的目标量级：

- 沉浸式主页头部约 `268dp`；头像约 `75dp`；三枚统计项和三枚半透明操作按钮；Tab 区约 `43dp`。
- 关系页搜索框约 `40dp`；头像约 `44dp`；用户行约 `64～72dp`。
- 本人发布和公开发布使用双列内容卡；底部导航覆盖安全区。

原型来源：`C:\Users\hekmatyar\Desktop\足球APP\我的-首页.png`、`我的-发布.png`、`我的-其他用户主页.png`、`我的-我的关注.png`、`我的-我的粉丝.png`。

## 真实 API 基线

后端已恢复并通过健康检查。使用已有完成 onboarding 的 DEMO 账号建立正常登录会话；凭据和 token 未写入本报告。

| 接口 | HTTP | code | 结果 |
| --- | ---: | ---: | --- |
| `/api/app/users/me/summary` | 200 | 0 | 当前用户 ID `10002`，昵称 Demo Fan |
| `/api/app/users/me/stand` | 200 | 0 | 关注球队 1 条，关注球员 1 条 |
| `/api/app/users/me/contents` | 200 | 0 | `total=2`，`pages=1` |
| `/api/app/users/10001/profile` | 200 | 0 | South Stand Editorial，公开用户候选 |
| `/api/app/users/10001/contents` | 200 | 0 | 当前 `total=0` |
| `/api/app/users/10001/followings` | 200 | 0 | 当前 `total=0` |
| `/api/app/users/10001/followers` | 200 | 0 | 当前 `total=0` |

目标本人固定为用户 `10002`。公开主页固定使用可公开读取的 DEMO 用户 `11000000000000001`（南看台小旗手），其资料接口 HTTP 200/code=0；关系补数只允许使用现有 DEMO 用户 ID `11000000000000001`～`11000000000000016`，不新增用户或内容。

## M0 结论

M0 的原型尺寸、代码入口、既有用户中心契约、本人账号和公开用户候选已确认。进入 M1 前只允许执行 VR9 专属关系 Seed、Validator 和随后定向 API 验证；不修改 API 契约或其他阶段数据。
