# agent-skills

This is the agent-skills project — a collection of production-grade engineering skills for AI coding agents.

## Project Structure

```
skills/       → Core skills (SKILL.md per directory)
agents/       → Reusable agent personas (code-reviewer, test-engineer, security-auditor)
hooks/        → Session lifecycle hooks
.claude/commands/ → Slash commands (/spec, /plan, /build, /test, /review, /code-simplify, /ship)
references/   → Supplementary checklists (testing, performance, security, accessibility)
docs/         → Setup guides for different tools
```

## Skills by Phase

**Define:** spec-driven-development
**Plan:** planning-and-task-breakdown
**Build:** incremental-implementation, test-driven-development, context-engineering, source-driven-development, frontend-ui-engineering, api-and-interface-design
**Verify:** browser-testing-with-devtools, debugging-and-error-recovery
**Review:** code-review-and-quality, code-simplification, security-and-hardening, performance-optimization
**Ship:** git-workflow-and-versioning, ci-cd-and-automation, deprecation-and-migration, documentation-and-adrs, shipping-and-launch

## Conventions

- Every skill lives in `skills/<name>/SKILL.md`
- YAML frontmatter with `name` and `description` fields
- Description starts with what the skill does (third person), followed by trigger conditions ("Use when...")
- Every skill has: Overview, When to Use, Process, Common Rationalizations, Red Flags, Verification
- References are in `references/`, not inside skill directories
- Supporting files only created when content exceeds 100 lines

## Commands

- `npm test` — Not applicable (this is a documentation project)
- Validate: Check that all SKILL.md files have valid YAML frontmatter with name and description

## Boundaries

- Always: Follow the skill-anatomy.md format for new skills
- Never: Add skills that are vague advice instead of actionable processes
- Never: Duplicate content between skills — reference other skills instead

---

## Mandatory Skills for Batuta Projects

This fork (`jota-batuta/batuta-agent-skills`) adds five skills on top of the upstream. The `using-agent-skills` meta-skill must route to these skills at the triggers below.

### batuta-project-hygiene (auto)
**MUST trigger** at two points without waiting for a slash command:
- `mode=project-init` at session start when cwd has no `CLAUDE.md` but contains project markers (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `.git/`, etc.).
- `mode=feature-init <name>` when the operator describes a new feature, capability, or slice — creates a scoped sub-folder with its own `CLAUDE.md` and `SPEC.md` on a `feature/<name>` branch.

Rationale: CLAUDE.md creation and feature scoping must not depend on the operator remembering a slash command.

### batuta-skill-authoring
**MUST trigger** before adding any new SKILL.md to this plugin.
Rationale: prevents skill sprawl. Forces `npx skills find` against skills.sh's 91k+ skills before authoring.

### batuta-agent-authoring
**MUST trigger** before adding any new agent definition to `agents/`.
Rationale: prevents agent overlap. Forces distinctness check against existing agents.

### research-first-dev
**MUST trigger** before writing code that imports or calls any external library/API not yet cited in this session.
Rationale: most bugs come from assuming outdated APIs. Context7 lookup is cheap, rework is expensive. Evidence lives in a `// Source:` citation comment.

### notion-kb-workflow
**MUST trigger** at three session boundaries:
- `--read` at the start of a session on an existing project
- `--init` at the start of a new project not yet represented in Notion
- `--append` at the end of a productive session (commits made or decisions taken)

Rationale: the context window is not memory. Notion is.

---

## Vendored Skills

The `skills/_vendored/` directory contains upstream skills this fork depends on. They are copied with their original LICENSE files and must not be modified in this fork. See `ATTRIBUTION.md` for authors and licenses.
