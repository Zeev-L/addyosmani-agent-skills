# Agent Skills

Production-grade engineering skills for OpenCode.

This repository packages reusable workflows, specialist agents, and custom commands so OpenCode sessions follow a more disciplined software-development lifecycle.

## Acknowledgments

This repository is a fork of [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills).

The original project is primarily aimed at Claude Code. This fork adapts the idea, structure, and workflows for native OpenCode usage.

```text
DEFINE          PLAN           BUILD          VERIFY         REVIEW          SHIP
Idea/Spec   ->  Plan      ->   Implement  ->  Debug/Test -> Review QA  ->  Launch
 /spec          /plan          /build         /test         /review       /ship
```

## OpenCode Quick Start

1. Clone the repository.
2. Open it in OpenCode.
3. Use the native project assets already included here:
   - `AGENTS.md`
   - `.opencode/commands/`
   - `.opencode/skills/`
   - `.opencode/agents/`
4. Run commands like `/spec`, `/plan`, `/build`, `/review`, and `/ship`, or let the agent load skills automatically via the native `skill` tool.

See [docs/opencode-setup.md](docs/opencode-setup.md).

## Repository Layout

```text
agent-skills/
├── .opencode/
│   ├── commands/     # OpenCode custom commands
│   ├── skills/       # Native OpenCode skills
│   ├── agents/       # Specialist subagents
│   ├── plugins/      # Optional OpenCode plugins
│   └── references/   # Supporting checklists and patterns
├── AGENTS.md         # Project instructions for OpenCode
├── docs/             # Setup and reference docs
├── bootstrap/        # Import scripts for existing repositories
└── CONTRIBUTING.md
```

## Commands

| Task | Command | Purpose |
|------|---------|---------|
| Define what to build | `/spec` | Create a structured specification before implementation |
| Break work down | `/plan` | Produce a read-only plan with verifiable tasks |
| Implement incrementally | `/build` | Execute the next vertical slice |
| Prove behavior with tests | `/test` | Follow a TDD workflow for features or bug fixes |
| Review changes | `/review` | Run a structured five-axis review via the review agent |
| Simplify working code | `/code-simplify` | Reduce complexity without changing behavior |
| Prepare for release | `/ship` | Run launch-readiness checks and rollout planning |

## Skills

The repository ships with 21 reusable skills under `.opencode/skills/`.

### Define

- [idea-refine](.opencode/skills/idea-refine/SKILL.md)
- [spec-driven-development](.opencode/skills/spec-driven-development/SKILL.md)

### Plan

- [planning-and-task-breakdown](.opencode/skills/planning-and-task-breakdown/SKILL.md)

### Build

- [incremental-implementation](.opencode/skills/incremental-implementation/SKILL.md)
- [test-driven-development](.opencode/skills/test-driven-development/SKILL.md)
- [context-engineering](.opencode/skills/context-engineering/SKILL.md)
- [source-driven-development](.opencode/skills/source-driven-development/SKILL.md)
- [frontend-ui-engineering](.opencode/skills/frontend-ui-engineering/SKILL.md)
- [api-and-interface-design](.opencode/skills/api-and-interface-design/SKILL.md)

### Verify

- [browser-testing-with-devtools](.opencode/skills/browser-testing-with-devtools/SKILL.md)
- [debugging-and-error-recovery](.opencode/skills/debugging-and-error-recovery/SKILL.md)

### Review

- [code-review-and-quality](.opencode/skills/code-review-and-quality/SKILL.md)
- [code-simplification](.opencode/skills/code-simplification/SKILL.md)
- [security-and-hardening](.opencode/skills/security-and-hardening/SKILL.md)
- [performance-optimization](.opencode/skills/performance-optimization/SKILL.md)

### Ship

- [git-workflow-and-versioning](.opencode/skills/git-workflow-and-versioning/SKILL.md)
- [ci-cd-and-automation](.opencode/skills/ci-cd-and-automation/SKILL.md)
- [deprecation-and-migration](.opencode/skills/deprecation-and-migration/SKILL.md)
- [documentation-and-adrs](.opencode/skills/documentation-and-adrs/SKILL.md)
- [shipping-and-launch](.opencode/skills/shipping-and-launch/SKILL.md)

## Specialist Agents

- [code-reviewer](.opencode/agents/code-reviewer.md)
- [test-engineer](.opencode/agents/test-engineer.md)
- [security-auditor](.opencode/agents/security-auditor.md)

## References

- [testing-patterns.md](.opencode/references/testing-patterns.md)
- [security-checklist.md](.opencode/references/security-checklist.md)
- [performance-checklist.md](.opencode/references/performance-checklist.md)
- [accessibility-checklist.md](.opencode/references/accessibility-checklist.md)

## Bootstrap Existing Repositories

To import these shared OpenCode assets into an existing repository, use one of the bootstrap scripts in `bootstrap/`.

Unix:

```bash
curl -fsSL <raw-script-url> -o install-opencode-assets.sh
sh install-opencode-assets.sh https://github.com/OWNER/REPO [ref]
```

Windows PowerShell:

```powershell
Invoke-WebRequest <raw-script-url> -OutFile install-opencode-assets.ps1
.\install-opencode-assets.ps1 -RepoUrl https://github.com/OWNER/REPO [-Ref <ref>]
```

Both scripts install the shared assets into the current repository and write `.opencode-vendor.json` so the source and version can be tracked.

## Why This Repository Exists

AI coding agents tend to optimize for the shortest path. These skills push them toward the safer path: explicit specs, smaller increments, test-backed changes, structured review, and deliberate launches.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/getting-started.md](docs/getting-started.md).
