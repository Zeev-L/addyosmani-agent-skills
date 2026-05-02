# AGENTS.md

本文件为在此存储库中工作时的人工智能编码代理（Claude Code、Cursor、Copilot、Antigravity 等）提供指导。

## 存储库概述

为高级软件工程师提供的 Claude.ai 和 Claude Code 技能集合。技能是打包的指令和脚本，用于扩展 Claude 和你的编码代理的能力。

## OpenCode 集成

OpenCode 使用由 `skill` 工具和本存储库的 `/skills` 目录驱动的**技能驱动执行模型**。

### 核心规则

- 如果任务匹配某个技能，你必须调用它
- 技能位于 `skills/<skill-name>/SKILL.md`
- 如果技能适用，永远不要直接实施
- 始终准确遵循技能指令（不要部分应用它们）

### 意图 → 技能映射

代理应该自动将用户意图映射到技能：

- 功能 / 新功能 → `spec-driven-development`，然后 `incremental-implementation`、`test-driven-development`
- 规划 / 分解 → `planning-and-task-breakdown`
- Bug / 失败 / 意外行为 → `debugging-and-error-recovery`
- 代码审查 → `code-review-and-quality`
- 重构 / 简化 → `code-simplification`
- API 或接口设计 → `api-and-interface-design`
- UI 工作 → `frontend-ui-engineering`

### 生命周期映射（隐式命令）

OpenCode 不支持像 `/spec` 或 `/plan` 这样的斜杠命令。

相反，代理必须在内部遵循这个生命周期：

- 定义 → `spec-driven-development`
- 计划 → `planning-and-task-breakdown`
- 构建 → `incremental-implementation` + `test-driven-development`
- 验证 → `debugging-and-error-recovery`
- 审查 → `code-review-and-quality`
- 发布 → `shipping-and-launch`

### 执行模型

对于每个请求：

1. 确定是否有任何技能适用（即使只有1%的机会）
2. 使用 `skill` 工具调用适当的技能
3. 严格遵循技能工作流
4. 只有在所需步骤（规格说明、计划等）完成后才继续进行实施

### 反合理化

以下想法是不正确的，必须忽略：

- "这对于技能来说太小了"
- "我可以快速实现这个"
- "我先收集上下文"

正确行为：

- 始终首先检查并使用技能

这确保了 OpenCode 的行为与具有完整工作流强制执行的 Claude Code 类似。

## 编排：角色、技能和命令

此存储库有三个可组合层。它们有不同的工作，不应混淆：

- **技能**（`skills/<name>/SKILL.md`）- 带有步骤和退出标准的工作流。*如何*。当意图匹配时的强制跳跃。
- **角色**（`agents/<role>.md`）- 具有视角和输出格式的角色。*谁*。
- **斜杠命令**（`.claude/commands/*.md`）- 面向用户的入口点。*何时*。编排层。

组合规则：**用户（或斜杠命令）是编排器。角色不调用其他角色。** 角色可以调用技能。

此存储库认可的唯一多角色编排模式是**带有合并步骤的并行扇出**——由 `/ship` 使用，同时运行 `code-reviewer`、`security-auditor` 和 `test-engineer` 并综合他们的报告。不要构建决定调用哪个其他角色的"路由器"角色；那是斜杠命令和意图映射的工作。

有关决策矩阵，请参见 [agents/README.md](agents/README.md)，有关完整模式目录，请参见 [references/orchestration-patterns.md](references/orchestration-patterns.md)。

**Claude Code 互操作：** `agents/` 中的角色作为 Claude Code 子代理（从此插件的 `agents/` 目录自动发现）和 Agent Teams 队友（生成时按名称引用）工作。两个平台约束与我们的规则一致：子代理无法生成其他子代理，团队无法嵌套。插件代理静默忽略 `hooks`、`mcpServers` 和 `permissionMode` 前言字段。

## 创建新技能

### 目录结构

```
skills/
  {skill-name}/           # kebab-case 目录名称
    SKILL.md              # 必需：技能定义
    scripts/              # 必需：可执行脚本
      {script-name}.sh    # Bash 脚本（首选）
  {skill-name}.zip        # 必需：打包以供分发
```

### 命名约定

- **技能目录**：`kebab-case`（例如 `web-quality`）
- **SKILL.md**：始终大写，始终使用这个确切的文件名
- **脚本**：`kebab-case.sh`（例如，`deploy.sh`、`fetch-logs.sh`）
- **Zip 文件**：必须与目录名称完全匹配：`{skill-name}.zip`

### SKILL.md 格式

```markdown
---
name: {skill-name}
description: {一句话描述何时使用此技能。包括触发短语，如"Deploy my app"、"Check logs"等。}
---

# {技能标题}

{技能功能的简要描述。}

## 工作原理

{解释技能工作流的编号列表}

## 用法

```bash
bash /mnt/skills/user/{skill-name}/scripts/{script}.sh [args]
```

**参数：**
- `arg1` - 描述（默认为 X）

**示例：**
{显示2-3个常见使用模式}

## 输出

{显示用户将看到的示例输出}

## 向用户呈现结果

{Claude 在向用户呈现结果时应如何格式化的模板}

## 故障排除

{常见问题和解决方案，特别是网络/权限错误}
```

### 上下文效率的最佳实践

技能是按需加载的——只有技能名称和描述在启动时加载。完整的 `SKILL.md` 仅在代理决定技能相关时才加载到上下文中。为了最小化上下文使用：

- **保持 SKILL.md 在500行以内**——将详细的参考材料放在单独的文件中
- **编写具体的描述**——帮助代理准确知道何时激活技能
- **使用渐进式披露**——引用仅当需要时才读取的支持文件
- **优先使用脚本而不是内联代码**——脚本执行不消耗上下文（只有输出会）
- **文件引用工作一层深度**——直接从 SKILL.md 链接到支持文件

### 脚本要求

- 使用 `#!/bin/bash` shebang
- 使用 `set -e` 实现快速失败行为
- 将状态消息写入 stderr：`echo "Message" >&2`
- 将机器可读的输出（JSON）写入 stdout
- 为临时文件包含清理陷阱
- 将脚本路径引用为 `/mnt/skills/user/{skill-name}/scripts/{script}.sh`

### 创建 Zip 包

创建或更新技能后：

```bash
cd skills
zip -r {skill-name}.zip {skill-name}/
```

### 最终用户安装

为用户记录这两种安装方法：

**Claude Code：**
```bash
cp -r skills/{skill-name} ~/.claude/skills/
```

**claude.ai：**
将技能添加到项目知识或将 SKILL.md 内容粘贴到对话中。

如果技能需要网络访问，请指示用户在 `claude.ai/settings/capabilities` 添加所需的域。
