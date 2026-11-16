# 球队输赢预测（比赛详情「预测」Tab）资料包

本目录保存「球队输赢预测」板块的**业务规则、UI 规格、原型图与原始抓取数据**，用于产品评审、UI 还原和前端开发。

- **范围**：比赛详情页第 6 个 Tab「预测」——赛前概率判断、球迷共识、看台豆挑战、赛后复盘。
- **来源**：蓝湖原型 + 飞书 wiki 需求文档，均为 2026-11-15 抓取，**两个来源都无需登录**。
- **状态**：资料已归档；业务规则、UI 规格、前后端实现与 Android 模拟器截图比对已完成。实现说明见 [04-implementation.md](04-implementation.md)。

## 文档

| 文档 | 内容 | 适合谁 |
| --- | --- | --- |
| [01-business-rules.md](01-business-rules.md) | 定位、硬边界、状态机、判断/共识/洞察分/看台豆公式与算例、合规、检查清单 | 产品、后端、测试 |
| [02-ui-spec.md](02-ui-spec.md) | Token、布局尺寸、三屏逐区块规格、交互状态、原型缺口、验收点 | UI、前端 |
| [03-open-questions.md](03-open-questions.md) | 30 个待确认问题（P0/P1/P2）及建议默认值 | 产品、开发评审 |
| [04-implementation.md](04-implementation.md) | 数据表、接口、前端接入、运行命令、验证结果与已知差异 | 后端、前端、测试 |
| [老板汇报 MD](../../reports/prediction-module/report.md) · [PDF](../../reports/prediction-module/report.pdf) | 面向非技术受众的功能汇报，含三态截图、真实比赛样本与原型对比 | 老板、产品、运营 |
| [source/README.md](source/README.md) | 原始数据的接口、文件与提取方法 | 需要追溯的人 |

## 原型图

| 图 | 内容 |
| --- | --- |
| [三屏总览](images/00-lanhu-overview.png) | 蓝湖画布中的预测1/2/3 |
| [赛前预测页](images/01-pre-match.png) | 球迷共识、我的预测、看台挑战、更多预测 |
| [判断面板](images/02-prediction-sheet.png) | 概率滑杆、快捷选择、看台豆档位、提交 |
| [赛后复盘](images/03-post-match.png) | 洞察分、豆变化、赢点、判断轨迹 |
| [飞书文档首页](images/04-feishu-doc-top.png) | 需求文档标题与目录 |

原型图为 750px 宽（@2x，375pt 画板），总览与文档截图为 1440px；均已转为真实 PNG。

## 实现截图

本机 Android 模拟器截图（Pixel 8 / 1080×2400 / density 420），与原型三屏一一对应：

| 图 | 内容 |
| --- | --- |
| [赛前预测](implementation/01-pre-match.png) | 六 Tab、球迷共识、我的预测、看台挑战、更多预测 |
| [判断面板](implementation/02-prediction-sheet.png) | 三滑杆 64/22/14、快捷选项、30 豆、提交 |
| [赛后复盘](implementation/03-post-match.png) | 90 分、方向命中、+30 豆、判断轨迹 |
| [已提交态](implementation/04-submitted-state.png) | 提交后锁定态：待结算、已参与 30 豆 |

并排比对（左原型 / 右实现）：

| 图 | 内容 |
| --- | --- |
| [赛前比对](implementation/comparisons/01-pre-match-compare.png) | 三卡结构、底部 CTA 与原型一致 |
| [面板比对](implementation/comparisons/02-prediction-sheet-compare.png) | 滑杆、快捷选项、豆档位、挑战说明 |
| [赛后比对](implementation/comparisons/03-post-match-compare.png) | 复盘头卡、得分/豆卡、赢点、轨迹 |

## 业务速览

1. **入口**：比赛详情原有 5 个栏目后新增「预测」；不塞进总览或统计。
2. **三态**：未开赛可提交/修改；开赛锁定；结束后变「赛后复盘」。
3. **判断**：给主胜/平局/客胜分配概率，三项合计 100%，免费参与。
4. **洞察分**：`B = Σ(pᵢ - yᵢ)²`，`S = round(100 × (1 - B/2))`，0–100。
5. **看台挑战**：可选 10/30/50 豆，只挑战自己最高概率的结果；命中返还本金 + `C × R`，未命中扣除 `C`，取消返还。
   `R = min(0.8, max(0, (S - 60) / 50))`。
6. **硬边界**：不充值、不提现、不转赠、不交易、不做赔率/奖池/抽水、不做滚球/加注。

## 目录结构

```
docs/references/win-prediction/
├─ README.md                  # 本文件
├─ 01-business-rules.md       # 业务规则
├─ 02-ui-spec.md              # UI 规格
├─ 03-open-questions.md       # 待确认问题
├─ 04-implementation.md       # 实现、接口、运行、验证
├─ images/                    # 5 张 PNG（原型 3 屏 + 总览 + 文档首页）
├─ implementation/            # 4 张本机实现截图 + comparisons/ 并排比对
├─ json/                      # 3 份 Figma JSON（图层、颜色、字号、坐标）
├─ meta/                      # 蓝湖图片元数据、分组列表
└─ source/                    # 飞书正文、文本节点、原始 block
```

## 来源与访问

| 来源 | 链接 | 说明 |
| --- | --- | --- |
| 蓝湖分享邀请 | <https://lanhuapp.com/link/#/invite?sid=lx0j9hIg> | 打开后进入「足球APP」项目，分组「预测」 |
| 蓝湖项目 | <https://lanhuapp.com/web/#/item/project/stage?tid=22ef8dbb-4c21-4b1c-8acc-8dfe501236ba&pid=0db55f49-842b-4b61-9e29-126afcda1977&activeSectionId=6c00df47-4f1f-4465-9f54-9e2d469dfeec> | 项目 63 页，预测分组 3 页 |
| 飞书 wiki | <https://wxhs7el1zwu.feishu.cn/wiki/UB0rwzng1iHWCukZHtBc6MT7n7d?from=from_copylink> | 《tifo比赛详情预测 Tab 功能需求初稿》，11月4日修改 |

> 蓝湖页面顶部曾提示“由于打开过分享页，用户状态发生变化，为安全起见，请重新登录”，但项目树与图片数据均正常加载，因此没有要求登录。飞书文档可直接匿名阅读。

## 已知差异与注意

- 原型头图是**切尔西 vs 莱特斯城**，判断面板与共识却是**巴萨 vs 皇马**，属于占位数据混用；实现必须由同一场比赛驱动。
- 预测2 的共识 `40% + 28% + 26% = 94%`，与“合计 100%”矛盾；应以聚合数据为准。
- 预测3 写 `收益50豆`，但同卡是 `+30豆`、`1030豆`；按公式 50×0.6=30，`收益50豆` 应为文案错误。
- 预测3 已结束仍显示「写下我的判断」，与“结束后不再展示可操作按钮”冲突。
- 原型多处 `说明说明说明` 是占位文案，上线前必须替换。
- JSON 中所有圆角为 0（Figma 导入丢失），UI 规格中的圆角是目测值，不是设计标注。

## 建议下一步

1. 评审 [03-open-questions.md](03-open-questions.md) 剩余的 P0/P1，尤其是开赛前修改次数、挑战与免费判断的锁定关系、并列最高概率。
2. 补球队中文短名映射，消除 `Bayern胜`、`Real Madrid胜` 这类英文队名文案。
3. 增加进行中锁定态、未命中态、取消/延期态的视觉稿与回归用例。
4. 将 Maven 测试入口恢复：先修复仓库既有的 `FootballQueryServiceTests` 签名问题，再纳入预测单测。
