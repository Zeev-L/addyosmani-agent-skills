# Add `autonomous-code-improvement` skill

## What this adds

A new Markdown-only skill at `skills/autonomous-code-improvement/SKILL.md` that documents the discipline for running an unattended code-improvement loop — scan, isolate, execute, multi-persona self-review, adversarial gate, domain guard, PR — with cost ceilings throughout.

No code, no executables, no tests in this PR. The skill is a pure prescription that fits the existing skill anatomy (Overview / When to Use / Process / Common Rationalizations / Red Flags / Verification).

## Why it belongs here

Autonomous coding agents are now common (Cursor's background agents, Copilot Workspace, Devin, etc.) but their failure modes are consistent and well-understood:

1. They guess when they hit domain-specific code rather than asking
2. They have no cost controls — a runaway loop is a $200 surprise
3. They let the writing model approve its own work — the writer's review is theater

The existing skills in this repo address how a *human-in-the-loop* agent should work (TDD, incremental implementation, code review, debugging). This skill addresses what changes when the human is no longer in the loop on every diff. It complements rather than overlaps:

- It cites and depends on `code-review-and-quality`, `security-and-hardening`, and `test-driven-development` (the three persona prompts pull from those)
- It cites `git-workflow-and-versioning` for worktree isolation
- It introduces concepts that don't appear elsewhere: domain-question markers, adversarial gates, cost checkpoints

## What it doesn't do

- **No new package, no executable code.** This PR is one Markdown file, matching every other skill in the repo.
- **No changes to top-level README.md, plugin.json, or any existing skill.** The skill plugs in by file presence alone — the discovery model already supports new skills via the standard convention.
- **No build/test infrastructure added to the repo.** The reference implementation lives in a separate repo (linked in the SKILL).

## Reference implementation

A working four-package TypeScript monorepo that implements every node of the pipeline ships separately as `asil-monorepo` (Autonomous Software Improvement Loop). 278 vitest tests, MIT-licensed, extracted from a production system in use today on an 80+ agent travel AI platform. Linked from the bottom of the SKILL.

This PR doesn't depend on the reference repo existing — the skill stands on its own as a process description. The link is for readers who want a turnkey starting point.

## Scope check

Per `CLAUDE.md`'s conventions:

- ✅ Skill lives at `skills/autonomous-code-improvement/SKILL.md`
- ✅ YAML frontmatter with `name` and `description`
- ✅ Description starts with what the skill does, then "Use when…"
- ✅ Sections: Overview, When to Use, Process, Common Rationalizations, Red Flags, Verification
- ✅ No supporting files (content fits in one SKILL.md, well under the 100-line threshold for splitting)
- ✅ No duplication with existing skills — references them instead

## Credit

Skill authored by Dušan Milicevic ([Telivity](https://telivity.com)) — extracted from a production autonomous system that has been running unattended for months and opening PRs daily.
