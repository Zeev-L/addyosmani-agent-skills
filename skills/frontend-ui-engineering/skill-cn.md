---
name: frontend-ui-engineering
description: 构建生产质量的 UI。在构建或修改用户面向的界面时使用。在创建组件、实现布局、管理状态或输出需要看起来和感觉像生产质量而不是 AI 生成时使用。
---

# 前端 UI 工程

## 概述

构建可访问、高性能且视觉精致的生产质量用户界面。目标是 UI 看起来像是由顶级公司的设计意识工程师构建的——而不是像是由 AI 生成的。这意味着真正的设计系统遵守、适当的可访问性、深思熟虑的交互模式和没有通用的"AI 美学"。

## 使用场景

- 构建新的 UI 组件或页面
- 修改现有的用户面向界面
- 实现响应式布局
- 添加交互性或状态管理
- 修复视觉或 UX 问题

## 组件架构

### 文件结构

将组件相关的所有内容放在同一位置：

```
src/components/
  TaskList/
    TaskList.tsx          # 组件实现
    TaskList.test.tsx     # 测试
    TaskList.stories.tsx  # Storybook 故事（如果使用）
    use-task-list.ts      # 自定义钩子（如果状态复杂）
    types.ts              # 组件特定的类型（如果需要）
```

### 组件模式

**优先组合而不是配置：**

```tsx
// 好：可组合
<Card>
  <CardHeader>
    <CardTitle>Tasks</CardTitle>
  </CardHeader>
  <CardBody>
    <TaskList tasks={tasks} />
  </CardBody>
</Card>

// 避免：过度配置
<Card
  title="Tasks"
  headerVariant="large"
  bodyPadding="md"
  content={<TaskList tasks={tasks} />}
/>
```

**保持组件专注：**

```tsx
// 好：做一件事
export function TaskItem({ task, onToggle, onDelete }: TaskItemProps) {
  return (
    <li className="flex items-center gap-3 p-3">
      <Checkbox checked={task.done} onChange={() => onToggle(task.id)} />
      <span className={task.done ? 'line-through text-muted' : ''}>{task.title}</span>
      <Button variant="ghost" size="sm" onClick={() => onDelete(task.id)}>
        <TrashIcon />
      </Button>
    </li>
  );
}
```

**将数据获取与展示分离：**

```tsx
// 容器：处理数据
export function TaskListContainer() {
  const { tasks, isLoading, error } = useTasks();

  if (isLoading) return <TaskListSkeleton />;
  if (error) return <ErrorState message="Failed to load tasks" retry={refetch} />;
  if (tasks.length === 0) return <EmptyState message="No tasks yet" />;

  return <TaskList tasks={tasks} />;
}

// 展示：处理渲染
export function TaskList({ tasks }: { tasks: Task[] }) {
  return (
    <ul role="list" className="divide-y">
      {tasks.map(task => <TaskItem key={task.id} task={task} />)}
    </ul>
  );
}
```

## 状态管理

**选择最简单有效的方法：**

```
本地状态 (useState)           → 组件特定的 UI 状态
提升的状态                     → 2-3 个兄弟组件之间共享
Context                          → 主题、身份验证、区域设置（读取多，写入少）
URL 状态 (searchParams)         → 过滤器、分页、可共享的 UI 状态
服务器状态 (React Query, SWR)  → 带缓存的远程数据
全局存储 (Zustand, Redux)    → 应用范围内共享的复杂客户端状态
```

**避免属性钻取超过 3 层。** 如果你通过不使用它们的组件传递属性，请引入 context 或重构组件树。

## 设计系统遵守

### 避免 AI 美学

AI 生成的 UI 有可识别的模式。避免所有这些：

| AI 默认 | 为什么是问题 | 生产质量 |
|---|---|---|
| 紫色/靛蓝色一切 | 模型默认为视觉上"安全"的调色板，使每个应用程序看起来相同 | 使用项目的实际调色板 |
| 过度渐变 | 渐变增加视觉噪音并与大多数设计系统冲突 | 平面或微妙的渐变，匹配设计系统 |
| 圆角一切 (rounded-2xl) | 最大圆角表示"友好"但忽略真实设计中的角半径层次结构 | 来自设计系统的一致 border-radius |
| 通用主区域部分 | 模板驱动布局与的实际内容或用户需求没有连接 | 内容优先布局 |
| Lorem ipsum 样式副本 | 占位符文本隐藏真实内容揭示的布局问题（长度、换行、溢出） | 逼真的占位符内容 |
| 超大填充无处不在 | 相等的慷慨填充破坏视觉层次结构并浪费屏幕空间 | 一致的间距比例 |
| 库存卡片网格 | 统一网格是忽略信息优先级和扫描模式的布局快捷方式 | 目标驱动布局 |
| 阴影重设计 | 分层阴影增加与内容竞争的深度，并降低低端设备上的渲染速度 | 微妙或无阴影，除非设计系统指定 |

### 间距和布局

使用一致的间距比例。不要发明值：

```css
/* 使用比例：0.25rem 增量（或项目使用的任何值）*/
/* 好 */  padding: 1rem;      /* 16px */
/* 好 */  gap: 0.75rem;       /* 12px */
/* 坏 */   padding: 13px;      /* 不在任何比例上 */
/* 坏 */   margin-top: 2.3rem; /* 不在任何比例上 */
```

### 排版

尊重类型层次结构：

```
h1 → 页面标题（每页一个）
h2 → 部分标题
h3 → 子部分标题
body → 默认文本
small → 次要/帮助文本
```

不要跳过标题级别。不要对非标题内容使用标题样式。

### 颜色

- 使用语义颜色令牌：`text-primary`、`bg-surface`、`border-default` —— 不是原始十六进制值
- 确保足够的对比度（正常文本为 4.5:1，大文本为 3:1）
- 不要仅仅依靠颜色来传达信息（也使用图标、文本或模式）

## 可访问性 (WCAG 2.1 AA)

每个组件必须满足这些标准：

### 键盘导航

```tsx
// 每个交互元素必须是键盘可访问的
<button onClick={handleClick}>Click me</button>        // ✓ 默认可聚焦
<div onClick={handleClick}>Click me</div>               // ✗ 不可聚焦
<div role="button" tabIndex={0} onClick={handleClick}    // ✓ 但首选 <button>
     onKeyDown={e => {
       if (e.key === 'Enter') handleClick();
       if (e.key === ' ') e.preventDefault();
     }}
     onKeyUp={e => {
       if (e.key === ' ') handleClick();
     }}>
  Click me
</div>
```

### ARIA 标签

```tsx
// 为缺少可见文本的交互元素添加标签
<button aria-label="Close dialog"><XIcon /></button>

// 为表单输入添加标签
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// 或在没有可见标签时使用 aria-label
<input aria-label="Search tasks" type="search" />
```

### 焦点管理

```tsx
// 内容更改时移动焦点
function Dialog({ isOpen, onClose }: DialogProps) {
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    if (isOpen) closeRef.current?.focus();
  }, [isOpen]);

  // 打开时聚焦在对话框内
  return (
    <dialog open={isOpen}>
      <button ref={closeRef} onClick={onClose}>Close</button>
      {/* 对话框内容 */}
    </dialog>
  );
}
```

### 有意义的空状态和错误状态

```tsx
// 不要显示空白屏幕
function TaskList({ tasks }: { tasks: Task[] }) {
  if (tasks.length === 0) {
    return (
      <div role="status" className="text-center py-12">
        <TasksEmptyIcon className="mx-auto h-12 w-12 text-muted" />
        <h3 className="mt-2 text-sm font-medium">No tasks</h3>
        <p className="mt-1 text-sm text-muted">Get started by creating a new task.</p>
        <Button className="mt-4" onClick={onCreateTask}>Create Task</Button>
      </div>
    );
  }

  return <ul role="list">...</ul>;
}
```

## 响应式设计

为移动设备优先设计，然后扩展：

```tsx
// Tailwind：移动优先响应式
<div className="
  grid grid-cols-1      /* 移动设备：单列 */
  sm:grid-cols-2        /* 小屏幕：2 列 */
  lg:grid-cols-3        /* 大屏幕：3 列 */
  gap-4
">
```

在这些断点测试：320px、768px、1024px、1440px。

## 加载和过渡

```tsx
// 骨架加载（不是内容旋转器）
function TaskListSkeleton() {
  return (
    <div className="space-y-3" aria-busy="true" aria-label="Loading tasks">
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="h-12 bg-muted animate-pulse rounded" />
      ))}
    </div>
  );
}

// 乐观更新以提高感知速度
function useToggleTask() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: toggleTask,
    onMutate: async (taskId) => {
      await queryClient.cancelQueries({ queryKey: ['tasks'] });
      const previous = queryClient.getQueryData(['tasks']);

      queryClient.setQueryData(['tasks'], (old: Task[]) =>
        old.map(t => t.id === taskId ? { ...t, done: !t.done } : t)
      );

      return { previous };
    },
    onError: (_err, _taskId, context) => {
      queryClient.setQueryData(['tasks'], context?.previous);
    },
  });
}
```

## 另见

有关详细的可访问性需求和测试工具，请参见 `references/accessibility-checklist.md`。

## 常见合理化理由

| 合理化理由 | 现实 |
|---|---|
| "可访问性是可有可无的" | 在许多司法管辖区，这是法律要求，也是工程质量标准。 |
| "我们稍后让它响应式" | 改造响应式设计比从一开始构建它难 3 倍。 |
| "设计还没最终确定，所以我会跳过样式" | 使用设计系统默认值。未设置样式的 UI 给审查者留下破损的第一印象。 |
| "这只是一个原型" | 原型成为生产代码。正确构建基础。 |
| "AI 美学现在没问题" | 它发出低质量的信号。从一开始就用项目的实际设计系统。 |

## 危险信号

- 超过 200 行的组件（拆分它们）
- 内联样式或任意像素值
- 缺少错误状态、加载状态或空状态
- 没有键盘导航测试
- 颜色作为状态的唯一指示器（红色/绿色而没有文本或图标）
- 通用"AI 外观"（紫色渐变、超大卡片、库存布局）

## 验证

构建 UI 后：

- [ ] 组件无控制台错误渲染
- [ ] 所有交互元素都是键盘可访问的（通过页面按 Tab 键）
- [ ] 屏幕阅读器可以传达页面的内容和结构
- [ ] 响应式：在 320px、768px、1024px、1440px 工作
- [ ] 加载、错误和空状态都得到处理
- [ ] 遵循项目的设计系统（间距、颜色、排版）
- [ ] dev 工具或 axe-core 中没有可访问性警告
