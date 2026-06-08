# Agent Skills

**为 AI 编码代理提供的生产级工程技能。**

技能编码了高级工程师在构建软件时使用的工作流、质量门和最佳实践。这些技能被打包，以便 AI 代理在开发的每个阶段都能一致地遵循它们。

```
  DEFINE          PLAN           BUILD          VERIFY         REVIEW          SHIP
 ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐      ┌──────┐
 │ Idea │ ───▶ │ Spec │ ───▶ │ Code │ ───▶ │ Test │ ───▶ │  QA  │ ───▶ │  Go  │
 │Refine│      │  PRD │      │ Impl │      │Debug │      │ Gate │      │ Live │
 └──────┘      └──────┘      └──────┘      └──────┘      └──────┘      └──────┘
  /spec          /plan          /build        /test         /review       /ship
```

---

## 命令

7个映射到开发生命周期的斜杠命令。每个命令都会自动激活正确的技能。

| 你正在做什么 | 命令 | 关键原则 |
|-------------------|---------|---------------|
| 定义要构建什么 | `/spec` | 代码之前的规格说明 |
| 计划如何构建它 | `/plan` | 小的、原子的任务 |
| 增量构建 | `/build` | 一次一个切片 |
| 证明它有效 | `/test` | 测试就是证据 |
| 合并前审查 | `/review` | 改善代码健康度 |
| 简化代码 | `/code-simplify` | 清晰胜过聪明 |
| 发布到生产环境 | `/ship` | 更快更安全 |

技能也会根据你正在做的事情自动激活——设计 API 会触发 `api-and-interface-design`，构建 UI 会触发 `frontend-ui-engineering`，以此类推。

---

## 快速开始

<details>
<summary><b>Claude Code（推荐）</b></summary>

**Marketplace 安装：**

```
/plugin marketplace add addyosmani/agent-skills
/plugin install agent-skills@addy-agent-skills
```

> **SSH 错误？** Marketplace 通过 SSH 克隆存储库。如果你没有在 GitHub 上设置 SSH 密钥，请[添加你的 SSH 密钥](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)或仅对 fetch 切换到 HTTPS：
> ```bash
> git config --global url."https://github.com/".insteadOf "git@github.com:"
> ```

**本地 / 开发：**

```bash
git clone https://github.com/addyosmani/agent-skills.git
claude --plugin-dir /path/to/agent-skills
```

</details>

<details>
<summary><b>Cursor</b></summary>

将任何 `SKILL.md` 复制到 `.cursor/rules/`，或引用完整的 `skills/` 目录。请参见 [docs/cursor-setup.md](docs/cursor-setup.md)。

</details>

<details>
<summary><b>Gemini CLI</b></summary>

安装为原生技能以自动发现，或添加到 `GEMINI.md` 以获得持久上下文。请参见 [docs/gemini-cli-setup.md](docs/gemini-cli-setup.md)。

**从存储库安装：**

```bash
gemini skills install https://github.com/addyosmani/agent-skills.git --path skills
```

**从本地克隆安装：**

```bash
gemini skills install ./agent-skills/skills/
```

</details>

<details>
<summary><b>Windsurf</b></summary>

将技能内容添加到你的 Windsurf 规则配置中。请参见 [docs/windsurf-setup.md](docs/windsurf-setup.md)。

</details>

<details>
<summary><b>OpenCode</b></summary>

通过 AGENTS.md 和 `skill` 工具使用代理驱动的技能执行。

请参见 [docs/opencode-setup.md](docs/opencode-setup.md)。

</details>

<details>
<summary><b>GitHub Copilot</b></summary>

使用来自 `agents/` 的代理定义作为 Copilot 角色，并在 `.github/copilot-instructions.md` 中使用技能内容。请参见 [docs/copilot-setup.md](docs/copilot-setup.md)。

</details>

<details>
 <summary><b>Kiro IDE & CLI </b></summary>
 Kiro 的技能位于 ".kiro/skills/" 下，可以存储在项目或全局级别。Kiro 也支持 Agents.md。请参见 Kiro 文档：https://kiro.dev/docs/skills/
</details>

<details>
<summary><b>Codex / 其他代理</b></summary>

技能是纯 Markdown——它们适用于任何接受系统提示或指令文件的代理。请参见 [docs/getting-started.md](docs/getting-started.md)。

</details>

---

## 全部 20 个技能

上面的命令是入口点。在底层，它们激活了这 20 个技能——每个都是带有步骤、验证门和反合理化表的结构化工作流。你也可以直接引用任何技能。

### 定义 - 澄清要构建什么

| 技能 | 功能 | 使用场景 |
|-------|-------------|----------|
| [idea-refine](skills/idea-refine/SKILL.md) | 结构化的发散/收敛思维，将模糊想法转化为具体提案 | 你有一个需要探索的粗略概念 |
| [spec-driven-development](skills/spec-driven-development/SKILL.md) | 在编写任何代码之前编写涵盖目标、命令、结构、代码风格、测试和边界的 PRD | 启动新项目、功能或重大变更 |

### 计划 - 分解它

| 技能 | 功能 | 使用场景 |
|-------|-------------|----------|
| [planning-and-task-breakdown](skills/planning-and-task-breakdown/SKILL.md) | 将规格说明分解为带有验收标准和依赖关系排序的小型、可验证任务 | 你有一个规格说明并需要可实施的单元 |

### 构建 - 编写代码

| 技能 | 功能 | 使用场景                  |
|-------|-------------|-----------------------|
| [incremental-implementation](skills/incremental-implementation/SKILL.md) | 薄的垂直切片 - 实施、测试、验证、提交。功能标志、安全默认值、友好回滚的变更 | 触及多个文件的任何变更           |
| [test-driven-development](skills/test-driven-development/SKILL.md) | 红-绿-重构，测试金字塔（80/15/5），测试大小，DAMP 优于 DRY，Beyoncé 规则，浏览器测试 | 实施逻辑、修复 bug 或更改行为     |
| [context-engineering](skills/context-engineering/SKILL.md) | 在正确的时间向代理提供正确的信息 - 规则文件、上下文打包、MCP 集成 | 启动会话、切换任务或输出质量下降时     |
| [source-driven-development](skills/source-driven-development/SKILL.md) | 将每个框架决策基于官方文档 - 验证、引用来源、标记未验证的内容 | 你想要任何框架或库的权威的、引用来源的代码 |
| [frontend-ui-engineering](skills/frontend-ui-engineering/SKILL.md) | 组件架构、设计系统、状态管理、响应式设计、WCAG 2.1 AA 可访问性 | 构建或修改面向用户的界面          |
| [api-and-interface-design](skills/api-and-interface-design/SKILL.md) | 契约优先设计、Hyrum 定律、单版本规则、错误语义、边界验证 | 设计 API、模块边界或公共接口      |

### 验证 - 证明它有效

| 技能 | 功能 | 使用场景 |
|-------|-------------|----------|
| [browser-testing-with-devtools](skills/browser-testing-with-devtools/SKILL.md) | 用于实时运行时数据的 Chrome DevTools MCP - DOM 检查、控制台日志、网络跟踪、性能分析 | 构建或调试任何在浏览器中运行的东西 |
| [debugging-and-error-recovery](skills/debugging-and-error-recovery/SKILL.md) | 五步分流：重现、定位、简化、修复、防护。停止线规则、安全回退 | 测试失败、构建中断或行为意外 |

### 审查 - 合并前的质量门

| 技能 | 功能 | 使用场景 |
|-------|-------------|----------|
| [code-review-and-quality](skills/code-review-and-quality/SKILL.md) | 五轴审查、变更大小（约100行）、严重性标签（Nit/Optional/FYI）、审查速度规范、拆分策略 | 合并任何变更之前 |
| [code-simplification](skills/code-simplification/SKILL.md) | 切斯特顿的栅栏、500 规则、在保持确切行为的同时降低复杂性 | 代码可以工作但比它应该的更难阅读或维护 |
| [security-and-hardening](skills/security-and-hardening/SKILL.md) | OWASP Top 10 预防、认证模式、密钥管理、依赖审计、三层边界系统 | 处理用户输入、认证、数据存储或外部集成 |
| [performance-optimization](skills/performance-optimization/SKILL.md) | 先测量方法 - Core Web Vitals 目标、性能分析工作流、包分析、反模式检测 | 存在性能要求或你怀疑有回归 |

### 发布 - 自信地部署

| 技能 | 功能 | 使用场景 |
|-------|-------------|----------|
| [git-workflow-and-versioning](skills/git-workflow-and-versioning/SKILL.md) | 基于主干的开发、原子提交、变更大小（约100行）、作为保存点的提交模式 | 进行任何代码变更（总是） |
| [ci-cd-and-automation](skills/ci-cd-and-automation/SKILL.md) | 左移、更快更安全、功能标志、质量门管道、失败反馈循环 | 设置或修改构建和部署管道 |
| [deprecation-and-migration](skills/deprecation-and-migration/SKILL.md) | 代码即负债心态、强制性与建议性弃用、迁移模式、僵尸代码移除 | 移除旧系统、迁移用户或淘汰功能 |
| [documentation-and-adrs](skills/documentation-and-adrs/SKILL.md) | 架构决策记录、API 文档、内联文档标准 - 记录*原因* | 做出架构决策、更改 API 或发布功能 |
| [shipping-and-launch](skills/shipping-and-launch/SKILL.md) | 发布前检查表、功能标志生命周期、分阶段推出、回滚程序、监控设置 | 准备部署到生产环境 |

---

## 代理角色

用于针对性审查的预配置专家角色：

| 代理 | 角色 | 视角 |
|-------|------|-------------|
| [code-reviewer](agents/code-reviewer.md) | 高级 Staff 工程师 | 以"staff 工程师会批准这个吗？"为标准进行五轴代码审查 |
| [test-engineer](agents/test-engineer.md) | QA 专家 | 测试策略、覆盖率分析、Prove-It 模式 |
| [security-auditor](agents/security-auditor.md) | 安全工程师 | 漏洞检测、威胁建模、OWASP 评估 |

---

## 参考检查表

技能在需要时拉入的快速参考材料：

| 参考 | 覆盖内容 |
|-----------|--------|
| [testing-patterns.md](references/testing-patterns.md) | 测试结构、命名、mocking、React/API/E2E 示例、反模式 |
| [security-checklist.md](references/security-checklist.md) | 提交前检查、认证、输入验证、标头、CORS、OWASP Top 10 |
| [performance-checklist.md](references/performance-checklist.md) | Core Web Vitals 目标、前端/后端检查表、测量命令 |
| [accessibility-checklist.md](references/accessibility-checklist.md) | 键盘导航、屏幕阅读器、视觉设计、ARIA、测试工具 |

---

## 技能如何工作

每个技能都遵循一致的结构：

```
┌─────────────────────────────────────────────────┐
│  SKILL.md                                       │
│                                                 │
│  ┌─ 前言 ─────────────────────────────┐  │
│  │ name: lowercase-hyphen-name               │  │
│  │ description: Guides agents through [task].│  │
│  │              Use when…                    │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  Overview         → 这个技能做什么                │
│  When to Use      → 触发条件                       │
│  Process          → 逐步工作流                     │
│  Rationalizations → 借口 + 反驳                     │
│  Red Flags        → 出现问题的迹象                   │
│  Verification     → 证据要求                       │
└─────────────────────────────────────────────────┘
```

**关键设计选择：**

- **流程，而不是散文。** 技能是代理遵循的工作流，而不是他们阅读的参考文档。每个都有步骤、检查点和退出标准。
- **反合理化。** 每个技能都包含一个常见借口的表格，代理使用这些借口来跳过步骤（例如，"我稍后会添加测试"），并附有记录的反驳论点。
- **验证是不可协商的。** 每个技能都以证据要求结束——测试通过、构建输出、运行时数据。"看起来对"永远不够。
- **渐进式披露。** `SKILL.md` 是入口点。支持参考仅在需要时才加载，保持令牌使用最小化。

---

## 项目结构

```
agent-skills/
├── skills/                            # 20 个核心技能（每个目录都有 SKILL.md）
│   ├── idea-refine/                   #   定义
│   ├── spec-driven-development/       #   定义
│   ├── planning-and-task-breakdown/   #   计划
│   ├── incremental-implementation/    #   构建
│   ├── context-engineering/           #   构建
│   ├── source-driven-development/     #   构建
│   ├── frontend-ui-engineering/       #   构建
│   ├── test-driven-development/       #   构建
│   ├── api-and-interface-design/      #   构建
│   ├── browser-testing-with-devtools/ #   验证
│   ├── debugging-and-error-recovery/  #   验证
│   ├── code-review-and-quality/       #   审查
│   ├── code-simplification/          #   审查
│   ├── security-and-hardening/        #   审查
│   ├── performance-optimization/      #   审查
│   ├── git-workflow-and-versioning/   #   发布
│   ├── ci-cd-and-automation/          #   发布
│   ├── deprecation-and-migration/     #   发布
│   ├── documentation-and-adrs/        #   发布
│   ├── shipping-and-launch/           #   发布
│   └── using-agent-skills/            #   元：如何使用这个包
├── agents/                            # 3 个专家角色
├── references/                        # 4 个补充检查表
├── hooks/                             # 会话生命周期钩子
├── .claude/commands/                  # 7 个斜杠命令（Claude Code）
├── .gemini/commands/                  # 7 个斜杠命令（Gemini CLI）
└── docs/                              # 每个工具的设置指南
```

---

## 为什么选择 Agent Skills？

AI 编码代理默认为最短路径——这通常意味着跳过规格说明、测试、安全审查和使软件可靠的做法。Agent Skills 为代理提供结构化的工作流，强制执行高级工程师在生产代码中带来的相同纪律。

每个技能都编码了来之不易的工程判断：*何时*编写规格说明、*什么*要测试、*如何*审查以及*何时*发布。这些不是通用提示——它们是那种有见地的、流程驱动的工作流，将生产质量的工作与原型质量的工作区分开来。

技能嵌入了来自 Google 工程文化的最佳实践——包括来自 [Software Engineering at Google](https://abseil.io/resources/swe-book) 和 Google 的 [engineering practices guide](https://google.github.io/eng-practices/) 的概念。你会在 API 设计中找到 Hyrum 定律，在测试中找到 Beyoncé 规则和测试金字塔，在代码审查中找到变更大小和审查速度规范，在简化中找到切斯特顿的栅栏，在 git 工作流中找到基于主干的开发，在 CI/CD 中找到左移和功能标志，以及将代码视为负债的专用弃用技能。这些不是抽象的原则——它们直接嵌入到代理遵循的逐步工作流中。

---

## 贡献

技能应该**具体**（可操作的步骤，而不是模糊的建议）、**可验证**（带有证据要求的明确退出标准）、**经过实战测试**（基于真实工作流）和**精简**（仅需要引导代理的内容）。

有关格式规范，请参见 [docs/skill-anatomy.md](docs/skill-anatomy.md)，有关指南，请参见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 许可证

MIT - 在你的项目、团队和工具中使用这些技能。
