---
name: documentation-and-adrs
description: 记录决策和文档。在进行架构决策、更改公共 API、发布功能或需要记录未来工程师和代理理解代码库所需的上下文时使用。
---

# 文档和 ADR

## 概述

记录决策，而不仅仅是代码。最有价值的文档捕获 *为什么* —— 导致决策的背景、约束和权衡。代码显示 *构建了什么*；文档解释 *为什么以这种方式构建* 和 *考虑了什么替代方案*。这个上下文对于在代码库中工作的未来人类和代理至关重要。

## 使用场景

- 进行重要的架构决策
- 在竞争方法之间选择
- 添加或更改公共 API
- 发布改变用户面向行为的功能
- 将新团队成员（或代理）入门到项目
- 当你发现自己重复解释同一件事时

**何时不使用：** 不要记录显而易见的代码。不要添加重申代码已经说的内容的注释。不要为一次性原型编写文档。

## 架构决策记录 (ADR)

ADR 捕获重要技术决策背后的推理。它们是你可以编写的最高价值文档。

### 何时编写 ADR

- 选择框架、库或主要依赖项
- 设计数据模型或数据库模式
- 选择身份验证策略
- 决定 API 架构（REST vs. GraphQL vs. tRPC）
- 在构建工具、托管平台或基础设施之间选择
- 任何逆转成本昂贵的决策

### ADR 模板

将 ADR 存储在 `docs/decisions/` 中，带有顺序编号：

```markdown
# ADR-001: 使用 PostgreSQL 作为主要数据库

## 状态
已接受 | 被 ADR-XXX 取代 | 已弃用

## 日期
2025-01-15

## 上下文
我们需要一个用于任务管理应用程序的主要数据库。关键要求：
- 关系数据模型（用户、任务、带有关系的团队）
- 任务状态更改的 ACID 事务
- 对任务内容支持全文搜索
- 可用的托管托管（对于小团队，运营能力有限）

## 决策
使用 PostgreSQL 和 Prisma ORM。

## 考虑的替代方案

### MongoDB
- 优点：灵活的架构，易于开始
- 缺点：我们的数据本质上是关系型的；需要手动管理关系
- 拒绝：文档存储中的关系数据导致复杂的连接或数据重复

### SQLite
- 优点：零配置，嵌入式，读取速度快
- 缺点：有限的并发写入支持，没有用于生产的托管托管
- 拒绝：不适合生产中的多用户 Web 应用程序

### MySQL
- 优点：成熟，广泛支持
- 缺点：PostgreSQL 有更好的 JSON 支持、全文搜索和生态系统工具
- 拒绝：PostgreSQL 更适合我们的功能需求

## 后果
- Prisma 提供类型安全的数据库访问和迁移管理
- 我们可以使用 PostgreSQL 的全文搜索，而不是添加 Elasticsearch
- 团队需要 PostgreSQL 知识（标准技能，低风险）
- 托管在托管服务上（Supabase、Neon 或 RDS）
```

### ADR 生命周期

```
提议 → 已接受 → （已取代或已弃用）
```

- **不要删除旧的 ADR。** 它们捕获历史上下文。
- 当决策更改时，编写引用并取代旧决策的新 ADR。

## 内联文档

### 何时注释

注释 *为什么*，而不是 *什么*：

```typescript
// 坏：重申代码
// 计数器加 1
counter += 1;

// 好：解释非显而易见的意图
// 速率限制使用滑动窗口 —— 在窗口边界重置计数器，
// 不是固定时间表，以防止窗口边缘的突发攻击
if (now - windowStart > WINDOW_SIZE_MS) {
  counter = 0;
  windowStart = now;
}
```

### 何时不注释

```typescript
// 不要注释不言自明的代码
function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// 不要为你应该现在就做的事情留下 TODO 注释
// TODO：添加错误处理 ← 直接添加它

// 不要留下注释掉的代码
// const oldImplementation = () => { ... }  ← 删除它，git 有历史
```

### 记录已知的陷阱

```typescript
/**
 * 重要：必须在第一次渲染之前调用此函数。
 * 如果在水合后调用，会导致未样式化内容的闪烁
 * 因为在 SSR 期间主题上下文不可用。
 *
 * 参见 ADR-003 了解完整的设计原理。
 */
export function initializeTheme(theme: Theme): void {
  // ...
}
```

## API 文档

对于公共 API（REST、GraphQL、库接口）：

### 使用类型内联（TypeScript 首选）

```typescript
/**
 * 创建新任务。
 *
 * @param input - 任务创建数据（标题必需，描述可选）
 * @returns 带有服务器生成的 ID 和时间戳的创建任务
 * @throws {ValidationError} 如果标题为空或超过 200 个字符
 * @throws {AuthenticationError} 如果用户未通过身份验证
 *
 * @example
 * const task = await createTask({ title: 'Buy groceries' });
 * console.log(task.id); // "task_abc123"
 */
export async function createTask(input: CreateTaskInput): Promise<Task> {
  // ...
}
```

### REST API 的 OpenAPI / Swagger

```yaml
paths:
  /api/tasks:
    post:
      summary: 创建任务
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateTaskInput'
      responses:
        '201':
          description: 任务已创建
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Task'
        '422':
          description: 验证错误
```

## README 结构

每个项目都应该有一个涵盖以下内容的 README：

```markdown
# 项目名称

这个项目做什么的一段描述。

## 快速开始
1. 克隆仓库
2. 安装依赖项：`npm install`
3. 设置环境：`cp .env.example .env`
4. 运行开发服务器：`npm run dev`

## 命令
| 命令 | 描述 |
|---------|-------------|
| `npm run dev` | 启动开发服务器 |
| `npm test` | 运行测试 |
| `npm run build` | 生产构建 |
| `npm run lint` | 运行 linter |

## 架构
项目结构和关键设计决策的简要概述。
链接到 ADR 了解详情。

## 贡献
如何贡献、编码标准、PR 流程。
```

## 变更日志维护

对于已发布的功能：

```markdown
# 变更日志

## [1.2.0] - 2025-01-20
### 已添加
- 任务共享：用户可以与团队成员共享任务 (#123)
- 任务分配的电子邮件通知 (#124)

### 已修复
- 快速单击创建按钮时出现重复任务 (#125)

### 已更改
- 任务列表现在每页加载 50 个项目（之前是 20 个）以获得更好的 UX (#126)
```

## 代理文档

AI 代理上下文的特殊考虑：

- **CLAUDE.md / 规则文件** —— 记录项目约定，以便代理遵循它们
- **规范文件** —— 保持规范更新，以便代理构建正确的东西
- **ADR** —— 帮助代理理解过去为什么做出决策（防止重新决策）
- **内联陷阱** —— 防止代理掉入已知的陷阱

## 常见合理化理由

| 合理化理由 | 现实 |
|---|---|
| "代码是自文档化的" | 代码显示什么。它不显示为什么、拒绝了什么替代方案或适用什么约束。 |
| "我们将在 API 稳定时编写文档" | 当你记录它们时，API 稳定得更快。文档是设计的第一次测试。 |
| "没有人阅读文档" | 代理会。未来的工程师会。你 3 个月后的自己会。 |
| "ADR 是开销" | 10 分钟的 ADR 防止 2 小时后关于 6 个月后相同决策的辩论。 |
| "注释会过时" | 关于 *为什么* 的注释是稳定的。关于 *什么* 的注释会过时 —— 这就是为什么你只写前者。 |

## 危险信号

- 没有书面理由的架构决策
- 没有文档或类型的公共 API
- README 没有解释如何运行项目
- 注释掉的代码而不是删除
- 已经存在数周的 TODO 注释
- 在具有重大架构选择的项目中没有 ADR
- 重申代码而不是解释意图的文档

## 验证

文档化后：

- [ ] 所有重要架构决策都存在 ADR
- [ ] README 涵盖快速开始、命令和架构概述
- [ ] API 函数具有参数和返回类型文档
- [ ] 已知的陷阱在重要的地方内联记录
- [ ] 没有注释掉的代码保留
- [ ] 规则文件（CLAUDE.md 等）是最新且准确的
