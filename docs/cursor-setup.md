# Using agent-skills with Cursor

## Setup

### Option 1: Rules Directory (Recommended)

Cursor uses [`.mdc` files](https://cursor.com/docs/rules) in `.cursor/rules/` for project-specific rules. Each `.mdc` file has YAML frontmatter that controls when the rule is loaded into context.

```bash
# Create the rules directory
mkdir -p .cursor/rules

# Copy skills you want as rules (note the .mdc extension)
cp /path/to/agent-skills/skills/test-driven-development/SKILL.md .cursor/rules/test-driven-development.mdc
cp /path/to/agent-skills/skills/code-review-and-quality/SKILL.md .cursor/rules/code-review-and-quality.mdc
cp /path/to/agent-skills/skills/incremental-implementation/SKILL.md .cursor/rules/incremental-implementation.mdc
```

After copying, update the YAML frontmatter in each `.mdc` file. Each `SKILL.md` ships with `name` and `description` fields, but Cursor expects `description`, `globs`, and optionally `alwaysApply`. Replace the frontmatter block so Cursor picks it up correctly:

```yaml
---
description: "Drives development with tests. Use when implementing any logic, fixing any bug, or changing any behavior."
globs: 
alwaysApply: false
---
```

> **Example `globs` values:** `**/*.ts` for TypeScript, `**/*.rb` for Ruby, `**/*.rs` for Rust, `**/*.cs` for C#. Set this to match your project's language so the rule only activates on relevant files.

| Field | Type | Description |
|-------|------|-------------|
| `description` | string | What the rule does (shown in the Cursor rule picker) |
| `globs` | string | File pattern that activates the rule when matching files are open |
| `alwaysApply` | boolean | If `true`, rule is loaded into every conversation regardless of open files |

> **Tip:** Prefer `globs` over `alwaysApply: true`. Glob-scoped rules only activate when relevant files are open, keeping context usage efficient. Use `alwaysApply` sparingly for universal project standards.

Rules in this directory are automatically loaded into Cursor's context. When `globs` are set, rules only activate when matching files are open.

### Option 2: .cursorrules File

Create a `.cursorrules` file in your project root with the essential skills inlined:

```bash
# Generate a combined rules file
cat /path/to/agent-skills/skills/test-driven-development/SKILL.md > .cursorrules
echo "\n---\n" >> .cursorrules
cat /path/to/agent-skills/skills/code-review-and-quality/SKILL.md >> .cursorrules
```

### Option 3: Notepads

Cursor's Notepads feature lets you store reusable context. Create a notepad for each skill you use frequently:

1. Open Cursor → Settings → Notepads
2. Create a new notepad named "swe: Test-Driven Development"
3. Paste the content of `skills/test-driven-development/SKILL.md`
4. Reference it in chat with `@notepad swe: Test-Driven Development`

## Recommended Configuration

### Essential Skills (Always Load)

Add these to `.cursor/rules/`:

1. `test-driven-development.mdc` — TDD workflow and Prove-It pattern
2. `code-review-and-quality.mdc` — Five-axis review
3. `incremental-implementation.mdc` — Build in small verifiable slices

### Phase-Specific Skills (Load as Notepads)

Create notepads for skills you use contextually:

- "swe: Spec Development" → `spec-driven-development/SKILL.md`
- "swe: Frontend UI" → `frontend-ui-engineering/SKILL.md`
- "swe: Security" → `security-and-hardening/SKILL.md`
- "swe: Performance" → `performance-optimization/SKILL.md`

Reference them with `@notepad` when working on relevant tasks.

## Usage Tips

1. **Don't load all skills at once** — Cursor has context limits. Load 2-3 skills as rules and keep others as notepads.
2. **Reference skills explicitly** — Tell Cursor "Follow the test-driven-development rules for this change" to ensure it reads the loaded rules.
3. **Use agents for review** — Copy `agents/code-reviewer.md` content and tell Cursor to "review this diff using this code review framework."
4. **Load references on demand** — When working on performance, reference `@notepad performance-checklist` or paste the checklist content.
