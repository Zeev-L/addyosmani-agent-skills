---
name: git-workflow-and-versioning
description: 构建 git 工作流实践。在进行任何代码更改时使用。在提交、分支、解决冲突或需要组织跨多个并行流的工作时使用。
---

# Git 工作流和版本控制

## 概述

Git 是你的安全网。将提交视为保存点，分支视为沙盒，历史视为文档。随着 AI 代理高速生成代码，有纪律的版本控制是保持更改可管理、可审查和可逆转的机制。

## 使用场景

始终。每个代码更改都流经 git。

## 核心原则

### 基于主干的开发（推荐）

保持 `main` 始终可部署。在 1-3 天内合并回的短生命周期功能分支中工作。长生命周期的开发分支是隐藏成本——它们分歧、创建合并冲突并延迟集成。DORA 研究一致表明，基于主干的开发与高性能工程团队相关。

```
main ──●──●──●──●──●──●──●──●──  （始终可部署）
        ╲      ╱  ╲    ╱
         ●──●─╱    ●──╱    ← 短生命周期功能分支（1-3 天）
```

这是推荐的默认设置。使用 gitflow 或长生命周期分支的团队可以使原则（原子提交、小更改、描述性消息）适应他们的分支模型——提交纪律比特定的分支策略更重要。

- **开发分支是成本。** 分支存在的每一天，它都会累积合并风险。
- **发布分支是可接受的。** 当你需要在 main 向前移动时稳定发布。
- **功能标志 > 长生命周期分支。** 优先在标志后面部署不完整的工作，而不是在分支上保留数周。

### 1. 尽早提交，经常提交

每个成功的增量都获得自己的提交。不要累积大量未提交的更改。

```
工作模式：
  实现切片 → 测试 → 验证 → 提交 → 下一个切片

不要这样：
  实现一切 → 希望它工作 → 巨型提交
```

提交是保存点。如果下一个更改破坏了某些东西，你可以立即还原到最后一个已知良好的状态。

### 2. 原子提交

每个提交做一件逻辑事情：

```
# 好：每个提交都是独立的
git log --oneline
a1b2c3d 添加带验证的任务创建端点
d4e5f6g 添加任务创建表单组件
h7i8j9k 将表单连接到 API 并添加加载状态
m1n2o3p 添加任务创建测试（单元测试 + 集成测试）

# 坏：一切都混合在一起
git log --oneline
x1y2z3a 添加任务功能、修复侧边栏、更新依赖项、重构实用程序
```

### 3. 描述性消息

提交消息解释 *为什么*，而不仅仅是 *什么*：

```
# 好：解释意图
feat: 向注册端点添加电子邮件验证

防止无效的电子邮件格式到达数据库。
在路由处理程序级别使用 Zod 模式验证，
与 auth.ts 中现有的验证模式一致。

# 坏：描述差异中显而易见的内容
update auth.ts
```

**格式：**
```
<类型>: <简短描述>

<解释为什么的可选正文，而不是什么>
```

**类型：**
- `feat` —— 新功能
- `fix` —— 错误修复
- `refactor` —— 既不修复错误也不添加功能的代码更改
- `test` —— 添加或更新测试
- `docs` —— 仅文档
- `chore` —— 工具、依赖项、配置

### 4. 保持关注点分离

不要将格式化更改与行为更改结合。不要将重构与功能结合。每种类型的更改应该是单独的提交——理想情况下是单独的 PR：

```
# 好：分离关注点
git commit -m "refactor: extract validation logic to shared utility"
git commit -m "feat: add phone number validation to registration"

# 坏：混合关注点
git commit -m "refactor validation and add phone number field"
```

**将重构与功能工作分开。** 重构更改和功能更改是两个不同的更改——分别提交它们。这使得每个更改更容易审查、还原和在历史中理解。小的清理（重命名变量）可以根据审查者的判断包含在功能提交中。

### 5. 调整更改大小

目标每个提交/PR 约 100 行。超过约 1000 行的更改应该拆分。有关如何分解大型更改的拆分策略，请参见 `code-review-and-quality`。

```
~100 行  → 易于审查，易于还原
~300 行  → 单个逻辑更改可接受
~1000 行 → 拆分为较小的更改
```

## 分支策略

### 功能分支

```
main （始终可部署）
  │
  ├── feature/task-creation    ← 每个分支一个功能
  ├── feature/user-settings    ← 并行工作
  └── fix/duplicate-tasks      ← 错误修复
```

- 从 `main`（或团队的默认分支）分支
- 保持分支短生命周期（1-3 天内合并）—— 长生命周期分支是隐藏成本
- 合并后删除分支
- 对于不完整的功能，优先功能标志而不是长生命周期分支

### 分支命名

```
feature/<简短描述>   → feature/task-creation
fix/<简短描述>       → fix/duplicate-tasks
chore/<简短描述>     → chore/update-deps
refactor/<简短描述>  → refactor/auth-module
```

## 使用工作树

对于并行 AI 代理工作，使用 git worktrees 同时运行多个分支：

```bash
# 为功能分支创建工作树
git worktree add ../project-feature-a feature/task-creation
git worktree add ../project-feature-b feature/user-settings

# 每个工作树都是一个带有自己分支的单独目录
# 代理可以并行工作而不互相干扰
ls ../
  project/              ← main 分支
  project-feature-a/    ← task-creation 分支
  project-feature-b/    ← user-settings 分支

# 完成后，合并并清理
git worktree remove ../project-feature-a
```

好处：
- 多个代理可以同时处理不同的功能
- 不需要分支切换（每个目录有自己的分支）
- 如果一个实验失败，删除工作树 —— 没有丢失任何东西
- 更改在明确合并之前是隔离的

## 保存点模式

```
代理开始工作
    │
    ├── 进行更改
    │   ├── 测试通过？ → 提交 → 继续
    │   └── 测试失败？ → 还原到最后一个提交 → 调查
    │
    ├── 进行另一个更改
    │   ├── 测试通过？ → 提交 → 继续
    │   └── 测试失败？ → 还原到最后一个提交 → 调查
    │
    └── 功能完成 → 所有提交形成干净的历史
```

这种模式意味着你永远不会丢失超过一个增量的工作。如果代理偏离轨道，`git reset --hard HEAD` 会带你回到最后一个成功状态。

## 更改摘要

在任何修改之后，提供结构化摘要。这使审查更容易，记录范围纪律，并反映意外的更改：

```
更改完成：
- src/routes/tasks.ts：向 POST 端点添加验证中间件
- src/lib/validation.ts：使用 Zod 添加 TaskCreateSchema

我故意没有碰：
- src/routes/auth.ts：有类似的验证差距，但超出范围
- src/middleware/error.ts：错误格式可以改进（单独的任务）

潜在关注点：
- Zod 模式是严格的 —— 拒绝额外字段。确认这是期望的。
- 添加了 zod 作为依赖项（72KB gzipped）—— 已经在 package.json 中
```

这种模式及早捕获错误的假设，并为审查者提供更改的清晰地图。"没有碰"部分尤其重要 —— 它显示你行使了范围纪律，不会进行未经请求的翻新。

## 提交前卫生

在每次提交之前：

```bash
# 1. 检查你即将提交的内容
git diff --staged

# 2. 确保没有秘密
git diff --staged | grep -i "password\|secret\|api_key\|token"

# 3. 运行测试
npm test

# 4. 运行 linting
npm run lint

# 5. 运行类型检查
npx tsc --noEmit
```

使用 git hooks 自动化此操作：

```json
// package.json（使用 lint-staged + husky）
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

## 处理生成的文件

- **仅当项目期望它们时才提交生成的文件**（例如，`package-lock.json`、`Prisma` 迁移）
- **不要提交** 构建输出（`dist/`、` .next/`）、环境文件（`.env`）或 IDE 配置（`.vscode/settings.json`，除非共享）
- **有一个 `.gitignore`** 涵盖：`node_modules/`、`dist/`、` .env`、` .env.local`、`*.pem`

## 使用 Git 进行调试

```bash
# 查找哪个提交引入了错误
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit>
# Git 检出中间点；在每个点运行你的测试以缩小范围

# 查看最近更改了什么
git log --oneline -20
git diff HEAD~5..HEAD -- src/

# 查找最后更改特定行的人
git blame src/services/task.ts

# 搜索带有特定关键词的提交消息
git log --grep="validation" --oneline
```

## 常见合理化理由

| 合理化理由 | 现实 |
|---|---|
| "我会在功能完成时提交" | 一个巨型提交是无法审查、调试或还原的。提交每个切片。 |
| "消息不重要" | 消息是文档。未来的你（和未来的代理）将需要理解更改了什么以及为什么。 |
| "我稍后会压缩它" | 压缩会破坏开发叙述。从一开始就更喜欢干净的增量提交。 |
| "分支增加开销" | 短生命周期分支是免费的，并防止冲突的工作相互碰撞。长生命周期分支是问题 —— 在 1-3 天内合并。 |
| "我稍后会拆分这个更改" | 大型更改更难审查，部署风险更高，并且更难还原。在提交之前拆分，而不是之后。 |
| "我不需要 .gitignore" | 直到带有生产秘密的 `.env` 被提交。立即设置它。 |

## 危险信号

- 大型未提交更改累积
- 像 "fix"、"update"、"misc" 这样的提交消息
- 格式化更改与行为更改混合
- 项目中没有 `.gitignore`
- 提交 `node_modules/`、`.env` 或构建工件
- 与 main 显著分歧的长生命周期分支
- 强制推送到共享分支

## 验证

对于每个提交：

- [ ] 提交做一件逻辑事情
- [ ] 消息解释为什么，遵循类型约定
- [ ] 在提交之前测试通过
- [ ] 差异中没有秘密
- [ ] 没有仅格式化更改与行为更改混合
- [ ] `.gitignore` 涵盖标准排除项
