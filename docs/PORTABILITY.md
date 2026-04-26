# PORTABILITY — switching tools mid-feature

**Audience:** an operator who is running this project in Claude Code and needs to continue work in another AI coding tool (Cursor, Codex CLI, Aider, Gemini CLI, Windsurf, OpenCode, etc.) — typically because Claude Code hit a token budget, or for pair programming, or to use a tool's specific strengths.

This file is honest about what survives the switch and what does not.

## What survives 100% (plain Markdown, ports everywhere)

The doc graph is pure Markdown and loads into any tool that reads project files:

- `docs/PRD.md` — vision, problem, success metrics
- `docs/SPEC.md` — architecture overview
- `docs/DELEGATION-RULE.md` and `docs/DELEGATION-RULE-SPECIALISTS.md` — the contract and the calibration table
- `docs/adr/` — decision records
- `docs/plans/active/<file>.md` — the in-flight plan
- `docs/plans/archive/` — historical plans
- `docs/sessions/<file>.md` — session journals (the most recent one's `Next:` line is the entry point)
- `CLAUDE.md` and `AGENTS.md` — conventions (CLAUDE.md preferred by Claude Code, AGENTS.md preferred by Codex CLI / Cursor / Aider / Gemini / OpenCode / Windsurf as fallback)
- `git log` — the actual recent activity, which contradicts stale docs when present
- The agent definitions in `agents/*.md` — readable as static context describing what each role would do

## What does NOT port (Claude Code-specific runtime)

- **PreToolUse hook** (`hooks/delegation-guard.sh`). No equivalent in Cursor, Aider, Codex CLI, Gemini CLI, Windsurf, or OpenCode as of Claude Code 1.x. The main agent in those tools can edit any file the operator's own permissions allow.
- **`Task` subagent delegation** (with verdict-returning agents). Cursor has Custom Modes, Aider has architect/editor mode, but neither matches the Claude Code chain semantics where the audit chain runs sequentially and the main reads each agent's `AUDIT RESULT` literal before proceeding.
- **`agent-architect` runtime specialist creation.** The meta-agent works because Claude Code can spawn subagents. In other tools, the operator manually drafts `<project>/.claude/agents/<name>.md` (or the tool's equivalent) and reads it as static context.
- **Slash commands `.claude/commands/`** — Claude Code-only.
- **Plugin-level marketplace install** — Claude Code-only.

## Cross-session entry sequence (any tool)

When you open a session in any tool — Claude Code or otherwise — read in this order before doing anything:

1. `docs/PRD.md` (project vision)
2. `CLAUDE.md` and/or `AGENTS.md` (conventions)
3. `docs/plans/active/*.md` (one file expected — the in-flight plan)
4. `docs/sessions/*.md` (most recent — its `Next:` line is your entry point)
5. `git log --oneline -10` (the actual ground truth when docs lag)

## How to self-enforce Rule #0 without the hook

In a tool without PreToolUse hooks, you (the operator) become the enforcement layer. The discipline:

1. **Treat the main agent's response as a draft, not a commit.** Before allowing edits to source code, ask: would the audit chain approve this?
2. **Run the chain manually.** After the agent produces an implementation:
   - Manually invoke a "test review" pass: load `agents/test-engineer.md` as static context, ask the agent to run the test-engineer workflow, expect an `AUDIT RESULT` line.
   - Repeat with `agents/code-reviewer.md` (GATE 2) and `agents/security-auditor.md` (GATE 3).
   - Do not commit until all three return APPROVED.
3. **Log the verdict.** Write the audit results into `docs/sessions/<today>.md` `Decisions:` section so the next session has the same evidence the audit-chain would have produced.
4. **Stay within the whitelist by hand.** When asked to edit something outside `specs/`, `docs/`, `.claude/`, `CLAUDE.md`, etc., pause: would the hook have blocked this? If yes, either reframe the task (delegate to a sub-conversation or file) or accept that you are operating outside Rule #0 and document why in the session journal.

This is slower and weaker than the runtime enforcement in Claude Code. The doc graph is what makes the switch survivable: by reading the same artifacts, the alternative tool can produce the same shape of output, even without the runtime guard.

**Secrets warning.** Cross-tool config files (`AGENTS.md`, `.aider.conf.yml`, `.cursor/rules/`, `GEMINI.md`, `.windsurfrules`) are committed to the repo by default. Do NOT paste API keys, tokens, or environment-variable values into any of them. The `read:` directives should reference files like `docs/PRD.md` and `docs/SPEC.md`, not `.env` or `secrets.yaml`.

## Tool-specific notes

- **Codex CLI:** reads `AGENTS.md` natively. Place `read: docs/PRD.md, docs/SPEC.md, docs/plans/active/*` in your config or paste the content at session start.
- **Cursor:** reads `AGENTS.md` as a complement to `.cursor/rules/`. The Custom Modes feature can approximate per-agent personas but does not return verdicts to a parent agent.
- **Aider:** add `read: [AGENTS.md, docs/SPEC.md, docs/plans/active/]` to `.aider.conf.yml`. The architect/editor split is a weak two-step substitute for the audit chain.
- **Gemini CLI:** reads `GEMINI.md` natively. `AGENTS.md` is supplementary — point Gemini at it via include/read directives in `GEMINI.md` to pick up the cross-tool conventions.
- **OpenCode:** see [`opencode-setup.md`](opencode-setup.md). Skill auto-routing works; the audit chain does not.
- **Windsurf:** alias for `AGENTS.md` via `.windsurfrules`. Same approach as Cursor.

## When to switch back to Claude Code

If you are doing security-sensitive work, regulated-domain work (Colombian e-invoicing, GDPR, PCI), or anything where the audit chain's sequential blocking matters more than tool-feature parity, **finish in Claude Code**. The runtime enforcement is the differentiator. Other tools are useful for prototyping, brainstorming, large-context reading, or unblocking when the budget runs out — not for shipping.

## Roundtrip protocol (Claude Code → other tool → Claude Code)

If you go round-trip:

1. Before leaving Claude Code: write a session journal entry with `Next:` pointing at the active plan and the next task.
2. Operate in the other tool, treat its work as a draft, write your own session journal entry there with `Next:` pointing back at the next Claude Code task.
3. Returning to Claude Code: read both journal entries, reconcile, and proceed. The hook will catch any out-of-whitelist edits the other tool made; you may need to revert or move them into the right paths.
