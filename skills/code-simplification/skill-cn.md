---
name: code-simplification
description: 简化代码以提高清晰度。在重构代码以提高清晰度而不改变行为时使用。当代码可以工作但比它应该的更难阅读、维护或扩展时使用。当审查积累了不必要复杂性的代码时使用。
---

# 代码简化

> 灵感来自 [Claude Code Simplifier 插件](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/code-simplifier/agents/code-simplifier.md)。此处改编为模型无关、过程驱动的技能，适用于任何 AI 编码代理。

## 概述

通过降低复杂性来简化代码，同时保持确切的行为。目标不是更少的行数——而是更容易阅读、理解、修改和调试的代码。每个简化必须通过一个简单的测试："新团队成员理解这个的速度会比原始版本更快吗？"

## 使用场景

- 功能正常工作且测试通过，但实现感觉比需要的更重
- 在代码审查期间，当标记了可读性或复杂性问题时
- 当遇到深度嵌套的逻辑、长函数或不清楚的名称时
- 重构在时间压力下编写的代码时
- 整合分散在文件中的相关逻辑时
- 合并引入重复或不一致性的更改后

**何时不使用：**

- 代码已经干净且可读——不要为了简化而简化
- 你还不理解代码做什么——在简化之前先理解
- 代码对性能至关重要，而"更简单"的版本会明显更慢
- 你即将完全重写模块——简化一次性代码是浪费精力

## 五个原则

### 1. 完全保持行为

不要改变代码的作用——只改变它表达的方式。所有输入、输出、副作用、错误行为和边缘情况必须保持相同。如果你不确定简化是否保持行为，就不要进行。

```
每次更改前询问：
→ 这是否为每个输入产生相同的输出？
→ 这是否保持相同的错误行为？
→ 这是否保持相同的副作用和顺序？
→ 所有现有测试是否仍通过而无需修改？
```

### 2. 遵循项目约定

简化意味着使代码与代码库更一致，而不是强加外部偏好。在简化之前：

```
1. 阅读 CLAUDE.md / 项目约定
2. 研究相邻代码如何处理类似模式
3. 匹配项目的样式：
   - 导入排序和模块系统
   - 函数声明样式
   - 命名约定
   - 错误处理模式
   - 类型注释深度
```

打破项目一致性的简化不是简化——它是搅动。

### 3. 优先清晰度而非聪明

当紧凑版本需要心理暂停来解析时，显式代码比紧凑代码更好。

```typescript
// 不清楚：密集三元链
const label = isNew ? 'New' : isUpdated ? 'Updated' : isArchived ? 'Archived' : 'Active';

// 清楚：可读的映射
function getStatusLabel(item: Item): string {
  if (item.isNew) return 'New';
  if (item.isUpdated) return 'Updated';
  if (item.isArchived) return 'Archived';
  return 'Active';
}
```

```typescript
// 不清楚：带内联逻辑的链式 reduces
const result = items.reduce((acc, item) => ({
  ...acc,
  [item.id]: { ...acc[item.id], count: (acc[item.id]?.count ?? 0) + 1 }
}), {});

// 清楚：命名的中间步骤
const countById = new Map<string, number>();
for (const item of items) {
  countById.set(item.id, (countById.get(item.id) ?? 0) + 1);
}
```

### 4. 保持平衡

简化有一个失败模式：过度简化。注意这些陷阱：

- **过于激进的内联** —— 删除给概念命名的助手会使调用点更难阅读
- **合并不相关的逻辑** —— 两个简单函数合并为一个复杂函数并不更简单
- **删除"不必要的"抽象** —— 某些抽象的存在是为了可扩展性或可测试性，而不是复杂性
- **优化行数** —— 更少的行不是目标；更容易理解才是

### 5. 范围限定到更改的内容

默认简化为最近修改的代码。除非明确要求扩大范围，否则避免顺便重构不相关的代码。无范围的简化会在差异中创建噪音，并带来意外的回归风险。

## 简化过程

### 步骤 1：在接触之前理解（切斯特顿的栅栏）

在更改或删除任何东西之前，理解它为什么存在。这是切斯特顿的栅栏：如果你看到路上有一个栅栏而不理解它为什么在那里，不要拆掉它。首先理解原因，然后决定原因是否仍然适用。

```
简化之前，回答：
- 这个代码的责任是什么？
- 什么调用它？它调用什么？
- 边缘情况和错误路径是什么？
- 是否有定义预期行为的测试？
- 为什么可能以这种方式编写？（性能？平台约束？历史原因？）
- 检查 git blame：这个代码的原始上下文是什么？
```

如果你不能回答这些，你还没有准备好简化。首先阅读更多上下文。

### 步骤 2：识别简化机会

扫描这些模式——每一个都是具体的信号，而不是模糊的味道：

**结构复杂性：**

| 模式 | 信号 | 简化 |
|---------|--------|----------------|
| 深度嵌套（3+ 级别） | 难以遵循控制流 | 将条件提取到保护子句或助手函数 |
| 长函数（50+ 行） | 多个职责 | 拆分为具有描述性名称的集中函数 |
| 嵌套三元 | 需要心理堆栈来解析 | 替换为 if/else 链、switch 或查找对象 |
| 布尔参数标志 | `doThing(true, false, true)` | 替换为选项对象或单独的函数 |
| 重复的条件 | 多个地方有相同的 `if` 检查 | 提取到命名良好的谓词函数 |

**命名和可读性：**

| 模式 | 信号 | 简化 |
|---------|--------|----------------|
| 通用名称 | `data`、`result`、`temp`、`val`、`item` | 重命名为描述内容：`userProfile`、`validationErrors` |
| 缩写名称 | `usr`、`cfg`、`btn`、`evt` | 使用完整的单词，除非缩写是通用的（`id`、`url`、`api`） |
| 误导性名称 | 命名为 `get` 的函数也改变状态 | 重命名以反映实际行为 |
| 解释"什么"的注释 | `// increment counter` 在 `count++` 上方 | 删除注释——代码足够清楚 |
| 解释"为什么"的注释 | `// Retry because the API is flaky under load` | 保留这些——它们携带代码无法表达的思想 |

**冗余：**

| 模式 | 信号 | 简化 |
|---------|--------|----------------|
| 重复的逻辑 | 多个地方有相同的 5+ 行 | 提取到共享函数 |
| 死代码 | 无法到达的分支、未使用的变量、注释掉的块 | 删除（在确认它确实是死的之后） |
| 不必要的抽象 | 不增加价值的包装器 | 内联包装器，直接调用底层函数 |
| 过度工程的模式 | 工厂的工厂、只有一个策略的策略 | 用简单直接的方法替换 |
| 冗余的类型断言 | 转换为已经推断的类型 | 删除断言 |

### 步骤 3：增量应用更改

一次进行一次简化。在每次更改后运行测试。**将重构更改与功能或错误修复更改分开提交。** 重构和添加功能的 PR 是两个 PR——拆分它们。

```
对于每个简化：
1. 进行更改
2. 运行测试套件
3. 如果测试通过 → 提交（或继续下一个简化）
4. 如果测试失败 → 还原并重新考虑
```

避免将多个简化批处理为一个未经测试的更改。如果出现问题，你需要知道是哪个简化导致的。

**500 规则：** 如果重构会触及超过 500 行，投资于自动化（codemods、sed 脚本、AST 转换），而不是手动进行更改。这种规模的手工编辑容易出错且审查起来很累。

### 步骤 4：验证结果

所有简化之后，退后一步评估整体：

```
比较之前和之后：
- 简化版本是否真的更容易理解？
- 你是否引入了与代码库不一致的任何新模式？
- 差异是否干净且可审查？
- 队友会批准这个更改吗？
```

如果"简化"版本更难理解或审查，请还原。不是每个简化尝试都会成功。

## 语言特定指导

### TypeScript / JavaScript

```typescript
// 简化：不必要的 async 包装器
// 之前
async function getUser(id: string): Promise<User> {
  return await userService.findById(id);
}
// 之后
function getUser(id: string): Promise<User> {
  return userService.findById(id);
}

// 简化：冗长的条件赋值
// 之前
let displayName: string;
if (user.nickname) {
  displayName = user.nickname;
} else {
  displayName = user.fullName;
}
// 之后
const displayName = user.nickname || user.fullName;

// 简化：手动数组构建
// 之前
const activeUsers: User[] = [];
for (const user of users) {
  if (user.isActive) {
    activeUsers.push(user);
  }
}
// 之后
const activeUsers = users.filter((user) => user.isActive);

// 简化：冗余的布尔返回
// 之前
function isValid(input: string): boolean {
  if (input.length > 0 && input.length < 100) {
    return true;
  }
  return false;
}
// 之后
function isValid(input: string): boolean {
  return input.length > 0 && input.length < 100;
}
```

### Python

```python
# 简化：冗长的字典构建
# 之前
result = {}
for item in items:
    result[item.id] = item.name
# 之后
result = {item.id: item.name for item in items}

# 简化：带早期返回的嵌套条件
# 之前
def process(data):
    if data is not None:
        if data.is_valid():
            if data.has_permission():
                return do_work(data)
            else:
                raise PermissionError("No permission")
        else:
            raise ValueError("Invalid data")
    else:
        raise TypeError("Data is None")
# 之后
def process(data):
    if data is None:
        raise TypeError("Data is None")
    if not data.is_valid():
        raise ValueError("Invalid data")
    if not data.has_permission():
        raise PermissionError("No permission")
    return do_work(data)
```

### React / JSX

```tsx
// 简化：冗长的条件渲染
// 之前
function UserBadge({ user }: Props) {
  if (user.isAdmin) {
    return <Badge variant="admin">Admin</Badge>;
  } else {
    return <Badge variant="default">User</Badge>;
  }
}
// 之后
function UserBadge({ user }: Props) {
  const variant = user.isAdmin ? 'admin' : 'default';
  const label = user.isAdmin ? 'Admin' : 'User';
  return <Badge variant={variant}>{label}</Badge>;
}

// 简化：通过中间组件传递属性
// 之前——考虑上下文或组合是否能更好地解决这个问题。
// 这是一个判断调用——标记它，不要自动重构。
```

## 常见合理化理由

| 合理化理由 | 现实 |
|---|---|
| "它正在工作，不需要碰它" | 难以阅读的 working 代码在它崩溃时将难以修复。现在简化节省未来每次更改的时间。 |
| "更少的行总是更简单" | 1 行的嵌套三元并不比 5 行的 if/else 更简单。简单性是关于理解速度，而不是行数。 |
| "我也要快速简化这个不相关的代码" | 无范围的简化会创建嘈杂的差异，并在你不打算更改的代码中带来回归风险。保持专注。 |
| "类型使它自我记录" | 类型记录结构，而不是意图。命名良好的函数比类型签名解释 *为什么* 比解释 *什么* 更好。 |
| "这个抽象以后可能有用" | 不要保留推测性的抽象。如果现在不使用，它就是没有价值的复杂性。删除它，在需要时重新添加。 |
| "原始作者肯定有原因" | 也许。检查 git blame——应用切斯特顿的栅栏。但累积的复杂性通常没有原因；它只是在压力下迭代的残留物。 |
| "我要在添加这个功能时重构" | 将重构与功能工作分开。混合的更改更难审查、还原和在历史中理解。 |

## 危险信号

- 需要修改测试以通过的简化（你可能改变了行为）
- "简化"代码比原始代码更长且更难遵循
- 重命名事物以匹配你的偏好而不是项目约定
- 因为"它使代码更干净"而删除错误处理
- 简化你不完全理解的代码
- 将许多简化批处理为一个大的、难以审查的提交
- 在未被要求的情况下重构当前任务范围之外的代码

## 验证

完成简化传递后：

- [ ] 所有现有测试通过而无需修改
- [ ] 构建成功，没有新的警告
- [ ] Linter/格式化程序通过（没有样式回归）
- [ ] 每个简化都是一个可审查的、增量的更改
- [ ] 差异是干净的——没有混合的不相关更改
- [ ] 简化后的代码遵循项目约定（根据 CLAUDE.md 或等效文件检查）
- [ ] 没有删除或削弱错误处理
- [ ] 没有留下死代码（未使用的导入、无法到达的分支）
- [ ] 队友或审查代理会批准这个更改作为净改进
