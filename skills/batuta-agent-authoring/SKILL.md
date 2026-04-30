---
name: batuta-agent-authoring
description: Use before adding a new agent definition to agents/ in this plugin. Enforces role-distinctness check against existing agents, minimal tool scope, and Batuta naming/tone conventions.
---

# Batuta Agent Authoring

## Overview

**Prevent agent overlap.** Agents compete for triggers; two agents with fuzzy boundaries both fire on the same request and produce inconsistent output. This skill is the gate that forces distinctness before a new agent is merged.

## When to Use

Use this skill whenever you are about to create a new `agents/<name>.md` in this plugin.

Do NOT use for:
- Editing an existing agent (read the agent file, edit, re-verify distinctness)
- Invoking agents in normal workflow

## Process

### Step 1: Scope check against existing agents

List all agents currently in the plugin:

```bash
ls agents/
```

For each existing agent, write one sentence summarizing what it covers. Then write one sentence for the new agent. Compare.

If the new agent's sentence can be rewritten as "<existing agent> + <narrow extension>", do not create a new agent — extend the existing one instead.

If the new agent is genuinely orthogonal, continue.

### Step 2: Search skills.sh for agent-like patterns

```
npx skills find "agent <role>"
```

Some skills on skills.sh (e.g. `subagent-driven-development`) encode agent-invocation patterns. If a vendored skill covers the workflow, prefer that over a new agent.

### Step 3: Define the agent

Write the agent file with these mandatory fields in frontmatter:

```yaml
---
name: agent-name
description: One-line role. Max 150 chars. Starts with a noun phrase.
model: haiku | sonnet | opus   # default haiku unless reasoning load is high
tools:
  - Read
  - Grep
  # List ONLY tools the agent needs. Default to read-only.
---
```

Body sections:

1. **Role** — one paragraph, what this agent is and is not.
2. **When to invoke** — 3 concrete scenarios.
3. **When NOT to invoke** — 3 concrete scenarios (distinctness).
4. **Output format** — explicit shape the agent returns.
5. **Example invocations** — 2 realistic prompts + expected output shape.

### Step 4: Apply Batuta conventions

| Convention | Requirement |
|---|---|
| Language | English only. |
| Description | ≤ 150 characters. Starts with a role noun (e.g. "Senior reviewer that..."). |
| Body length | ≤ 150 lines. |
| Tools list | Read-only by default. Write/Edit/Bash require a one-line justification in the Role section. |
| Name collision | Must not collide with any existing agent in `agents/` or in any vendored skill. |

### Step 5: Write the authoring marker (MANDATORY, last step)

Once Steps 1–4 pass and **before** any `Write` to a new `agents/<name>.md`, run this exact command:

```bash
mkdir -p "${CLAUDE_PLUGIN_ROOT}/.claude" && \
  touch "${CLAUDE_PLUGIN_ROOT}/.claude/.authoring-marker-agent-$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

This drops a marker file consumed by the runtime hook `pre-write-agent-gate.sh`. Without a marker less than 60 minutes old, the hook blocks creation of any new agent file in the plugin repository — that is the enforcement gate from rule `rules/authoring/agent-authoring-required.md`.

The marker file is gitignored. Re-running this command refreshes the timestamp.

**Do not skip this step.** If you skip it, the next `Write` to a new `agents/<name>.md` will fail at the hook with `"Invocá batuta-agent-authoring primero. Marker faltante o expirado."`.

For project-local specialists at `<project>/.claude/agents/<name>.md`: `agent-architect` writes the marker as part of its Phase 5 — you do NOT need to invoke `batuta-agent-authoring` separately.

## Anti-Rationalizations

| Excuse | Reality |
|---|---|
| "This agent handles the same area but 'better'" | Two agents covering the same area will fight for triggers. Improve the existing one. |
| "I need full Bash access for flexibility" | Flexibility in agents = unpredictable behavior. Tighten tools. |
| "Description length doesn't matter" | It shows in every invocation picker. Long descriptions reduce accuracy. |
| "The agent can't be tested in isolation" | If you can't define expected output for 2 example invocations, the role is not clear enough. |

## Red Flags

- Two sentences summarizing existing agent and new agent that differ by a single adjective
- Tool list longer than 6 items
- Description repeats the plugin name or uses marketing phrases
- No "When NOT to invoke" section
- Body exceeds 150 lines
- Code-writing agent (`Edit`/`Write`/`MultiEdit` in `tools`) without an explicit research-first step
- Audit-gate agent (closes with `AUDIT RESULT:` literal) without a Step 0 NOT-APPLICABLE pre-flight

## Verification

Before committing a new agent:

1. **Distinctness proof**: in the PR description, paste the one-sentence summaries of all existing agents + the new agent. Show a reviewer they are non-overlapping.
2. **Format check**:
   ```bash
   wc -l agents/<new-agent>.md   # expect ≤ 150
   ```
3. **Dry-run**: invoke the agent with each of the 2 example prompts from the body. Confirm output matches the declared format.
4. **Tool minimality**: for each tool in the frontmatter `tools` list, show which step in the body uses it. If a tool is listed but unused, remove it.
5. **Research-first wiring (mandatory for code-writing agents)**: if the `tools` list includes `Edit`, `Write`, `MultiEdit`, or `NotebookEdit`, the agent body MUST include an explicit research-first step before any code-writing step. The step requires Context7 lookup against the pinned library version, web-search fallback when Context7 has no coverage, and a `// Source: <url> (verified YYYY-MM-DD, <lib>@<version>)` citation comment at every import site. Mirror the wording used in `agents/implementer.md` Step 2 — do not paraphrase. Read-only agents (Read/Grep/Glob/Bash only) are exempt. Audit-only agents whose Step 0 returns `AUDIT RESULT: NOT APPLICABLE` on a clean tree are also exempt — they are bound by the audit chain scope contract instead (see `docs/DELEGATION-RULE.md` § Audit chain scope).
6. **Audit chain scope wiring (mandatory for audit-gate agents)**: if the agent ends with an `AUDIT RESULT:` literal as its closing line (i.e. it's a gate in the chain), the body MUST include a Step 0 pre-flight that checks `git diff --staged --stat` and `git diff HEAD --stat` and returns `AUDIT RESULT: NOT APPLICABLE` when both report no changes. Mirror the wording used in `agents/code-reviewer.md` Step 0 — do not paraphrase.

If any check fails, do not commit.
