# agent-skills

这是 agent-skills 项目——为 AI 编码代理提供的一套生产级工程技能。

## 项目结构

```
skills/       → 核心技能（每个目录都有 SKILL.md）
agents/       → 可重用的代理角色（code-reviewer、test-engineer、security-auditor）
hooks/        → 会话生命周期钩子
.claude/commands/ → 斜杠命令（/spec、/plan、/build、/test、/review、/code-simplify、/ship）
references/   → 补充检查表（测试、性能、安全、可访问性）
docs/         → 不同工具的设置指南
```

## 按阶段分类的技能

**定义：** spec-driven-development
**计划：** planning-and-task-breakdown
**构建：** incremental-implementation、test-driven-development、context-engineering、source-driven-development、frontend-ui-engineering、api-and-interface-design
**验证：** browser-testing-with-devtools、debugging-and-error-recovery
**审查：** code-review-and-quality、code-simplification、security-and-hardening、performance-optimization
**发布：** git-workflow-and-versioning、ci-cd-and-automation、deprecation-and-migration、documentation-and-adrs、shipping-and-launch

## 约定

- 每个技能都位于 `skills/<name>/SKILL.md`
- 带有 `name` 和 `description` 字段的 YAML 前言
- 描述以技能的功能开头（第三人称），后跟触发条件（"Use when..."）
- 每个技能都有：概述、何时使用、流程、常见合理化借口、危险信号、验证
- 引用位于 `references/` 中，不在技能目录内
- 仅当内容超过100行时才创建支持文件

## 命令

- `npm test`——不适用（这是一个文档项目）
- 验证：检查所有 SKILL.md 文件是否具有带 name 和 description 的有效 YAML 前言

## 边界

- 始终：遵循新技能的 skill-anatomy.md 格式
- 绝不：添加模糊建议而不是可操作流程的技能
- 绝不：在技能之间复制内容——改为引用其他技能
