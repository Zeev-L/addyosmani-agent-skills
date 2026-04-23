# Getting Started

This repository is designed to work natively with OpenCode.

## Core Pieces

- `AGENTS.md` defines repository-wide instructions.
- `.opencode/commands/` defines reusable command entrypoints.
- `.opencode/skills/` contains reusable engineering workflows.
- `.opencode/agents/` contains focused specialist subagents.

## Typical Workflow

1. Use `/spec` to define a non-trivial change.
2. Use `/plan` to break the work into verifiable tasks.
3. Use `/build` or `/test` to implement incrementally.
4. Use `/review` before considering the work done.
5. Use `/ship` when preparing a release.

## How Skills Work

Each skill is a `SKILL.md` file under `.opencode/skills/<name>/`.

Skills are discovered by OpenCode and loaded through the native `skill` tool only when they are relevant. That keeps the active prompt smaller while preserving detailed workflows.

## How Agents Work

The specialist agents in `.opencode/agents/` are subagents that can be invoked directly by commands or by the primary agent.

- `code-reviewer` is optimized for read-only review work.
- `security-auditor` is optimized for read-only security review.
- `test-engineer` can edit files when test work needs to be carried through.

## References

Supporting checklists live in `.opencode/references/`. Skills should pull them in only when needed.

## Creating New Assets

- Add new reusable workflows under `.opencode/skills/`.
- Add repetitive entrypoints under `.opencode/commands/`.
- Add specialist subagents under `.opencode/agents/`.

Keep names short, specific, and aligned with the task they handle.
