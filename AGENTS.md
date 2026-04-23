# AGENTS.md

This repository is an OpenCode-first collection of reusable engineering skills, commands, and specialist agents for AI-assisted software development.

## Repository Overview

- `AGENTS.md` defines the default behavior for OpenCode sessions in this repository.
- `.opencode/skills/` contains reusable `SKILL.md` definitions that OpenCode discovers through its native `skill` tool.
- `.opencode/commands/` contains custom commands such as `/spec`, `/plan`, `/build`, `/review`, and `/ship`.
- `.opencode/agents/` contains specialist subagents for review, testing, and security work.
- `.opencode/references/` contains supporting checklists and patterns that skills can reference when needed.

## Core Rules

- Check whether a skill applies before acting.
- If a skill applies, load it with the `skill` tool and follow it.
- Prefer the smallest correct change that completes the task.
- Keep workflows explicit: define, plan, build, verify, review, ship.
- Do not invent repository structure or tool behavior when the codebase can answer the question.

## Intent To Skill Mapping

- Feature or new functionality -> `spec-driven-development`, then `incremental-implementation`, then `test-driven-development`
- Planning or task breakdown -> `planning-and-task-breakdown`
- Bug, failure, or unexpected behavior -> `debugging-and-error-recovery`
- Code review -> `code-review-and-quality`
- Refactoring or simplification -> `code-simplification`
- API or interface design -> `api-and-interface-design`
- UI work -> `frontend-ui-engineering`
- Shipping or rollout work -> `shipping-and-launch`

## Lifecycle Mapping

- DEFINE -> `spec-driven-development`
- PLAN -> `planning-and-task-breakdown`
- BUILD -> `incremental-implementation` plus `test-driven-development`
- VERIFY -> `debugging-and-error-recovery`
- REVIEW -> `code-review-and-quality`
- SHIP -> `shipping-and-launch`

## Commands

OpenCode custom commands live in `.opencode/commands/`.

- `/spec` starts definition work with the planning agent.
- `/plan` produces a read-only implementation plan.
- `/build` executes the next implementation slice.
- `/test` runs a TDD-oriented implementation flow.
- `/review` invokes the `code-reviewer` subagent.
- `/code-simplify` runs the simplification workflow.
- `/ship` runs the launch-readiness checklist.

## Skills

All native skills live in `.opencode/skills/<skill-name>/SKILL.md`.

- Keep the directory name and frontmatter `name` identical.
- Keep descriptions specific enough for automatic selection.
- Use supporting reference files sparingly and only when they add clear value.

## Agents

Specialist subagents live in `.opencode/agents/`.

- `code-reviewer` is read-only and focuses on quality review.
- `security-auditor` is read-only and focuses on security findings.
- `test-engineer` can edit files when test creation or remediation is needed.

## Contributing

When adding or updating repository assets:

- Add new reusable workflows as skills in `.opencode/skills/`.
- Add repetitive entrypoints as commands in `.opencode/commands/`.
- Add focused specialist behaviors as agents in `.opencode/agents/`.
- Keep OpenCode documentation and examples aligned with the actual repository layout.
