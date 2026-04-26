# ADR 0003 — PreToolUse hook for Rule #0 enforcement (not `permissions.deny`)

**Status:** Accepted
**Date:** 2026-04-26
**Deciders:** jota-batuta
**Supersedes:** none

## Context

Rule #0 (the main agent never edits source code directly — see [ADR 0001](0001-rule-zero-delegation-only-main.md)) needs runtime teeth. Documentary contracts erode under context pressure. The plugin needed a mechanism that physically prevents Write/Edit/MultiEdit/NotebookEdit calls from the main agent against paths outside a narrow whitelist, while leaving subagents free to operate inside their own tool-scope contracts.

Claude Code provides two surfaces that could host the enforcement:

- **`permissions.deny` in settings.json:** declarative deny rules with glob patterns. Native, low-overhead, well-documented.
- **PreToolUse hook:** programmatic shell script (or HTTP endpoint, or MCP tool) that fires on every matching tool call and decides allow/block via exit code or JSON.

Both surfaces are stable Claude Code primitives as of 1.x. The decision is which to use for Rule #0.

## Decision

**Use a PreToolUse hook (`hooks/delegation-guard.sh`).** The hook is registered plugin-level in `hooks/hooks.json` with matcher `Write|Edit|MultiEdit|NotebookEdit`. It reads stdin JSON to extract `agent_id`, `hook_event_name`, and `tool_input.file_path`, applies the whitelist/blocklist logic, and exits 0 (allow) or 2 (block with stderr message).

## Alternatives considered

### Alt 1 — `permissions.deny` for Write/Edit/MultiEdit globally with allow-list overrides
**Rejected.** Two blocking reasons:

- **No per-caller distinction.** `permissions.deny` applies to every tool call regardless of caller (main vs subagent). Rule #0 requires the *opposite* posture per caller: blocked for main, allowed for subagent. A global deny would block subagents too, which defeats the purpose — implementation must happen *somewhere*, just not in the main's window.
- **No agent_id context in permissions matching.** Permission rules match against tool name and tool input fields, not against the calling agent's identity. There is no way to express "deny if the caller is the main agent" in the permissions DSL as of Claude Code 1.x.

### Alt 2 — `permissions.deny` augmented with a separate `permissions.allow` per subagent
**Rejected.** Conceivably you could write `Write(specs/**)`, `Write(docs/**)` in `permissions.allow` and trust subagents to inherit. But subagents inherit the parent's permission set — they don't reset it. Adding allows for subagents implicitly broadens the main's surface unless you can scope by caller, which (per Alt 1) you cannot.

### Alt 3 — Skill-level enforcement (a skill the main has to invoke before editing)
**Rejected.** Skills are invoked at the main's discretion. A skill that says "before you edit, check the whitelist" is bypassable by simply not invoking it. The whole point of Rule #0 is to remove the agent's discretion on this question.

### Alt 4 — Project-level hook in `.claude/settings.json` instead of plugin-level
**Rejected as the primary surface.** Per-project hooks are a viable fallback for operators who don't want to install the plugin, but the plugin-level hook is the canonical placement because (a) it ships with the distribution, (b) it lives next to the agent definitions and docs that articulate the same contract, and (c) it can use `${CLAUDE_PLUGIN_ROOT}` for path portability across machines. The plugin's hook merges with any project-level hooks the operator adds; both can coexist.

## Consequences

### Positive

- The hook can distinguish main vs subagent via `agent_id` field in stdin JSON, which `permissions.deny` cannot.
- Plugin-level placement means the rule travels with the plugin install. Operators get enforcement for free when they enable the plugin.
- The hook produces actionable error messages (lists the four delegation alternatives, names the allowed paths) that help the main re-route on the next attempt.
- Kill-switch protection is straightforward: the hook adds `.claude/settings*.json`, `.claude/hooks/`, `.claude/agents/` to a separate blocklist that runs before the whitelist match. The hook cannot be disabled by the main editing one Edit away.
- Fail-soft on missing `jq` keeps the operator unblocked rather than locked out of their own configuration.

### Negative

- Latency: ~30-50ms per Write/Edit/MultiEdit/NotebookEdit call (one `bash` + one `jq` invocation). Acceptable for this surface — these calls are interactive operator-pace, not high-throughput.
- Bash + jq dependency: Windows operators need Git Bash and `jq` (winget install jqlang.jq). Documented in the hook's stderr message when `jq` is missing.
- The hook itself is a security-relevant component. It went through `code-reviewer` + `security-auditor` audit before merge (1 HIGH + 2 MEDIUM hardening recommendations applied: agent_id verification tightened with hook_event_name check, `.claude/` whitelist narrowed to exclude kill-switches, symlink caveat documented).

### Neutral

- The hook performs lexical path matching, not filesystem resolution. Symlink-traversal hardening (resolving paths through `realpath` before whitelist match) is a tracked backlog item; until then, the script header documents the residual lexical-only behavior so operators do not assume semantic equivalence.

## References

- [ADR 0001](0001-rule-zero-delegation-only-main.md) — Rule #0 motivation
- [`hooks/delegation-guard.sh`](../../hooks/delegation-guard.sh) — the script
- [`hooks/hooks.json`](../../hooks/hooks.json) — registration
- [Claude Code hooks reference](https://code.claude.com/docs/en/hooks) — official hook protocol
- [Claude Code permissions reference](https://code.claude.com/docs/en/permissions) — the rejected alternative surface
