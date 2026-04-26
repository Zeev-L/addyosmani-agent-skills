---
name: batuta-rule-authoring
description: Gatekeeps new files under rules/. Validates §A.4 format, §A.5 conventions, §A.6 evidence. Use before adding any rules/ file.
---

# Batuta Rule Authoring

## Overview

Prevents low-quality or premature rules from entering `rules/`. A rule is a declarative invariant distilled from repeated, evidence-backed engineering practice — not an idea, not a preference, not advice found online. This skill validates §A.4 (canonical format), §A.5 (style conventions), and §A.6 (admission gate: N=2 distinct projects) before allowing any `.md` to be materialized under `rules/<folder>/`. It does NOT perform external research — rules are distilled from practice the operator already has, not investigated from scratch.

**Scope of this gate.** The skill validates *structure* (format, conventions, evidence count) — not *content*. A well-formed but adversarial rule (e.g. one that smuggles malicious guidance dressed in §A.4 sections) would pass this gate. Content review is the operator's responsibility at PR-review time. Do not assume the gate substitutes for human review of the rule's substance.

## When to Use

- Before adding any new `.md` file under `rules/core/`, `rules/stack/`, `rules/domain-co/`, or `rules/delivery/`
- When promoting an inline project convention from a project's `CLAUDE.md` to a shared plugin rule

## When NOT to Use

- Editing or updating an existing rule (read the file, edit, re-verify §A.4 and §A.5, done)
- Invoking a rule in a workflow (that is normal `CLAUDE.md` + `@<path>` import; no gating needed)
- Creating a new skill (`batuta-skill-authoring` handles that)
- Creating a new agent (`batuta-agent-authoring` handles that)

## Process

### Step 1: Discovery against existing rules

List all existing rules to check for overlap:

```bash
find rules/ -name "*.md" | grep -v "_meta\|README"
```

Read each candidate file. If the proposed rule overlaps >70% semantically with an existing one, recommend editing the existing file instead. Document the reason in the review response. Do not proceed to later steps if overlap is found.

### Step 2: §A.6 admission gate — N=2 evidence check

Ask the operator (or invoking agent): in which ≥2 distinct projects has this invariant applied without exceptions?

- Each project must be named or described concisely (no client names — use project type or stack)
- "Applied without exceptions" means the rule was enforced as stated, no deviation was needed in that project

**Block creation if <2 distinct projects are cited.** Respond with:

> BLOCKED: §A.6 gate requires evidence of application in ≥2 distinct projects. You have cited N=[n]. If this rule is important now, document it inline in your current project's `CLAUDE.md`. When it shows up in a second project, promote it here.

**Documented exception:** rules that are verbatim derivations from `~/.claude/CLAUDE.md` global count as universally applied across all sessions. They pass §A.6 automatically — cite the source section in the frontmatter `last-reviewed` notes or a comment.

### Step 3: §A.4 format validation

Verify the proposed content includes all mandatory sections in order:

1. **Inviolable rules** — numbered list, imperative, verifiable
2. **Allowed patterns** — at least one executable example in a language from `applies-to`
3. **Anti-patterns** — non-empty; each example names which inviolable rule it breaks
4. **Documented exceptions** — optional section; absence is allowed

**Reject if Anti-patterns section is missing or empty.** A rule without anti-patterns is indistinguishable from generic advice.

### Step 4: §A.5 conventions check

Verify all of the following:

- File length: 50–200 lines (count with `wc -l <file>`)
- Tone: imperative throughout. Flag and reject any "should", "consider", "best practice", "it is recommended"
- Examples: code blocks run in a language declared in `applies-to`; they are minimal and executable, not pseudo-code
- No client names: scan body for proper nouns matching known client identifiers. The rule must generalize

### Step 5: Frontmatter check

Required frontmatter keys: `title`, `applies-to` (non-empty array), `last-reviewed` (YYYY-MM-DD).

**Reject if `name:` or `description:` keys appear in the frontmatter.** Those keys belong to `SKILL.md` files, not rules. Visual differentiation helps human readers distinguish the two layer formats at a glance and prevents tooling confusion if auto-discovery is ever extended.

### Step 6: Materialize

After all checks pass, write the file at `rules/<folder>/<kebab-case-name>.md`. Confirm with `wc -l` and report the count.

## Anti-Rationalizations

| Excuse | Reality |
|---|---|
| "This is generic advice, it doesn't need anti-patterns" | Without anti-patterns the rule is vague. A code reviewer cannot cite it. Generic advice belongs in a README, not in `rules/`. |
| "I've applied it in 1 project but it will be useful in others" | §A.6 gate is N=2 with evidence. Wait for the second project. Document inline in your current project's `CLAUDE.md` in the meantime. |
| "It's important, I must create it now" | Importance does not bypass the evidence gate. A rule admitted at N=1 is a hypothesis. Document it in the project's `CLAUDE.md`; when it appears in a second project without deviation, promote it here. |
| "The frontmatter `name:` field doesn't hurt anything" | Defense in depth. Auto-discovery is path-scoped and won't break, but mixing `name:` / `description:` into rule frontmatter erodes the visual contract between the `skills/` and `rules/` layers — one key at a time. |

## Red Flags

- Anti-patterns section is empty or missing
- File exceeds 200 lines without being split at a logical boundary
- A client name (proper noun identifying a real engagement) appears in the body
- The proposed rule duplicates an existing one with only cosmetic renaming
- Code examples are pseudo-code or do not use a language listed in `applies-to`
- Frontmatter contains `name:` or `description:` keys

## Verification

After the file is written, run these checks:

- `wc -l rules/<folder>/<name>.md` — expect 50–200
- `grep -i "anti-pattern" rules/<folder>/<name>.md` — must return ≥1 match (section header present)
- Frontmatter block (between `---` delimiters) parses as valid YAML
- `grep -E "^name:|^description:" rules/<folder>/<name>.md` — must return 0 matches
- `applies-to` value is a non-empty YAML array (not a bare string, not empty `[]`)
