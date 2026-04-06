# Using agent-skills with Cursor

## Setup

### Option 1: Skills Directory

Since [Cursor 2.4](https://cursor.com/changelog/2-4), the editor natively supports **Agent Skills** — defined as `SKILL.md` files inside `.cursor/skills/`. This is a perfect match for agent-skills, since each skill already ships as a `SKILL.md` with the same YAML frontmatter format Cursor expects (`name` and `description`).

```bash
# Create the skills directory
mkdir -p .cursor/skills

# Copy skills you want — each in its own subdirectory
cp -r /path/to/agent-skills/skills/test-driven-development .cursor/skills/
cp -r /path/to/agent-skills/skills/code-review-and-quality .cursor/skills/
cp -r /path/to/agent-skills/skills/incremental-implementation .cursor/skills/
```

Unlike rules (which are always loaded), skills are **loaded dynamically** — the agent decides when they're relevant based on the `description` field in the frontmatter. This keeps your context window clean.

You can also invoke any skill manually via the **slash command menu** in chat.

> **Tip:** In Cursor, go to **New Cursor Rule** and it will create a `SKILL.md` in `.cursor/skills/` automatically. You can use this to create project-specific skills that complement the ones from agent-skills.

### Option 2: Cursor Plugins

Cursor 2.5+ supports [plugins](https://cursor.com/docs/plugins) that bundle skills, subagents, MCP servers, and more. If agent-skills is published as a plugin, you can install it directly:

1. Open the **Cursor Marketplace** or use `/add-plugin` in chat
2. Search for the plugin
3. Install with one click

For teams, you can also set up a **private marketplace** to distribute curated skill sets.

### Option 3: Rules Directory

Cursor supports `.cursor/rules/` for **always-on, declarative rules**. Rules are loaded into every conversation automatically — use them for coding standards, style guides, and project conventions that must always apply:

```bash
mkdir -p .cursor/rules

# Copy skills as always-on rules
cp /path/to/agent-skills/skills/test-driven-development/SKILL.md .cursor/rules/test-driven-development.md
cp /path/to/agent-skills/skills/code-review-and-quality/SKILL.md .cursor/rules/code-review-and-quality.md
```

> **Note:** Rules and skills serve different purposes. Rules are best for standards that should **always** be enforced. Skills are best for procedural workflows the agent loads **when relevant**. See the comparison table below.

### Option 4: Notepads

Cursor's Notepads feature lets you store reusable context you can reference on demand:

1. Open Cursor → Settings → Notepads
2. Create a new notepad named "swe: Test-Driven Development"
3. Paste the content of `skills/test-driven-development/SKILL.md`
4. Reference it in chat with `@notepad swe: Test-Driven Development`

## Skills vs Rules — When to Use Which

| | Skills (`.cursor/skills/`) | Rules (`.cursor/rules/`) |
|---|---|---|
| **Loading** | Dynamic — agent loads when relevant | Always on — every request |
| **Best for** | Procedural how-to, workflows, domain knowledge | Coding standards, style guides, project conventions |
| **Context cost** | Low (only when needed) | High (always present) |
| **Invocation** | Automatic or via slash command | Automatic |

## Recommended Configuration

### As Skills (Dynamic — Loaded When Relevant)

Copy these into `.cursor/skills/` so the agent pulls them in when the task matches:

- `test-driven-development` — TDD workflow and Prove-It pattern
- `code-review-and-quality` — Five-axis review
- `incremental-implementation` — Build in small verifiable slices
- `spec-driven-development` — Write specs before code
- `frontend-ui-engineering` — Frontend UI patterns
- `security-and-hardening` — Security review
- `performance-optimization` — Performance tuning

### As Rules (Always On)

If your team has non-negotiable standards, load these as rules:

- `code-review-and-quality` — Ensure every change is reviewed
- `test-driven-development` — Enforce TDD in all work

### As Notepads (On Demand)

Keep these as notepads for occasional reference:

- "swe: Security Checklist" → `references/security-checklist.md`
- "swe: Performance Checklist" → `references/performance-checklist.md`
- "swe: Accessibility Checklist" → `references/accessibility-checklist.md`

## Usage Tips

1. **Use both skills and rules** — They're complementary. Rules enforce standards in every conversation; skills provide workflows on demand.
2. **Don't load everything as rules** — Cursor has context limits. Only use rules for standards that must always apply. Let the agent discover skills dynamically for everything else.
3. **Reference skills explicitly when needed** — Tell Cursor "Use the test-driven-development skill for this change" to ensure it loads a specific skill.
4. **Use agents for review** — Copy `agents/code-reviewer.md` content and tell Cursor to "review this diff using this code review framework."
5. **Combine approaches** — Use rules for team standards, skills for workflows, and notepads for reference material.
