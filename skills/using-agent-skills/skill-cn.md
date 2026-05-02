---
name: using-agent-skills
description: 发现和调用代理技能。适用于启动会话或需要发现哪个技能适用于当前任务时。这是管理所有其他技能如何被发现和调用的元技能。
---

# 使用代理技能 (Using Agent Skills)

## 概述

Agent Skills 是按开发阶段组织的一整套工程工作流技能。每个技能编码了高级工程师遵循的特定流程。这个元技能帮助你发现并应用适合你当前任务的技能。

## 技能发现

当任务到达时，识别开发阶段并应用相应的技能：

```
任务到达
    │
    ├── 模糊想法/需要细化？ ──→ idea-refine
    ├── 新项目/功能/变更？ ──→ spec-driven-development
    ├── 有规格说明，需要任务？ ──────→ planning-and-task-breakdown
    ├── 实施代码？ ────────────→ incremental-implementation
    │   ├── UI 工作？ ─────────────────→ frontend-ui-engineering
    │   ├── API 工作？ ────────────────→ api-and-interface-design
    │   ├── 需要更好的上下文？ ─────→ context-engineering
    │   └── 需要文档验证的代码？ ───→ source-driven-development
    ├── 编写/运行测试？ ────────→ test-driven-development
    │   └── 基于浏览器？ ───────────→ browser-testing-with-devtools
    ├── 什么东西坏了？ ──────────────→ debugging-and-error-recovery
    ├── 审核代码？ ───────────────→ code-review-and-quality
    │   ├── 安全问题？ ───────→ security-and-hardening
    │   └── 性能问题？ ────────→ performance-optimization
    ├── 提交/分支？ ─────────→ git-workflow-and-versioning
    ├── CI/CD 管道工作？ ──────────→ ci-cd-and-automation
    ├── 编写文档/ADR？ ───────────→ documentation-and-adrs
    └── 部署/发布？ ─────────→ shipping-and-launch
```

## 核心操作行为

这些行为适用于所有时间、所有技能。它们是不可协商的。

### 1. 揭示假设

在实施任何非平凡的东西之前，明确陈述你的假设：

```
我正在做的假设：
1. [关于需求的假设]
2. [关于架构的假设]
3. [关于范围的假设]
→ 现在纠正我，否则我将按这些假设进行。
```

不要默默地填补模糊的需求。最常见的失败模式是做出错误的假设并在未检查的情况下运行它们。尽早揭示不确定性——它比返工便宜。

### 2. 主动管理困惑

当你遇到不一致、冲突的需求或不清楚的规格说明时：

1. **停止。** 不要用猜测继续。
2. 说出具体的困惑。
3. 提出权衡或询问澄清性问题。
4. 在继续之前等待解决方案。

**坏：** 默默地选择一个解释并希望它是正确的。
**好：** "我在规格说明中看到 X 但在现有代码中看到 Y。哪个优先？"

### 3. 在必要时推回

你不是一台说是的机器。当一种方法有明显问题时：

- 直接指出问题
- 解释具体的缺点（尽可能量化——"这增加了约200ms延迟"而不是"这可能会更慢"）
- 提出替代方案
- 如果人类在完全知情的情况下否决，接受他们的决定

谄媚是一种失败模式。"当然！"后面跟着实施一个坏主意对任何人都没有帮助。诚实的技术分歧比虚假的一致更有价值。

### 4. 强制执行简单性

你的自然倾向是过度复杂化。积极地抵制它。

在完成任何实施之前，问：
- 这可以用更少的行完成吗？
- 这些抽象是否值得它们的复杂性？
-  staff 工程师会看着这个说"你为什么不直接..."吗？

如果你构建了1000行而100行就足够了，你已经失败了。 prefer 无聊、明显的解决方案。聪明是昂贵的。

### 5. 保持范围纪律

只触及你被要求触及的内容。

不要：
- 删除你不理解的注释
- "清理"与任务正交的代码
- 作为副作用重构相邻系统
- 未经明确批准删除看起来未使用的代码
- 添加规格说明中没有的功能，因为它们"看起来有用"

你的工作是外科般的精确，而不是主动的翻新。

### 6. 验证，不要假设

每个技能都包括一个验证步骤。在验证通过之前，任务不算完成。"看起来对"永远不够——必须有证据（通过的测试、构建输出、运行时数据）。

## 要避免的失败模式

这些是看起来像生产力但会产生问题的微妙错误：

1. 不检查就做出错误假设
2. 不管理你自己的困惑——迷失时继续前进
3. 不揭示你注意到的不一致
4. 对非明显的决策不提出权衡
5. 对有明显问题的方法谄媚（"当然！"）
6. 过度复杂化代码和 API
7. 修改与任务正交的代码或注释
8. 删除你不完全理解的东西
9. 因为"很明显"而在没有规格说明的情况下构建
10. 因为"看起来对"而跳过验证

## 技能规则

1. **在开始工作之前检查是否有适用的技能。** 技能编码了防止常见错误的流程。

2. **技能是工作流，不是建议。** 按顺序遵循步骤。不要跳过验证步骤。

3. **可以应用多个技能。** 功能实施可能涉及 `idea-refine` → `spec-driven-development` → `planning-and-task-breakdown` → `incremental-implementation` → `test-driven-development` → `code-review-and-quality` → `shipping-and-launch` 的顺序。

4. **当有疑问时，从规格说明开始。** 如果任务不是平凡的且没有规格说明，从 `spec-driven-development` 开始。

## 生命周期序列

对于完整的功能，典型的技能序列是：

```
1. idea-refine                 → 细化模糊想法
2. spec-driven-development     → 定义我们在构建什么
3. planning-and-task-breakdown → 分解为可验证的块
4. context-engineering         → 在正确的时间加载正确的上下文
5. source-driven-development   → 在实施前根据官方文档验证
6. incremental-implementation  → 逐片构建
7. test-driven-development     → 证明每片都工作
8. code-review-and-quality     → 合并前审核
9. git-workflow-and-versioning → 干净的提交历史
10. documentation-and-adrs     → 记录决策
11. shipping-and-launch        → 安全部署
```

不是每个任务都需要每个技能。Bug 修复可能只需要：`debugging-and-error-recovery` → `test-driven-development` → `code-review-and-quality`。

## 快速参考

| 阶段 | 技能 | 单行摘要 |
|-------|-------|-----------------|
| 定义 | idea-refine | 通过结构化的发散和收敛思维细化想法 |
| 定义 | spec-driven-development | 代码之前的需求和验收标准 |
| 计划 | planning-and-task-breakdown | 分解为小的、可验证的任务 |
| 构建 | incremental-implementation | 薄的垂直切片，在扩展之前测试每个 |
| 构建 | source-driven-development | 在实施前根据官方文档验证 |
| 构建 | context-engineering | 在正确的时间提供正确的上下文 |
| 构建 | frontend-ui-engineering | 具有可访问性的生产质量 UI |
| 构建 | api-and-interface-design | 具有清晰契约的稳定接口 |
| 验证 | test-driven-development | 先失败的测试，然后使它通过 |
| 验证 | browser-testing-with-devtools | 用于运行时验证的 Chrome DevTools MCP |
| 验证 | debugging-and-error-recovery | 重现 → 定位 → 修复 → 防护 |
| 审核 | code-review-and-quality | 带质量门的五轴审核 |
| 审核 | security-and-hardening | OWASP 预防、输入验证、最小权限 |
| 审核 | performance-optimization | 先测量，只优化重要的事情 |
| 发布 | git-workflow-and-versioning | 原子提交，干净的历史 |
| 发布 | ci-cd-and-automation | 每次变更的自动化质量门 |
| 发布 | documentation-and-adrs | 记录原因，而不仅仅是内容 |
| 发布 | shipping-and-launch | 发布前检查表、监控、回滚计划 |
