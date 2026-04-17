# Attribution

This fork (`jota-batuta/batuta-agent-skills`) is derived from [`addyosmani/agent-skills`](https://github.com/addyosmani/agent-skills) and incorporates skills from two additional upstreams under their respective licenses.

## Upstream Base

- **`addyosmani/agent-skills`** — MIT License. Tracked via `upstream` remote. Merge via `git fetch upstream && git merge upstream/main`.

## Vendored Skills

Skills copied into `skills/_vendored/` with their original LICENSE files. Not modified in this fork.

| Vendored path | Source | License | Author | Purpose |
|---|---|---|---|---|
| `skills/_vendored/writing-skills/` | [`obra/superpowers`](https://github.com/obra/superpowers) | MIT | Jesse Vincent | RED-GREEN-REFACTOR framework for authoring new SKILL.md files. Consumed by `skills/batuta-skill-authoring/`. |
| `skills/_vendored/context7/` | [`intellectronica/agent-skills`](https://github.com/intellectronica/agent-skills) | CC0-1.0 | intellectronica | Library documentation lookup via Context7 API. Consumed by `skills/research-first-dev/`. |

Each vendored directory contains a copy of the source repository's LICENSE file. Full license text is preserved.

## Referenced External Skill (not vendored)

- **`vercel-labs/skills/find-skills`** — no LICENSE file in source repo at time of adoption. Installed on demand via:

  ```bash
  npx skills add vercel-labs/skills --skill find-skills
  ```

  Consumed by `skills/batuta-skill-authoring/` Step 1 (discovery). Cannot be vendored until upstream publishes a license.

## New Skills (this fork)

Written from scratch in this fork. License: same as parent (MIT per upstream `addyosmani/agent-skills`).

| Skill | Origin |
|---|---|
| `skills/batuta-skill-authoring/` | Wraps `writing-skills` (vendored) + `find-skills` (referenced). |
| `skills/batuta-agent-authoring/` | From scratch. No existing upstream equivalent. |
| `skills/research-first-dev/` | Wraps `context7` (vendored) with a citation-comment enforcement gate. |
| `skills/notion-kb-workflow/` | From scratch. Consumes the official Notion MCP plugin. |

## Merging Upstream Changes

```bash
git fetch upstream
git merge upstream/main
```

Conflicts are expected only in `CLAUDE.md` (fork adds "Mandatory Skills" section) and possibly `README.md`. Resolve by preserving the fork's additions.
