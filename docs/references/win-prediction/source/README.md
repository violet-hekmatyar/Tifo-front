# 原始数据说明

本目录保存抓取到的原始数据，供追溯业务规则与 UI 数值。**不是**人工整理的结论，未做二次改写（仅清理换行与空白）。

## 文件

| 文件 | 来源 | 内容 |
| --- | --- | --- |
| `feishu-doc.txt` | 飞书 wiki | 正文纯文本，191 个内容块，约 9.2 KB |
| `feishu-blocks.json` | 飞书 wiki | 每个块的 `type`、`text`、绝对 `y`、`tag`，保留顺序 |
| `prediction-1-texts.json` | 蓝湖预测1 的 Figma JSON | 46 个文本节点的 `value`、`size`、`color`、`x/y` |
| `prediction-2-texts.json` | 蓝湖预测2 | 71 个文本节点（含被弹层遮住的底层页面） |
| `prediction-3-texts.json` | 蓝湖预测3 | 42 个文本节点 |

## 蓝湖接口

项目 ID：`0db55f49-842b-4b61-9e29-126afcda1977`；团队 ID：`22ef8dbb-4c21-4b1c-8acc-8dfe501236ba`；预测分组：`6c00df47-4f1f-4465-9f54-9e2d469dfeec`。

```text
GET https://lanhuapp.com/api/project/project_sectors?project_id=0db55f49-842b-4b61-9e29-126afcda1977
GET https://lanhuapp.com/api/project/image?image_id=<image_id>&project_id=<project_id>&team_id=<team_id>
```

- `project_sectors` 返回 `data.sectors[]`，每个 sector 含 `id/name/images[]`；`images` 是**图片 ID 字符串数组**，不是对象。
- `image` 返回 `result.name/width/height/url/versions[]`：
  - `result.url`：封面 PNG；
  - `versions[0].url`：整页 PNG；
  - `versions[0].json_url`：Figma JSON（`https://alipic.lanhuapp.com/FigmaJSON<md5>.json`）。
- JSON 与 PNG 都在公开 OSS；**PNG 直接下载会 403**，需带 `Referer: https://lanhuapp.com/` 和浏览器 UA。

| 页面 | image_id | 设计尺寸 | 对应文件 |
| --- | --- | --- | --- |
| 球比赛详情-预测1 | `ec509530-bd73-4cce-b344-7859b2d81d18` | 187.5×461 | `json/prediction-1.json` |
| 球比赛详情-预测2 | `100cde83-027a-4eeb-b69d-e6cda76e52fe` | 187.5×406 | `json/prediction-2.json` |
| 球比赛详情-预测3 | `6d6cf1ef-f9a3-416c-a000-b7a43c9e4f5f` | 187.5×461 | `json/prediction-3.json` |

> 蓝湖接口里的 `width` 是 CSS 宽度（187.5 = 375pt 的 50% 缩放展示）；画板实际为 375×922 / 375×812。`meta/` 下保存了原始响应。

## Figma JSON 结构

```text
{ meta, assets, artboard }
artboard.frame = { left, top, width: 375, height: 922 }
artboard.layers[] = shapeLayer | textLayer | groupLayer | artboard
```

- 文本：`text.value`；字体：`text.style.font.name/size/fontWeight`；颜色：`text.style.color.value`（rgba 字符串）。
- 文本坐标：`text.frame.left/top/width/height`，**已经是画板绝对坐标**，不要再累加父级 frame（累加会重复偏移）。
- 圆角：`radius` 全为 0，属 Figma 导入丢失，不可作为设计值。
- `meta.sliceScale = 4`、`meta.device = "iOS @1x"`。

## 飞书抓取

文档 URL：

```text
https://wxhs7el1zwu.feishu.cn/wiki/UB0rwzng1iHWCukZHtBc6MT7n7d?from=from_copylink
```

- 匿名可读，HTTP 200；标题《tifo比赛详情预测 Tab 功能需求初稿》，页脚“广州六边网科技有限公司”，标注“11月4日修改”。
- 阅读态使用虚拟滚动，DOM 中的 block 顺序不等于视觉顺序，需按绝对 `y` 排序：

```js
const container = document.querySelector('.bear-web-x-container');
const top = container.getBoundingClientRect().top;
// y = block.getBoundingClientRect().top - top + container.scrollTop
```

- 必须跳过三类重复内容：
  1. `data-block-type="page"`：其 `innerText` 包含整篇文档；
  2. `table_cell`：单元格文本会与表格整体重复；
  3. 表格内部嵌套的文本节点。
- 去重后得到 191 个有序块；正文按块类型换行拼接，得到 `feishu-doc.txt`。

> 首次用 `web_fetch` 抓取时被重定向到 `accounts.feishu.cn`，误判为需要登录；实际用浏览器打开是公开阅读态。**不要仅凭重定向判断登录墙。**

## 蓝湖批注

- 图片列表 `has_comment: false`。
- `POST https://lanhuapp.com/api/comment/v1/anchor/multi` 返回：

```json
{"code":0,"msg":"成功","result":{"anchors":[],"count":0}}
```

即这三张原型没有文字批注/评论，业务规则全部来自飞书文档。

## 复现提示

- 抓取脚本不在仓库内，位于 `D:\Football-APP\tmp\browser-driver\`（Playwright + Edge 持久化 profile），依赖本机蓝湖登录 Cookie，不适合提交到仓库。
- 修改含中文的 `.mjs` 时不要用 PowerShell `-replace` + `Set-Content`，会按 GBK 破坏 UTF-8（实测“预测”变“棰勬祴”）；用编辑器的 UTF-8 写入。
- 重新导出图片后，请同步更新 `images/` 与 `02-ui-spec.md` 中的尺寸说明。
