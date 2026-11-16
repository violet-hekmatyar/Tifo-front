# 赛事预测功能汇报

面向非技术老板的 8 页图文汇报。

## 文件

- `report.md`：可编辑的汇报源文件。改文字、改标题、调顺序都直接改这里。
- `report.pdf`：当前导出版（A4，8 页，含封面、页码）。
- `assets/`：汇报用图，替换同名文件即可更新 PDF。
  - `03-three-step.png`：三步流程图（赛前 / 判断面板 / 赛后）。
  - `02-prediction-sheet.png`：判断面板原图。
  - `05-real-matches.png`：7 场真实比赛样本。
  - `04-prototype-compare.png`：蓝湖原型 vs Android 模拟器。
  - `01-pre-match.png` / `03-post-match.png`：三态原图备用。

## 修改建议

1. 先改 `report.md`，确认文字和数据口径。
2. 如果替换截图，保持 `assets/` 文件名不变，再重新导出 PDF。
3. 当前 PDF 由 `report.html` 通过 Edge 打印生成；改完 MD 后需要重新生成 HTML 再打印，或让开发同事协助导出。
4. 汇报数据来自本机 `south_stand` 的真实赛果表；正式对外前请再核对一次赛果与时间。
