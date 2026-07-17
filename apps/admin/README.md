# 南看台 Vue 管理后台

仅供内部管理员使用，不是面向普通用户的 H5。使用 Node 24.17.0、npm 11.13.0、Vue 3.5.40、TypeScript 6.0.3 和 Vite 8.1.5；包管理器固定为 npm。

F01 已接入 Vue Router、Pinia、Element Plus、SCSS、Vitest、ESLint 和 Prettier，提供基础占位页、404 页和组件测试。尚未实现管理员登录、权限菜单、API 请求或任何管理业务。

```powershell
npm ci
npm run dev
npm run lint
npm run type-check
npm run test:unit -- --run
npm run build
npm run preview
```

`npm run dev` 输出的实际本地 URL 用于浏览器预览，按 `Ctrl+C` 停止。
