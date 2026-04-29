# Using agent-skills with Cursor

## Setup

### Option 1: Rules Directory (Recommended)

Cursor supports a `.cursor/rules/` directory for project-specific rules:

```bash
# Create the rules directory
mkdir -p .cursor/rules

# Copy skills you want as rules
cp /path/to/agent-skills/skills/test-driven-development/SKILL.md .cursor/rules/test-driven-development.md
cp /path/to/agent-skills/skills/code-review-and-quality/SKILL.md .cursor/rules/code-review-and-quality.md
cp /path/to/agent-skills/skills/incremental-implementation/SKILL.md .cursor/rules/incremental-implementation.md
```

Rules in this directory are automatically loaded into Cursor's context.

### Option 2: .cursorrules File

Create a `.cursorrules` file in your project root with the essential skills inlined:

```bash
# Generate a combined rules file
cat /path/to/agent-skills/skills/test-driven-development/SKILL.md > .cursorrules
echo "\n---\n" >> .cursorrules
cat /path/to/agent-skills/skills/code-review-and-quality/SKILL.md >> .cursorrules
```

## Recommended Configuration

### Essential Skills (Always Load)

Add these to `.cursor/rules/`:

1. `test-driven-development.md` — TDD workflow and Prove-It pattern
2. `code-review-and-quality.md` — Five-axis review
3. `incremental-implementation.md` — Build in small verifiable slices

### Phase-Specific Skills (Load on Demand)

Copy skills into `.cursor/rules/` when working on tasks that need them, and remove when done:

```bash
# When starting spec work
cp /path/to/agent-skills/skills/spec-driven-development/SKILL.md .cursor/rules/spec-driven-development.md

# When doing frontend work
cp /path/to/agent-skills/skills/frontend-ui-engineering/SKILL.md .cursor/rules/frontend-ui-engineering.md

# When hardening security
cp /path/to/agent-skills/skills/security-and-hardening/SKILL.md .cursor/rules/security-and-hardening.md

# When optimizing performance
cp /path/to/agent-skills/skills/performance-optimization/SKILL.md .cursor/rules/performance-optimization.md
```

## Usage Tips

1. **Don't load all skills at once** — Cursor has context limits. Keep only the 2-3 skills relevant to your current task in `.cursor/rules/`.
2. **Reference skills explicitly** — Tell Cursor "Follow the test-driven-development rules for this change" to ensure it reads the loaded rules.
3. **Use agents for review** — Copy `agents/code-reviewer.md` content and tell Cursor to "review this diff using this code review framework."
4. **Paste context on demand** — For one-off tasks, paste the relevant `SKILL.md` content directly into the chat instead of adding it to rules.
