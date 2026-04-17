---
name: batuta-skill-authoring
description: Use before adding a new SKILL.md to this plugin. Enforces discover-first workflow (search skills.sh catalog of 91k+ skills) before authoring. If no match, delegates to vendored writing-skills framework with Batuta conventions layered on top.
---

# Batuta Skill Authoring

## Overview

**Prevent skill sprawl.** Most ecosystems grow to 30+ inconsistent skills because contributors author first, search second. This skill inverts the order: **search 91k+ skills first, author only after 3 searches fail**.

This skill wraps two existing resources:
- `skills/_vendored/writing-skills/` — Jesse Vincent's RED-GREEN-REFACTOR framework (MIT)
- `vercel-labs/skills/find-skills` — skills.sh discovery tool (install separately via `npx skills add vercel-labs/skills --skill find-skills`)

Batuta layer adds: discover-first gate, install quality bar, batuta naming/tone conventions.

## When to Use

Use this skill whenever you are about to create a new `skills/<name>/SKILL.md` in this plugin.

Do NOT use for:
- Editing an existing skill (use writing-skills directly)
- Reading or invoking skills in normal workflow

## Process

### Step 1: Discover (MANDATORY)

Before writing any SKILL.md, run:

```
npx skills find "<task description>"
```

If `find-skills` is installed, it returns skills.sh matches ranked by install count. Evaluate each candidate against this install bar:

| Signal | Required |
|---|---|
| Install count | ≥ 10,000 |
| Owner | vercel-labs, anthropics, obra, microsoft, or verified org |
| License | MIT, Apache-2.0, CC0, BSD, or unlicensed-OK-for-reference |
| Last commit | ≤ 6 months |
| Skills.sh audits | Gen Agent / Socket / Snyk all pass or warn |

If at least one candidate passes all 5 → **install it, do not author a new one**:

```
npx skills add <owner>/<repo> --skill <name>
```

If no candidate passes, proceed to Step 2.

### Step 2: Delegate scaffolding to writing-skills

Read `skills/_vendored/writing-skills/SKILL.md` and follow its RED-GREEN-REFACTOR process:

1. Write a pressure test (subagent scenario that should fail without the skill)
2. Verify baseline failure
3. Author minimal SKILL.md
4. Verify test passes
5. Close loopholes

### Step 3: Apply Batuta conventions

After writing-skills produces the draft, enforce these conventions before merging:

| Convention | Requirement |
|---|---|
| Language | English only. No Spanish, no Spanglish. |
| Frontmatter description | ≤ 150 characters. Starts with "Use when..." or similar trigger verb. |
| Body length | ≤ 200 lines total. |
| Tone | Direct, imperative, upstream style. No marketing copy. |
| Required sections | Overview, When to Use, Process, Anti-Rationalizations, Red Flags, Verification. |
| Verification | Must contain grep-able or command-runnable evidence, not "make sure X". |
| Attribution | If derived from a vendored skill, add `Attribution:` line in frontmatter. |

## Anti-Rationalizations

| Excuse | Reality |
|---|---|
| "I already know no skill exists for this" | You haven't checked 91k+ skills. Run `npx skills find` anyway — takes 30 seconds. |
| "My case is unique to Batuta" | Colombian regulations change yearly. Skills encode workflow, not domain facts. Domain facts go in Notion KB via `notion-kb-workflow`. |
| "The discovered skill is 80% right, I'll write a better one" | Fork the discovered skill, vendor it, layer Batuta conventions. Faster and keeps upstream updates. |
| "writing-skills is too heavy for this trivial skill" | If it's trivial, it doesn't need to be a skill. Use a prompt. |

## Red Flags

- About to write a skill without running `npx skills find` first
- Description exceeds 150 chars
- Skill body exceeds 200 lines
- Verification says "make sure..." or "ensure..." instead of an evidence command
- Mixing Spanish and English in the same file
- Two skills in this plugin with overlapping triggers

## Verification

Before committing a new skill:

1. **Discovery proof**: paste the `npx skills find` output into the PR description. Show the top 5 candidates and why each failed the install bar.
2. **Format check**:
   ```bash
   wc -l skills/<new-skill>/SKILL.md   # expect ≤ 200
   head -4 skills/<new-skill>/SKILL.md | grep description | awk -F: '{print length($2)}'   # expect ≤ 150
   ```
3. **Convention check**: grep for Spanish stop-words (`"de la"`, `"el "`, `"que"`) in the new SKILL.md — must return 0 matches.
4. **Trigger eval**: pass the skill through `skill-eval` or equivalent. Required: ≥ 80% triggering accuracy on the test set.

If any check fails, do not commit. Fix and re-verify.
