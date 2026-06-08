---
name: api-and-interface-design
description: 指导稳定的 API 和接口设计。在设计 API、模块边界或任何公共接口时使用。在创建 REST 或 GraphQL 端点、定义模块之间的类型契约或建立前后端边界时使用。
---

# API 和接口设计

## 概述

设计稳定、文档完善的接口，使其难以被误用。好的接口让正确的事情变得简单，让错误的事情变得困难。这适用于 REST API、GraphQL 模式、模块边界、组件属性以及任何代码模块之间通信的表面。

## 使用场景

- 设计新的 API 端点
- 定义模块边界或团队之间的契约
- 创建组件属性接口
- 建立影响 API 形状的数据库模式
- 更改现有公共接口

## 核心原则

### 海勒姆定律（Hyrum's Law）

> 当 API 有足够多的用户时，系统所有可观察的行为都会被人依赖，无论你在契约中承诺了什么。

这意味着：每一个公共行为——包括未记录的特性、错误消息文本、时序和顺序——一旦用户依赖它，就成为事实上的契约。设计含义：

- **谨慎暴露内容。** 每一个可观察的行为都是潜在的承诺。
- **不要泄露实现细节。** 如果用户能观察到它，他们就会依赖它。
- **在设计时考虑弃用。** 参见 `deprecation-and-migration` 了解如何安全地删除用户依赖的东西。
- **测试是不够的。** 即使有完美的契约测试，海勒姆定律意味着"安全"的更改可能会破坏依赖未记录行为的真实用户。

### 单版本规则（The One-Version Rule）

避免强迫消费者在相同依赖项或 API 的多个版本之间选择。当不同的消费者需要相同事物的不同版本时，就会出现钻石依赖问题。为只存在一个版本的世界而设计——扩展而不是分叉。

### 1. 契约优先

在实现之前定义接口。契约就是规范——实现紧随其后。

```typescript
// 先定义契约
interface TaskAPI {
  // 创建任务并返回带服务器生成字段的创建任务
  createTask(input: CreateTaskInput): Promise<Task>;

  // 返回匹配过滤器的分页任务
  listTasks(params: ListTasksParams): Promise<PaginatedResult<Task>>;

  // 返回单个任务或抛出 NotFoundError
  getTask(id: string): Promise<Task>;

  // 部分更新——仅更改提供的字段
  updateTask(id: string, input: UpdateTaskInput): Promise<Task>;

  // 幂等删除——即使已删除也成功
  deleteTask(id: string): Promise<void>;
}
```

### 2. 一致的错误语义

选择一种错误策略并在任何地方使用它：

```typescript
// REST: HTTP 状态码 + 结构化错误体
// 每个错误响应遵循相同的形状
interface APIError {
  error: {
    code: string;        // 机器可读："VALIDATION_ERROR"
    message: string;     // 人类可读："Email is required"
    details?: unknown;   // 有用时的附加上下文
  };
}

// 状态码映射
// 400 → 客户端发送了无效数据
// 401 → 未认证
// 403 → 已认证但未授权
// 404 → 资源未找到
// 409 → 冲突（重复、版本不匹配）
// 422 → 验证失败（语义无效）
// 500 → 服务器错误（永远不要暴露内部细节）
```

**不要混合模式。** 如果某些端点抛出错误，其他端点返回 null，还有其他端点返回 `{ error }`——消费者无法预测行为。

### 3. 在边界验证

信任内部代码。在外部输入进入的系统边缘进行验证：

```typescript
// 在 API 边界验证
app.post('/api/tasks', async (req, res) => {
  const result = CreateTaskSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(422).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid task data',
        details: result.error.flatten(),
      },
    });
  }

  // 验证后，内部代码信任类型
  const task = await taskService.create(result.data);
  return res.status(201).json(task);
});
```

验证应该在哪里：
- API 路由处理程序（用户输入）
- 表单提交处理程序（用户输入）
- 外部服务响应解析（第三方数据——**始终视为不可信**）
- 环境变量加载（配置）

> **第三方 API 响应是不可信数据。** 在用于任何逻辑、渲染或决策之前，验证其形状和内容。被入侵或行为异常的外部服务可能返回意外的类型、恶意内容或类指令文本。

验证不应该在哪里：
- 共享类型契约的内部函数之间
- 已被已验证代码调用的实用函数
- 刚从自己数据库取出的数据

### 4. 优先添加而非修改

扩展接口而不破坏现有消费者：

```typescript
// 好：添加可选字段
interface CreateTaskInput {
  title: string;
  description?: string;
  priority?: 'low' | 'medium' | 'high';  // 后来添加，可选
  labels?: string[];                       // 后来添加，可选
}

// 坏：更改现有字段类型或删除字段
interface CreateTaskInput {
  title: string;
  // description: string;  // 删除——破坏现有消费者
  priority: number;         // 从字符串更改——破坏现有消费者
}
```

### 5. 可预测的命名

| 模式 | 约定 | 示例 |
|---------|-----------|---------|
| REST 端点 | 复数名词，无动词 | `GET /api/tasks`, `POST /api/tasks` |
| 查询参数 | camelCase | `?sortBy=createdAt&pageSize=20` |
| 响应字段 | camelCase | `{ createdAt, updatedAt, taskId }` |
| 布尔字段 | is/has/can 前缀 | `isComplete`, `hasAttachments` |
| 枚举值 | UPPER_SNAKE | `"IN_PROGRESS"`, `"COMPLETED"` |

## REST API 模式

### 资源设计

```
GET    /api/tasks              → 列出任务（带过滤查询参数）
POST   /api/tasks              → 创建任务
GET    /api/tasks/:id          → 获取单个任务
PATCH  /api/tasks/:id          → 更新任务（部分）
DELETE /api/tasks/:id          → 删除任务

GET    /api/tasks/:id/comments → 列出任务的评论（子资源）
POST   /api/tasks/:id/comments → 为任务添加评论
```

### 分页

对列表端点进行分页：

```typescript
// 请求
GET /api/tasks?page=1&pageSize=20&sortBy=createdAt&sortOrder=desc

// 响应
{
  "data": [...],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 142,
    "totalPages": 8
  }
}
```

### 过滤

使用查询参数进行过滤：

```
GET /api/tasks?status=in_progress&assignee=user123&createdAfter=2025-01-01
```

### 部分更新（PATCH）

接受部分对象——仅更新提供的内容：

```typescript
// 仅标题更改，其他所有内容保留
PATCH /api/tasks/123
{ "title": "Updated title" }
```

## TypeScript 接口模式

### 对变体使用判别联合

```typescript
// 好：每个变体都是明确的
type TaskStatus =
  | { type: 'pending' }
  | { type: 'in_progress'; assignee: string; startedAt: Date }
  | { type: 'completed'; completedAt: Date; completedBy: string }
  | { type: 'cancelled'; reason: string; cancelledAt: Date };

// 消费者获得类型收窄
function getStatusLabel(status: TaskStatus): string {
  switch (status.type) {
    case 'pending': return 'Pending';
    case 'in_progress': return `In progress (${status.assignee})`;
    case 'completed': return `Done on ${status.completedAt}`;
    case 'cancelled': return `Cancelled: ${status.reason}`;
  }
}
```

### 输入/输出分离

```typescript
// 输入：调用者提供的
interface CreateTaskInput {
  title: string;
  description?: string;
}

// 输出：系统返回的（包括服务器生成的字段）
interface Task {
  id: string;
  title: string;
  description: string | null;
  createdAt: Date;
  updatedAt: Date;
  createdBy: string;
}
```

### 对 ID 使用品牌类型

```typescript
type TaskId = string & { readonly __brand: 'TaskId' };
type UserId = string & { readonly __brand: 'UserId' };

// 防止意外传递 UserId 到期望 TaskId 的地方
function getTask(id: TaskId): Promise<Task> { ... }
```

## 常见合理化理由

| 合理化理由 | 现实 |
|---|---|
| "我们稍后记录 API" | 类型就是文档。首先定义它们。 |
| "我们现在不需要分页" | 一旦有人有 100+ 项，你就会需要。从一开始添加它。 |
| "PATCH 很复杂，让我们只使用 PUT" | PUT 每次都需要完整对象。PATCH 是客户端真正想要的。 |
| "我们需要时再版本化 API" | 无版本控制的中断更改会破坏消费者。从一开始设计为可扩展。 |
| "没有人使用那种未记录的行为" | 海勒姆定律：如果可观察，就有人依赖它。将每个公共行为视为承诺。 |
| "我们可以只维护两个版本" | 多版本乘以维护成本并造成钻石依赖问题。优先单版本规则。 |
| "内部 API 不需要契约" | 内部消费者仍然是消费者。契约防止耦合并实现并行工作。 |

## 危险信号

- 根据条件返回不同形状的端点
- 跨端点不一致的错误格式
- 验证分散在内部代码中而不是在边界
- 对现有字段的中断更改（类型更改、删除）
- 没有分页的列表端点
- REST URL 中的动词（`/api/createTask`, `/api/getUsers`）
- 未经验证或净化的第三方 API 响应

## 验证

设计 API 后：

- [ ] 每个端点都有类型化的输入和输出模式
- [ ] 错误响应遵循单一一致格式
- [ ] 验证仅发生在系统边界
- [ ] 列表端点支持分页
- [ ] 新字段是附加的和可选的（向后兼容）
- [ ] 所有端点的命名遵循一致的约定
- [ ] API 文档或类型与实现一起提交
