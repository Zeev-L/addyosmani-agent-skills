---
name: performance-optimization
description: 优化应用程序性能。当存在性能要求、怀疑性能回归或需要改进 Core Web Vitals 或加载时间时使用。当性能分析揭示需要修复的瓶颈时使用。
---

# 性能优化#

## 概述

在优化之前先测量。没有测量的性能工作是猜测 —— 而猜测导致过早优化，增加复杂性而不改善重要的事情。首先进行分析，识别实际瓶颈，修复它，再次测量。仅优化测量证明重要的事情。

## 使用场景

- 规范中存在性能要求（加载时间预算、响应时间 SLAs）
- 用户或监控报告缓慢行为
- Core Web Vitals 分数低于阈值
- 你怀疑更改引入了回归
- 构建处理大型数据集或高流量的功能#

**何时不使用：** 在你有问题的证据之前不要优化。过早优化增加复杂性，其成本超过它获得的性能。

## Core Web Vitals 目标#

| 指标 | 好 | 需要改进 | 差 |
|--------|------|-------------------|------|
| **LCP** (最大内容绘制) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| **INP** (交互到下一次绘制) | ≤ 200ms | ≤ 500ms | > 500ms |
| **CLS** (累积布局偏移) | ≤ 0.1 | ≤ 0.25 | > 0.25 |#

## 优化工作流#

```
1. 测量  → 使用真实数据建立基线
2. 识别 → 找到实际瓶颈（不是假设的）
3. 修复      → 解决特定瓶颈
4. 验证   → 再次测量，确认改进
5. 防护    → 添加监控或测试以防止回归
```

### 步骤 1：测量#

两种互补的方法 —— 两种都使用：

- **合成（Lighthouse、DevTools Performance 标签）：** 受控条件，可重现。最适合 CI 回归检测和隔离特定问题。
- **RUM (web-vitals 库、CrUX)：** 真实条件下的真实用户数据。需要验证修复是否真正改善了用户体验。

**前端：**
```bash
# 合成：Chrome DevTools 中的 Lighthouse（或 CI）
# Chrome DevTools → Performance 标签 → 录制
# Chrome DevTools MCP → 性能跟踪

# RUM：代码中的 Web Vitals 库
import { onLCP, onINP, onCLS } from 'web-vitals';

onLCP(console.log);
onINP(console.log);
onCLS(console.log);
```

**后端：**
```bash
# 响应时间记录
# 应用程序性能监控 (APM)
# 带时序的数据库查询记录

# 简单计时
console.time('db-query');
const result = await db.query(...);
console.timeEnd('db-query');
```

### 从哪里开始测量#

使用症状决定首先测量什么：

```
什么是慢的？
├── 首次页面加载
│   ├── 大包？--> 测量包大小，检查代码分割
│   ├── 服务器响应慢？--> 在 DevTools 网络瀑布图中测量 TTFB
│   │   ├── DNS 长？--> 为已知源添加 dns-prefetch / preconnect
│   │   ├── TCP/TLS 长？--> 启用 HTTP/2，检查边缘部署，keep-alive
│   │   └── 等待（服务器）长？--> 分析后端，检查查询和缓存
│   └── 渲染阻塞资源？--> 检查 CSS/JS 阻塞的网络瀑布图
├── 交互感觉迟缓
│   ├── 点击时 UI 冻结？--> 分析主线程，查找长任务 (>50ms)
│   ├── 表单输入延迟？--> 检查重新渲染，受控组件开销
│   └── 动画卡顿？--> 检查布局抖动，强制重排
├── 导航后页面
│   ├── 数据加载？--> 测量 API 响应时间，检查瀑布图
│   └── 客户端渲染？--> 分析组件渲染时间，检查 N+1 获取
└── 后端 / API
    ├── 单个端点慢？--> 分析数据库查询，检查索引
    ├── 所有端点慢？--> 检查连接池、内存、CPU
    └── 间歇性慢？--> 检查锁竞争、GC 暂停、外部依赖项
```

### 步骤 2：识别瓶颈#

按类别的常见瓶颈：

**前端：**

| 症状 | 可能原因 | 调查 |
|---------|-------------|---------------|
| 慢 LCP | 大图像、渲染阻塞资源、慢服务器 | 检查网络瀑布图、图像大小 |
| 高 CLS | 没有尺寸的图像、延迟加载内容、字体偏移 | 检查布局偏移归因 |
| 差 INP | 主线程上的重型 JavaScript、大型 DOM 更新 | 检查性能跟踪中的长任务 |
| 初始加载慢 | 大包、许多网络请求 | 检查包大小、代码分割 |

**后端：**

| 症状 | 可能原因 | 调查 |
|---------|-------------|---------------|
| 慢 API 响应 | N+1 查询、缺少索引、未优化查询 | 检查数据库查询日志 |
| 内存增长 | 泄漏的引用、无界缓存、大型负载 | 堆快照分析 |
| CPU 峰值 | 同步重型计算、正则表达式回溯 | CPU 分析 |
| 高延迟 | 缺少缓存、冗余计算、网络跳数 | 通过堆栈跟踪请求 |

### 步骤 3：修复常见反模式#

#### N+1 查询（后端）#

```typescript
// 坏：N+1 —— 每个任务一个查询
const tasks = await db.tasks.findMany();
for (const task of tasks) {
  task.owner = await db.users.findUnique({ where: { id: task.ownerId } });
}

// 好：使用 join/include 的单个查询
const tasks = await db.tasks.findMany({
  include: { owner: true },
});
```

#### 无界数据获取#

```typescript
// 坏：获取所有记录
const allTasks = await db.tasks.findMany();

// 好：带限制的分页
const tasks = await db.tasks.findMany({
  take: 20,
  skip: (page - 1) * 20,
  orderBy: { createdAt: 'desc' },
});
```

#### 缺少图像优化（前端）#

```html
<!-- 坏：没有尺寸，没有格式优化 -->
<img src="/hero.jpg" />

<!-- 好：Hero / LCP 图像 —— 美术方向 + 分辨率切换，高优先级 -->
<!--
  两种技术结合：
  - 美术方向 (media)：每个断点的不同裁剪/构图
  - 分辨率切换 (srcset + sizes)：每个屏幕密度的正确文件大小
-->
<picture>
  <!-- 移动设备：纵向裁剪 (8:10) -->
  <source
    media="(max-width: 767px)"
    srcset="/hero-mobile-400.avif 400w, /hero-mobile-800.avif 800w"
    sizes="100vw"
    width="800"
    height="1000"
    type="image/avif"
  />
  <source
    media="(max-width: 767px)"
    srcset="/hero-mobile-400.webp 400w, /hero-mobile-800.webp 800w"
    sizes="100vw"
    width="800"
    height="1000"
    type="image/webp"
  />
  <!-- 桌面：横向裁剪 (2:1) -->
  <source
    srcset="/hero-800.avif 800w, /hero-1200.avif 1200w, /hero-1600.avif 1600w"
    sizes="(max-width: 1200px) 100vw, 1200px"
    width="1200"
    height="600"
    type="image/avif"
  />
  <source
    srcset="/hero-800.webp 800w, /hero-1200.webp 1200w, /hero-1600.webp 1600w"
    sizes="(max-width: 1200px) 100vw, 1200px"
    width="1200"
    height="600"
    type="image/webp"
  />
  <img
    src="/hero-desktop.jpg"
    width="1200"
    height="600"
    fetchpriority="high"
    alt="Hero image description"
  />
</picture>

<!-- 好：折下图像 —— 懒加载 + 异步解码 -->
<img
  src="/content.webp"
  width="800"
  height="400"
  loading="lazy"
  decoding="async"
  alt="Content image description"
/>
```

#### 不必要的重新渲染（React）#

```tsx
// 坏：每次渲染时创建新对象，导致子组件重新渲染
function TaskList() {
  return <TaskFilters options={{ sortBy: 'date', order: 'desc' }} />;
}

// 好：稳定引用
const DEFAULT_OPTIONS = { sortBy: 'date', order: 'desc' } as const;
function TaskList() {
  return <TaskFilters options={DEFAULT_OPTIONS} />;
}

// 对昂贵的组件使用 React.memo
const TaskItem = React.memo(function TaskItem({ task }: Props) {
  return <div>{/* 昂贵渲染 */}</div>;
});

// 对昂贵的计算使用 useMemo
function TaskStats({ tasks }: Props) {
  const stats = useMemo(() => calculateStats(tasks), [tasks]);
  return <div>{stats.completed} / {stats.total}</div>;
}
```

#### 大包大小#

```typescript
// 现代打包器（Vite、webpack 5+）通过树摇自动处理命名导入，
// 前提是依赖项提供 ESM 并在 package.json 中标记为 `sideEffects: false`。
// 在更改导入样式之前进行分析 —— 真正的收益来自分割和懒加载。

// 好：重型、很少使用的功能的动态导入
const ChartLibrary = lazy(() => import('./ChartLibrary'));

// 好：包裹在 Suspense 中的路由级代码分割
const SettingsPage = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<Spinner />}>
      <SettingsPage />
    </Suspense>
  );
}
```

#### 缺少缓存（后端）#

```typescript
// 缓存频繁读取、很少更改的数据
const CACHE_TTL = 5 * 60 * 1000; // 5 分钟
let cachedConfig: AppConfig | null = null;
let cacheExpiry = 0;

async function getAppConfig(): Promise<AppConfig> {
  if (cachedConfig && Date.now() < cacheExpiry) {
    return cachedConfig;
  }
  cachedConfig = await db.config.findFirst();
  cacheExpiry = Date.now() + CACHE_TTL;
  return cachedConfig;
}

// 静态资产的 HTTP 缓存标头
app.use('/static', express.static('public', {
  maxAge: '1y',           // 缓存 1 年
  immutable: true,        // 从不重新验证（在文件名中使用内容哈希）
}));

// API 响应的 Cache-Control
res.set('Cache-Control', 'public, max-age=300'); // 5 分钟
```

## 性能预算#

设置预算并执行它们：

```
JavaScript 包：< 200KB gzipped （初始加载）
CSS：< 50KB gzipped
图像：< 200KB 每张图像（首屏）
字体：< 100KB 总计
API 响应时间：< 200ms (p95)
可交互时间：< 3.5s 在 4G 上
Lighthouse 性能分数：≥ 90
```

**在 CI 中执行：**
```bash
# 包大小检查
npx bundlesize --config bundlesize.config.json

# Lighthouse CI
npx lhci autorun
```

## 另见#

有关详细的性能检查表、优化命令和反模式参考，请参见 `references/performance-checklist.md`。

## 常见合理化理由#

| 合理化理由 | 现实 |
|---|---|
| "我们稍后优化" | 性能债务复合。现在修复明显的反模式，推迟微优化。 |
| "在我的机器上很快" | 你的机器不是用户的。在代表性硬件和网络上进行性能分析。 |
| "这个优化是显而易见的" | 如果你没有测量，你就不知道。首先分析。 |
| "用户不会注意到 100ms" | 研究表明 100ms 延迟影响转化率。用户注意到的比你想象的要多。 |
| "框架处理性能" | 框架防止了一些问题，但不能修复 N+1 查询或过大的包。 |

## 危险信号#

- 没有性能分析数据证明的优化
- 数据获取中的 N+1 查询模式
- 没有分页的列表端点
- 没有尺寸、懒加载或响应式大小的图像
- 包大小增长没有审查
- 生产中没有性能监控
- 到处都是 `React.memo` 和 `useMemo`（过度使用与 Underusing 一样糟糕）#

## 验证#

任何性能相关的更改后：

- [ ] 存在前后测量（具体数字）
- [ ] 识别并解决了特定瓶颈
- [ ] Core Web Vitals 在"好"阈值内
- [ ] 包大小没有显著增加
- [ ] 新的数据获取代码中没有 N+1 查询
- [ ] 性能预算在 CI 中通过（如果已配置）
- [ ] 现有测试仍然通过（优化不会破坏行为）
