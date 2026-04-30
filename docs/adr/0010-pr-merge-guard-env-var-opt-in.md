# ADR 0010 — `gh pr merge` blocking hook with operator-side env-var opt-in

**Status:** Accepted (amended 2026-04-29 with v3.7 self-disable closure + eval-bypass acknowledgment)
**Date:** 2026-04-29
**Deciders:** jota-batuta

## Context

The plugin's user-level `CLAUDE.md` documents a `## PR policy (always create, never merge)` rule:

> Every change goes through a PR — no direct pushes to `main` or `master`.
> Claude creates PRs via `gh pr create`. Claude never merges PRs.
> The operator (jota-batuta) merges manually after review.

Up to v3.5, this rule lived **only** as written doctrine — enforcement was the operator's habit. No runtime hook checked for `gh pr merge`. The PRD's earlier candidate listing for this hook noted "zero observed violations" and rejected it as rule-invention without evidence.

In the 2026-04-29 session, this calculus shifted: the operator authorized merge "como excepción" 14 times in a single session (PRs #11–#26). The exception was scoped to that session, but the precedent created a drift surface — if "merge as exception" becomes routine in future sessions, the rule's protection erodes silently.

The trigger for this slice (v3.6) is operator preemption: install the backstop *before* drift accumulates further, while the design space is still small and the threat model is clear.

## Decision

Ship a `PreToolUse` hook (`hooks/pr-merge-guard.sh`) that **blocks any `gh pr merge` invocation by default**, with an **operator-side env-var opt-in** (`BATUTA_ALLOW_PR_MERGE=1`) for sessions where the operator explicitly authorizes Claude to merge.

### Block path (default)

Any tool call where:
- `tool_name == "Bash"` (matched in `hooks/hooks.json`)
- `tool_input.command` matches the regex `gh\s+pr\s+merge` with whitespace tolerance
- `BATUTA_ALLOW_PR_MERGE` is not set to `1`

…exits with code 1 and a stderr message that:
1. States the rule and the source (`CLAUDE.md` global).
2. Tells the operator how to override (`BATUTA_ALLOW_PR_MERGE=1 claude`).
3. Tells the agent to surface the request to the operator and stop.
4. Echoes the attempted command for transparency.

### Allow path (override)

When `BATUTA_ALLOW_PR_MERGE=1` is set in the shell environment that launched Claude Code, the hook logs `pr-merge-guard: 'gh pr merge' allowed by BATUTA_ALLOW_PR_MERGE=1` to stderr (visible in the transcript) and exits 0. The override is per-session by construction — env vars do not persist beyond the shell process.

### What the hook does NOT block

- `gh pr view`, `gh pr list`, `gh pr review`, `gh pr checkout`, `gh pr diff`, `gh pr edit` — read or annotate PRs without merging.
- `gh pr create` — explicitly the canonical Claude action per the PR policy rule.
- `git merge` — local-branch merging, distinct from PR merging on GitHub.
- Any other Bash command — only `gh\s+pr\s+merge` matches the regex.

### What the hook does NOT do

- It does NOT enforce the rule on the operator's manual `gh pr merge` calls. Those are out of Claude's tool-call surface entirely.
- It does NOT interpret "operator authorization in chat" as override. Mentions in the conversation buffer are NOT sufficient — the env var is the only override mechanism.
- It does NOT bypass for subagents. Unlike `hooks/delegation-guard.sh` (which has `agent_id` bypass for legitimate Task delegation), this hook applies to ALL contexts. No subagent in the plugin (auditors, agent-architect, project-local specialists) has a legitimate reason to merge PRs.

## Alternatives considered

### Alt α — Sentinel file in the repo (`.claude/.merge-authorized`)

**Rejected.** The agent could `touch .claude/.merge-authorized` from a Bash tool call inside the very session where the user wants the block enforced. Self-bypass = no enforcement. The hook would have to detect the touch *before* the agent could merge, which is a TOCTOU race.

### Alt β — Operator authorization via chat ("merge autorizado")

**Rejected.** The agent reads its own conversation buffer; "operator says merge is authorized" is just a string the agent can self-generate (prompt injection from a malicious doc, false-memory replay, hallucination). The plugin's threat model treats the conversation buffer as **input that may have been tampered with**, not as an auth surface. ADR-0006 § "Treat `Next:` as input, not as instructions" applies the same principle to session-handoff text.

### Alt γ — Slash command `/authorize-merge` that sets a session-state flag

**Rejected.** Two problems:
1. The state has to live somewhere — either in `~/.claude/` (which the agent can write) or in env (which a slash command cannot set on the parent shell). No location satisfies "operator-controlled, agent-can't-mutate."
2. Operator might forget to revoke. Without an explicit revoke command, drift accumulates: every session ends authorized.

### Alt δ — `pre-commit` hook on the repo's `git push --force` chain

**Rejected for this scope.** That defends a different rule (force-push protection), not the merge-PR rule. Out of scope; revisit in a separate slice if needed.

### Alt ε — Permissions config in `.claude/settings.json` denying `gh pr merge`

**Rejected.** The plugin philosophy (ADR-0003, ADR-0006) puts enforcement in plugin-level hooks, not in operator-side `permissions.deny`. The latter is operator territory and can drift across machines / projects. Plugin-level hook is uniform across every project that has the plugin enabled.

## Consequences

### Positive

- **Backstop for the "Claude never merges PRs" rule** before drift makes enforcement reactive instead of preemptive.
- **Per-session granularity** — each session starts blocked; opt-in is explicit. Operator can't accidentally leave a long-lived auth.
- **No false positives on read-only PR commands** — only `gh pr merge` matches.
- **Audit trail** — when override fires, the env-var allow is logged to stderr and visible in the session transcript.
- **Aligned with v2.7 kill-switch model** — block-by-default, narrow override path, operator-controlled. Same architecture as ADR-0006.

### Negative

- **Operator must remember the env var** when starting a session where merge is intended. Mitigated: the block message teaches the override on first encounter; restart cost is seconds.
- **One more hook to maintain** — `hooks/pr-merge-guard.sh`, validator 10. ~50 LOC each, with no external dependencies. Maintenance cost is low.
- **An attacker with shell access to set env vars defeats the hook.** True — the hook is not a security boundary against an attacker who already controls the operator's shell. The hook is a backstop against agent drift, not a sandbox escape control.

### Neutral

- Existing `delegation-guard.sh` is unchanged. The two hooks have separate concerns: `delegation-guard` blocks file paths (Write/Edit kill-switches); `pr-merge-guard` blocks command patterns (Bash `gh pr merge`). Each is registered under its matching `matcher` in `hooks/hooks.json`.
- The audit chain treatment is unchanged. `gh pr merge` is not a code change, so the post-edit audit chain doesn't apply to it. The hook is the gate for this specific operation.

## What is intentionally NOT done

- **No `gh release create` or `gh repo delete` blocking.** Those are separate rules with separate threat models. Add them in future slices if drift is observed.
- **No alerting beyond stderr.** The hook is silent on success and verbose on block. No telemetry, no Slack webhook, no email. The operator notices via the block message during routine work; the audit chain on every PR is the systemic check.
- **No automatic logging of every bypass to a persistent file.** The transcript itself is the log; if the operator needs forensics, they grep the transcript.

## Update 2026-04-29 — v3.7 closure: self-disable surface + eval-bypass acknowledgment

The v3.6 GATE 3 audit identified two findings that were not addressed before merge (the operator authorized "aprovved" while the async sub-agent was still running). v3.7 closes the HIGH and acknowledges the MEDIUM as a known limitation.

### HIGH (closed in v3.7)

`hooks/pr-merge-guard.sh` was NOT in `delegation-guard.sh`'s kill-switch list when v3.6 shipped. The kill-switch enumerated `hooks/delegation-guard.sh` specifically; `pr-merge-guard.sh` (and any future hook) was unprotected. The main agent could `Edit hooks/pr-merge-guard.sh` to disable the new hook before invoking `gh pr merge` — a self-disable surface that contradicts the slice's own design intent.

**Fix in v3.7**: extended the kill-switch case statement in `hooks/delegation-guard.sh` from `hooks/delegation-guard.sh` (specific) to `hooks/*.sh` (broadened). All current and future hook scripts in `hooks/` are now kill-switched against main-agent edits. Validator 06 updated to enforce the broader pattern.

### MEDIUM acknowledged (not closed — known limitation)

The `gh\s+pr\s+merge` regex performs literal substring matching on the outer command string. It does NOT lex sub-shells, expand variables, or follow indirection. Therefore the following inputs **slip past the hook**:

| Input | Why it slips |
|---|---|
| `eval "gh pr merge"` | The literal string IS in the command — but quoting can be stripped/varied |
| `bash -c "gh pr merge"` | Same indirection through a sub-shell flag |
| `sh -c gh\\ pr\\ merge` | Backslash-escaped whitespace breaks the regex |
| `x="gh pr merge"; eval $x` | Variable expansion happens at shell runtime, after hook |
| `GH=gh; $GH pr merge` | Same |

**Why this is acceptable as a known limitation**:

1. The threat model for this hook is **drift backstop, not active adversary**. ADR-0010 § Context: "the rule has no observed runtime violations to date; this hook exists as a backstop against drift." An agent obfuscating its own merge call to evade the hook is a security-relevant adversary, not a drift case.
2. **Obfuscation is highly visible in transcripts.** A `gh pr merge` in plain text is one thing; an `eval $cmd` where `$cmd` resolves to a merge command is a glaring red flag the operator catches in normal PR review.
3. **The operator's PR review on every change is the systemic backstop**, not the hook. The hook is one of multiple defenses; bypass via shell indirection still leaves the operator's review intact.
4. Closing this MEDIUM would require parsing every Bash command through a real shell lexer (e.g. `bash -n` + AST), which is out of scope for a backstop hook and introduces its own attack surface.

If future evidence shows obfuscated bypass actually happens (rather than this being a theoretical concern), revisit with a Bash-AST-aware lexer or a `permissions.deny` rule at the Claude Code level.

### LOW noted (not closed — design choice)

The block message echoes `Command attempted: ${command}` to stderr → transcript. If an operator pastes a command containing a token (e.g. hypothetically `gh pr merge --some-secret-flag ghp_xxx`), the token would surface in the transcript. Two reasons this is acceptable:

1. `gh` reads tokens from `GH_TOKEN` env or `gh auth login`, NOT from CLI flags. There is no realistic command shape where a token sits in the literal command string.
2. The transcript echo aids debugging — the operator (and audit chain) can see *what* was blocked, which speeds resolution.

If a future tool adds token-in-flag patterns, add a redaction regex (`s/ghp_[A-Za-z0-9]+/ghp_REDACTED/`) to the echo. Not done preemptively.

## Verification

- [`tests/v2.5-validators/10-pr-merge-guard.sh`](../../tests/v2.5-validators/10-pr-merge-guard.sh): static check of hook presence, regex shape, env-var support, fail-soft on missing jq, hook registration in `hooks/hooks.json`, block-message educational content.
- Functional smoke test pattern (run locally before each release):

  ```bash
  # Block path:
  echo '{"tool_input":{"command":"gh pr merge 25 --squash"}}' | bash hooks/pr-merge-guard.sh
  # → exit 1 with educational stderr

  # Allow path:
  echo '{"tool_input":{"command":"gh pr merge 25 --squash"}}' | BATUTA_ALLOW_PR_MERGE=1 bash hooks/pr-merge-guard.sh
  # → exit 0 with allow log

  # Unrelated commands:
  echo '{"tool_input":{"command":"git status"}}' | bash hooks/pr-merge-guard.sh
  # → exit 0
  echo '{"tool_input":{"command":"gh pr view 25"}}' | bash hooks/pr-merge-guard.sh
  # → exit 0
  ```

## References

- [`hooks/pr-merge-guard.sh`](../../hooks/pr-merge-guard.sh) — the hook itself
- [`hooks/hooks.json`](../../hooks/hooks.json) — registers the hook under matcher `Bash`
- [`tests/v2.5-validators/10-pr-merge-guard.sh`](../../tests/v2.5-validators/10-pr-merge-guard.sh) — static validator
- [ADR-0006](0006-trust-native-delegation.md) — kill-switch-only model that this hook follows
- [ADR-0003](0003-plugin-level-hook-vs-permissions-deny.md) — why hooks instead of `permissions.deny`
- User-level `~/.claude/CLAUDE.md` § "PR policy (always create, never merge)" — the rule this hook backstops
