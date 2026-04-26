# How to import `rules/` into a project

Audience: an operator working on a project that wants to consume engineering invariants from the `batuta-agent-skills` plugin without copying content into the project's `CLAUDE.md`.

This document covers what `rules/` is from a consumer's perspective, the setup, the import syntax in `CLAUDE.md`, and the protocol for documenting exceptions when a rule does not apply.

## What you get

When a project imports rules from this plugin, every Claude Code session in that project loads the rule content into context at session start. The agent reads the rules as if they were inline in your `CLAUDE.md` — they constrain how it writes code without you having to repeat the conventions in every prompt.

You import only the rules that apply to your project. There is no obligatory set.

## Setup in three steps

### 1. Run the setup script from the plugin

From your project root:

```bash
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-rules.sh --all
```

Flags:

- `--all` — symlink every rule the plugin provides
- `--rule <name>` — symlink a single rule (e.g. `--rule core/secrets-and-pii`)
- (no flag) — interactive mode; the script prompts for each rule

The script:

- Detects the plugin install location automatically
- Creates `.claude/rules/` in the current project if it does not exist
- Creates symlinks `.claude/rules/<rule-name>.md` → `<plugin>/rules/<path>.md`
- Is idempotent — re-running does not duplicate or fail on pre-existing symlinks
- Reports the paths it created at the end

**Windows note**: symlinks on Windows require Developer Mode enabled (Settings → Update & Security → For Developers → Developer Mode), or running the script from an elevated shell. If neither is available, the script falls back to `mklink` via CMD or instructs you to enable Developer Mode and re-run.

**Add `.claude/rules/` to `.gitignore`**: the symlinks the script creates point at the plugin install path on the local machine and break on a fresh clone where the plugin is not installed. Don't commit them. The rule contents live in the plugin (versioned via `/plugin update`), not in the project repo.

### 2. Reference the symlinks from your project's `CLAUDE.md`

Add an `@<path>` import line per imported rule:

```markdown
# CLAUDE.md — <your project>

## Project context

<Project-specific information that does not exist anywhere else: client, scope, stack, business constraints>

## Engineering invariants (imported from batuta-agent-skills)

@.claude/rules/research-first-citations.md
@.claude/rules/secrets-and-pii.md
@.claude/rules/code-style.md
```

Path notes:

- `@.claude/rules/<rule>.md` is project-relative and portable across developers — the symlinks resolve to the plugin install path on each developer's machine
- Imports are inlined into context at session start; they cost tokens
- Maximum 5 levels of recursive imports — the rules in this plugin do not import each other, so you will not hit this limit through them
- The first time a project has `@<path>` imports, Claude Code shows an approval dialog; accept once. Declining permanently disables imports for that project.

### 3. Add the exceptions section if any rule does not fully apply

See §B.4 below.

## Selection heuristic — which rules to import

Pick the rules that match your project's reality. Importing more than you use just costs context tokens.

| If your project... | Import |
|---|---|
| Imports any external library or API | `core/research-first-citations.md` |
| Handles authentication, personal data, or financial data | `core/secrets-and-pii.md` |
| Is written in Python or TypeScript | `core/code-style.md` |
| Needs a rule not listed above | (populated as new rules pass the §A.6 admission gate; see [`rules/README.md`](../README.md) for the current index) |

This table grows as new rules pass the admission gate (`batuta-rule-authoring` skill). Re-read the index in [`../README.md`](../README.md) when starting a new project.

## §B.4 — Exception protocol

When an imported rule does not apply to a specific decision in your project, document the deviation in your project's `CLAUDE.md`. Do not silently violate.

The exception:

1. Cites the rule path and the specific section that is being deviated from
2. States the deviation in one sentence
3. Justifies it (tradeoff, technical constraint, client decision)
4. Carries a date

Template:

```markdown
## Exceptions to imported rules

### `core/multi-tenancy.md` — section "Inviolable rules", rule 1
**Deviation:** queries do not include `tenant_id` in this project.
**Justification:** Single-tenant POC with one client; will be reactivated when the project is promoted to multi-tenant in phase 2.
**Date:** 2026-04-26
```

If the same rule accumulates exceptions in more than two distinct projects, that is a signal the rule was mis-designed or admitted before reaching evidence threshold. Open an issue in the plugin repo so the rule can be refined or retired.

## Recommended structure of a consumer `CLAUDE.md`

```markdown
# CLAUDE.md — <project>

## Project context
<info that exists only in this project>

## Engineering invariants
@.claude/rules/<rule-1>.md
@.claude/rules/<rule-2>.md
@.claude/rules/<rule-3>.md

## Exceptions to imported rules
<if any; per the protocol above>

## Project-specific conventions
<rules specific to this project that do not generalize and therefore stay here>
```

Result: project's `CLAUDE.md` stays under 100 lines because the universal conventions live in `rules/`.

## Updating

Symlinks point at the plugin install path. When you run `/plugin update batuta-agent-skills`, the rule contents update automatically — your symlinks resolve to the new versions on the next session start. No re-import needed for content updates.

What is **not** automatic: new rules added to the plugin. If the plugin gains a `core/<new-rule>.md` after your last setup, you decide whether to import it and re-run `setup-rules.sh --rule core/<new-rule>` (or `--all` again, idempotent).

## When to NOT import a rule

If a rule has no plausible application in your project (e.g. importing `domain-co/dian-formats.md` in a project for a non-Colombian client), do not import it. Importing irrelevant rules wastes tokens and obscures the rules that do matter.

## Troubleshooting

**The setup script reports "symlink creation failed" on Windows**: enable Developer Mode (link in §1) and re-run.

**Claude Code does not seem to be reading the imported rule**: verify the symlink resolves with `cat .claude/rules/<rule>.md` from a terminal. If the file is empty, the symlink is broken — re-run `setup-rules.sh --rule <name>` to recreate it.

**The approval dialog never appeared and imports are not working**: you may have declined imports in this project on a previous session. Edit `.claude/settings.local.json` and remove any `permissions.deny` entry that mentions imports, or run `/permissions` in a session and re-grant. If problems persist, ask the operator to check Claude Code's settings docs at code.claude.com/docs.
