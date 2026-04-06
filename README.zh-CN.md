# Agent Skills

[English](README.md) | [简体中文](README.zh-CN.md)

**面向 AI 编码代理的生产级工程技能。**

这些技能把资深工程师在构建软件时使用的工作流、质量门禁和最佳实践编码进去，并以可打包的形式提供给 AI 代理，让它们在开发的每个阶段都能一致地遵循这些流程。

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

有 7 个与开发生命周期一一对应的 slash 命令。每个命令都会自动激活合适的技能。

| 你正在做什么 | 命令 | 核心原则 |
|--------------|------|----------|
| 定义要构建什么 | `/spec` | 先写规格，再写代码 |
| 规划如何实现 | `/plan` | 拆成小而原子的任务 |
| 增量式构建 | `/build` | 一次只完成一个切片 |
| 证明它能工作 | `/test` | 测试就是证据 |
| 合并前做评审 | `/review` | 持续改善代码健康度 |
| 简化代码 | `/code-simplify` | 清晰胜过炫技 |
| 发布到生产环境 | `/ship` | 越快越安全 |

技能也会根据你正在做的事情自动激活 —— 比如设计 API 会触发 `api-and-interface-design`，构建 UI 会触发 `frontend-ui-engineering`，等等。

---

## 快速开始

<details>
<summary><b>Claude Code（推荐）</b></summary>

**通过 Marketplace 安装：**

```
/plugin marketplace add addyosmani/agent-skills
/plugin install agent-skills@addy-agent-skills
```

**本地 / 开发模式：**

```bash
git clone https://github.com/addyosmani/agent-skills.git
claude --plugin-dir /path/to/agent-skills
```

</details>

<details>
<summary><b>Cursor</b></summary>

把任意 `SKILL.md` 复制到 `.cursor/rules/`，或者直接引用完整的 `skills/` 目录。详见 [docs/cursor-setup.md](docs/cursor-setup.md)。

</details>

<details>
<summary><b>Gemini CLI</b></summary>

可以安装为原生技能以启用自动发现，也可以加入 `GEMINI.md` 作为持久上下文。详见 [docs/gemini-cli-setup.md](docs/gemini-cli-setup.md)。

```bash
gemini skills install https://github.com/addyosmani/agent-skills.git
```

</details>

<details>
<summary><b>Windsurf</b></summary>

把技能内容加入 Windsurf 的 rules 配置。详见 [docs/windsurf-setup.md](docs/windsurf-setup.md)。

</details>

<details>
<summary><b>GitHub Copilot</b></summary>

把 `agents/` 中的 agent 定义作为 Copilot persona，把技能内容放进 `.github/copilot-instructions.md`。详见 [docs/copilot-setup.md](docs/copilot-setup.md)。

</details>

<details>
<summary><b>Codex / 其他代理</b></summary>

技能本质上就是普通 Markdown —— 任何接受 system prompt 或 instruction file 的代理都能使用。详见 [docs/getting-started.md](docs/getting-started.md)。

</details>

---

## 全部 19 个技能

上面的命令是入口。底层会激活这 19 个技能 —— 每个技能都是一个结构化工作流，包含步骤、验证门禁和反自我合理化表。你也可以直接引用任意技能。

### Define - 明确要构建什么

| Skill | 作用 | 适用场景 |
|-------|------|----------|
| [idea-refine](skills/idea-refine/SKILL.md) | 通过结构化的发散/收敛思考，把模糊想法变成具体方案 | 你有一个粗略概念，需要先探索清楚 |
| [spec-driven-development](skills/spec-driven-development/SKILL.md) | 在写任何代码之前，先写一份包含目标、命令、结构、代码风格、测试和边界的 PRD | 开始一个新项目、新功能或重大改动 |

### Plan - 拆解实现路径

| Skill | 作用 | 适用场景 |
|-------|------|----------|
| [planning-and-task-breakdown](skills/planning-and-task-breakdown/SKILL.md) | 把规格拆成带验收标准和依赖顺序的小任务 | 已经有 spec，需要拆成可执行单元 |

### Build - 编写代码

| Skill | 作用 | 适用场景 |
|-------|------|----------|
| [incremental-implementation](skills/incremental-implementation/SKILL.md) | 薄切片式开发 —— 实现、测试、验证、提交。强调 feature flag、安全默认值和可回滚改动 | 任何会改动多个文件的任务 |
| [test-driven-development](skills/test-driven-development/SKILL.md) | Red-Green-Refactor、测试金字塔（80/15/5）、测试粒度、DAMP 优于 DRY、Beyonce Rule、浏览器测试 | 实现逻辑、修 bug 或修改行为时 |
| [context-engineering](skills/context-engineering/SKILL.md) | 在合适的时间给代理喂入合适的信息 —— rules 文件、上下文打包、MCP 集成 | 开始新会话、切换任务，或输出质量下降时 |
| [frontend-ui-engineering](skills/frontend-ui-engineering/SKILL.md) | 组件架构、设计系统、状态管理、响应式设计、WCAG 2.1 AA 无障碍 | 构建或修改面向用户的界面 |
| [api-and-interface-design](skills/api-and-interface-design/SKILL.md) | 契约优先设计、Hyrum's Law、One-Version Rule、错误语义、边界校验 | 设计 API、模块边界或公共接口时 |

### Verify - 证明它可用

| Skill | 作用 | 适用场景 |
|-------|------|----------|
| [browser-testing-with-devtools](skills/browser-testing-with-devtools/SKILL.md) | 使用 Chrome DevTools MCP 获取实时运行数据 —— DOM 检查、控制台日志、网络请求、性能分析 | 构建或调试任何浏览器中运行的内容 |
| [debugging-and-error-recovery](skills/debugging-and-error-recovery/SKILL.md) | 五步排障：复现、定位、缩小范围、修复、加护栏。包含 stop-the-line 规则和安全回退策略 | 测试失败、构建报错或行为异常时 |

### Review - 合并前的质量门禁

| Skill | 作用 | 适用场景 |
|-------|------|----------|
| [code-review-and-quality](skills/code-review-and-quality/SKILL.md) | 五维代码评审、变更规模控制（约 100 行）、严重级别标签（Nit/Optional/FYI）、评审速度规范、拆分策略 | 合并任何改动之前 |
| [code-simplification](skills/code-simplification/SKILL.md) | Chesterton's Fence、Rule of 500，在保持行为完全不变的前提下降低复杂度 | 代码虽然能跑，但太难读或太难维护 |
| [security-and-hardening](skills/security-and-hardening/SKILL.md) | OWASP Top 10 防护、认证模式、密钥管理、依赖审计、三级边界系统 | 处理用户输入、认证、数据存储或外部集成时 |
| [performance-optimization](skills/performance-optimization/SKILL.md) | 先测量再优化 —— Core Web Vitals 目标、性能分析工作流、包体积分析、反模式检测 | 有性能要求，或怀疑存在性能回退时 |

### Ship - 有把握地上线

| Skill | 作用 | 适用场景 |
|-------|------|----------|
| [git-workflow-and-versioning](skills/git-workflow-and-versioning/SKILL.md) | Trunk-based development、原子提交、变更规模控制（约 100 行）、commit-as-save-point 模式 | 任何代码改动（始终适用） |
| [ci-cd-and-automation](skills/ci-cd-and-automation/SKILL.md) | Shift Left、更快更安全、feature flag、质量门禁流水线、失败反馈回路 | 搭建或修改构建/部署流水线时 |
| [deprecation-and-migration](skills/deprecation-and-migration/SKILL.md) | 把代码视为负债、区分强制/建议性弃用、迁移模式、清理僵尸代码 | 移除旧系统、迁移用户或下线功能时 |
| [documentation-and-adrs](skills/documentation-and-adrs/SKILL.md) | 架构决策记录（ADR）、API 文档、内联文档规范 —— 记录“为什么” | 做架构决策、修改 API 或发布功能时 |
| [shipping-and-launch](skills/shipping-and-launch/SKILL.md) | 上线前检查清单、feature flag 生命周期、分阶段发布、回滚流程、监控配置 | 准备发布到生产环境时 |

---

## Agent Personas

为针对性评审预配置的专家 persona：

| Agent | 角色 | 视角 |
|-------|------|------|
| [code-reviewer](agents/code-reviewer.md) | Senior Staff Engineer | 五维代码评审，以“资深工程师会不会批准”为标准 |
| [test-engineer](agents/test-engineer.md) | QA Specialist | 测试策略、覆盖率分析和 Prove-It 模式 |
| [security-auditor](agents/security-auditor.md) | Security Engineer | 漏洞检测、威胁建模、OWASP 评估 |

---

## 参考清单

技能在需要时会按需加载这些速查资料：

| Reference | 覆盖内容 |
|-----------|----------|
| [testing-patterns.md](references/testing-patterns.md) | 测试结构、命名、mock、React/API/E2E 示例、反模式 |
| [security-checklist.md](references/security-checklist.md) | 提交前检查、认证、输入校验、响应头、CORS、OWASP Top 10 |
| [performance-checklist.md](references/performance-checklist.md) | Core Web Vitals 目标、前后端检查项、测量命令 |
| [accessibility-checklist.md](references/accessibility-checklist.md) | 键盘导航、屏幕阅读器、视觉设计、ARIA、测试工具 |

---

## 技能如何工作

每个技能都遵循一致的结构：

```
┌─────────────────────────────────────────────┐
│  SKILL.md                                   │
│                                             │
│  ┌─ Frontmatter ─────────────────────────┐  │
│  │ name: lowercase-hyphen-name           │  │
│  │ description: Use when [trigger]       │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  Overview         → What this skill does    │
│  When to Use      → Triggering conditions   │
│  Process          → Step-by-step workflow   │
│  Rationalizations → Excuses + rebuttals     │
│  Red Flags        → Signs something's wrong │
│  Verification     → Evidence requirements   │
└─────────────────────────────────────────────┘
```

**关键设计选择：**

- **强调流程，不是散文。** 技能是代理要遵循的工作流，而不是只读参考文档。每个技能都有步骤、检查点和退出条件。
- **反自我合理化。** 每个技能都包含一张表，列出代理常用来跳过步骤的借口（比如“测试以后再补”）以及对应反驳。
- **验证不可妥协。** 每个技能最后都要求证据 —— 测试通过、构建输出、运行时数据。仅仅“看起来对”永远不够。
- **渐进式披露。** `SKILL.md` 是入口，支持性参考资料只在需要时加载，从而尽量节省 token。

---

## 项目结构

```
agent-skills/
├── skills/                            # 19 个核心技能（每个目录一个 SKILL.md）
│   ├── idea-refine/                   #   Define
│   ├── spec-driven-development/       #   Define
│   ├── planning-and-task-breakdown/   #   Plan
│   ├── incremental-implementation/    #   Build
│   ├── context-engineering/           #   Build
│   ├── frontend-ui-engineering/       #   Build
│   ├── test-driven-development/       #   Build
│   ├── api-and-interface-design/      #   Build
│   ├── browser-testing-with-devtools/ #   Verify
│   ├── debugging-and-error-recovery/  #   Verify
│   ├── code-review-and-quality/       #   Review
│   ├── code-simplification/           #   Review
│   ├── security-and-hardening/        #   Review
│   ├── performance-optimization/      #   Review
│   ├── git-workflow-and-versioning/   #   Ship
│   ├── ci-cd-and-automation/          #   Ship
│   ├── deprecation-and-migration/     #   Ship
│   ├── documentation-and-adrs/        #   Ship
│   ├── shipping-and-launch/           #   Ship
│   └── using-agent-skills/            #   Meta：如何使用这个技能包
├── agents/                            # 3 个专家 persona
├── references/                        # 4 份补充清单
├── hooks/                             # 会话生命周期 hooks
├── .claude/commands/                  # 7 个 slash 命令
└── docs/                              # 面向不同工具的接入指南
```

---

## 为什么是 Agent Skills？

AI 编码代理默认会选择最短路径 —— 而这通常意味着跳过 spec、测试、安全审查，以及那些让软件真正可靠的工程实践。Agent Skills 为代理提供结构化工作流，让它们像资深工程师一样，对生产级代码保持同样的纪律性。

每个技能都编码了来之不易的工程判断：*什么时候*该写 spec，*什么*必须测试，*如何*做评审，以及*什么时候*可以发布。这些不是泛泛而谈的提示词，而是把重流程、强约束的实践直接嵌入到代理执行步骤里的工作流，用来区分“可上生产”的成果和“只是原型”的成果。

这些技能也吸收了 Google 工程文化中的最佳实践，包括 [Software Engineering at Google](https://abseil.io/resources/swe-book) 和 Google 的 [engineering practices guide](https://google.github.io/eng-practices/) 里的概念。你会在 API 设计里看到 Hyrum's Law，在测试中看到 Beyonce Rule 和测试金字塔，在代码评审中看到变更规模控制和评审速度规范，在简化代码时看到 Chesterton's Fence，在 Git 工作流里看到 trunk-based development，在 CI/CD 中看到 Shift Left 和 feature flag，以及一个专门把代码视为负债的 deprecation 技能。这些不是抽象原则 —— 它们被直接写进了代理要执行的逐步工作流里。

---

## 贡献

技能应当具备以下特点：**具体**（有可执行步骤，而不是模糊建议）、**可验证**（退出条件明确，证据要求清晰）、**经得起实战**（来源于真实工作流，而不是理论理想）、以及 **最小化**（只保留正确引导代理所需的内容）。

格式规范见 [docs/skill-anatomy.md](docs/skill-anatomy.md)，贡献指南见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 许可证

MIT —— 你可以在自己的项目、团队和工具中使用这些技能。
