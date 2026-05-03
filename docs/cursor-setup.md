# Using agent-skills with Cursor

Cursor 3.x+ (stable) supports native Agent Skills. Skills load dynamically into context only when relevant — keeping your context window clean, unlike rules which are always included.

## Setup

### Personal install (recommended)

Install skills globally so they're available across all your projects:

```bash
mkdir -p ~/.cursor/skills
cp -r /path/to/agent-skills/skills/* ~/.cursor/skills/
```

Or with a one-liner from the repo:

```bash
git clone https://github.com/addyosmani/agent-skills.git /tmp/agent-skills \
  && mkdir -p ~/.cursor/skills \
  && cp -r /tmp/agent-skills/skills/* ~/.cursor/skills/ \
  && rm -rf /tmp/agent-skills
```

### Project install

Install skills into your project so they're shared with your team (commit `.cursor/skills/` to version control):

```bash
mkdir -p .cursor/skills
cp -r /path/to/agent-skills/skills/* .cursor/skills/
```

## How it works

Cursor reads the `name` and `description` from each `SKILL.md` frontmatter at startup. When you make a request, the agent evaluates which skills are relevant and loads the full `SKILL.md` only for those — minimizing token usage while keeping specialized workflows available on demand.

Skills live in directories under `~/.cursor/skills/` (personal) or `.cursor/skills/` (project):

```
~/.cursor/skills/
├── test-driven-development/
│   └── SKILL.md
├── code-review-and-quality/
│   └── SKILL.md
└── ...
```

## Usage tips

1. **Skills activate automatically** — the agent reads all descriptions and decides which skills to apply based on your request. You can also reference them explicitly: "Follow the test-driven-development process for this change."
2. **Personal vs project scope** — use `~/.cursor/skills/` for general engineering practices you want everywhere; use `.cursor/skills/` for project-specific workflows committed to your repo.
3. **Don't load all skills at once as rules** — if you were previously using `.cursor/rules/` or `.cursorrules`, migrate to the skills directory for dynamic loading. Use `~/.cursor/skills/` for personal workflows.
4. **Use agents for review** — copy `agents/code-reviewer.md` content and tell Cursor to "review this diff using this code review framework."

## Migrating from rules / .cursorrules

If you previously copied `SKILL.md` files into `.cursor/rules/` or inlined them into `.cursorrules`, migrate to the native skills directory:

```bash
# Move project rules to native skills
mkdir -p .cursor/skills
for f in .cursor/rules/*.md; do
  name=$(basename "$f" .md)
  mkdir -p ".cursor/skills/$name"
  mv "$f" ".cursor/skills/$name/SKILL.md"
done

# Or just start fresh from the repo
cp -r /path/to/agent-skills/skills/* .cursor/skills/
```

Cursor also ships a built-in `/migrate-to-skills` agent command that automates this conversion.
