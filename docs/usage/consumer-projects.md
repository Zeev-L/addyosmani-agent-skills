# Consumer projects: bootstrap, retrofit, conventions

This guide covers what to do when you start using the plugin against a consumer repo — yours or a client's. Three scenarios:

- **New project**: `batuta-project-hygiene mode=project-init` handles everything.
- **Existing project without plugin conventions**: `batuta-project-hygiene mode=project-retrofit` adds what's missing without overwriting.
- **Existing project that's already partially adopted**: ad-hoc commands for selective imports.

For the **what gets created** by hygiene, see [`skills/batuta-project-hygiene/SKILL.md`](../../skills/batuta-project-hygiene/SKILL.md).

## Decision tree

```
Does ./CLAUDE.md exist?
├── No  → does the dir have a project manifest? (package.json, pyproject.toml, Cargo.toml, go.mod)
│         ├── Yes → mode=project-init      (full scaffold)
│         └── No  → not a project; skip
└── Yes → does docs/PRD.md, docs/SPEC.md, docs/plans/active/ exist?
          ├── All exist → ad-hoc imports only (selective)
          └── Some missing → mode=project-retrofit (additive)
```

The skill auto-detects which mode applies. You don't pick — you just describe what you're doing and the skill fires.

## New project (full scaffold)

In a fresh project directory, open Claude Code and start describing your work. If `./CLAUDE.md` is missing AND there's a manifest file, `batuta-project-hygiene mode=project-init` auto-triggers and:

1. Detects organization style (feature-oriented vs layer-oriented) — affects where SPEC.md goes for individual features.
2. Detects stack from manifest (Next.js, FastAPI, Django, Rust, Go, etc.).
3. Runs the upstream `/init` command for a stack-aware baseline `CLAUDE.md`.
4. Appends the **Mandatory Skills for Batuta Projects** section verbatim.
5. Creates `docs/{PRD,SPEC}.md` skeletons + `docs/adr/0001-template-decision.md`.
6. Creates `docs/plans/active/`, `docs/plans/archive/`, `docs/sessions/` with `.gitkeep`.
7. Asks the operator: *"Bootstrap cross-tool files (AGENTS.md + .aider.conf.yml)? (Y/n)"*. Default Y.
8. Asks the operator: *"Bootstrap engineering invariants from batuta-agent-skills? (Y/n)"*. Default Y. On Y, runs `setup-rules.sh --all` which also chains into `setup-code-graph.sh` (engines installed).
9. If no `.git/`, runs `git init` + first commit. If no remote, asks about creating a private GitHub repo.

End state: project ready for development with full plugin support.

## Existing project (retrofit)

If `./CLAUDE.md` already exists but parts of the doc skeleton are missing, `batuta-project-hygiene mode=project-retrofit` auto-detects the missing pieces and adds them additively. Triggers explicitly when:

- Operator says "retrofit" or "complete the doc skeleton" in conversation.
- An `implementer` returns a BLOCKER citing missing `docs/plans/active/` or `specs/current/`.

Retrofit is **purely additive**:

- Never overwrites existing `CLAUDE.md` (or any existing file).
- Creates only what's missing: `docs/PRD.md`, `docs/SPEC.md`, `docs/adr/0001-template-decision.md`, `docs/plans/active/.gitkeep`, etc.
- Asks the operator before importing rules or bootstrapping code-graph engines (default Y).
- Reports added vs preserved at the end.

Idempotent — running retrofit twice on the same project does nothing the second time.

## Existing project (selective imports)

If your project already has the doc skeleton and just wants to import specific things from the plugin, run the bootstrap scripts directly:

### Just the rules layer

```bash
cd /path/to/your-repo
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-rules.sh --all
# Or selectively:
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-rules.sh --rule core/research-first-citations
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-rules.sh --rule integrations/code-graph-usage
```

`--all` also chains into `setup-code-graph.sh`, so engines are bootstrapped for this machine in the same pass. After the symlinks land, append the `@.claude/rules/<rule>.md` lines to your project's `CLAUDE.md`.

Add `.claude/rules/` to your repo's `.gitignore` — symlinks are per-machine and break on clones without the plugin installed:

```bash
echo '.claude/rules/' >> .gitignore
```

### Just the code-graph engines

See [`code-graph.md`](code-graph.md). Short version:

```bash
bash ~/.claude/plugins/marketplaces/batuta-agent-skills/tools/setup-code-graph.sh
```

### Just the CI workflow

See [`ci.md`](ci.md). The plugin does NOT install workflows in your repo automatically — you copy `.github/workflows/ci.yml` from the plugin and adapt it to your project's tests.

## Cross-tool portability

If the project may be opened in tools other than Claude Code (Aider, Cursor, Codex, etc.), `mode=project-init` step 4a creates `AGENTS.md` and `.aider.conf.yml` automatically. The doc graph (`docs/PRD.md`, `docs/SPEC.md`, `docs/plans/`) is plain Markdown and works in any tool. The runtime layer (PreToolUse hook, audit chain Task delegation) is Claude Code-specific — see [`docs/PORTABILITY.md`](../PORTABILITY.md).

## Per-feature scaffolding

When you start a new feature in an already-bootstrapped project, `batuta-project-hygiene mode=feature-init <name>` creates:

- A scoped subfolder (`src/<name>/`, `packages/<name>/`, `app/<name>/`, `crates/<name>/`, or `docs/features/<name>/` for layered projects).
- `<feature-folder>/CLAUDE.md` (≤ 60 lines, feature-scoped rules only — does NOT restate project-wide rules; those inherit via Claude Code's nested CLAUDE.md loading).
- `<feature-folder>/SPEC.md` via the upstream `spec-driven-development` skill, with the write target overridden to the feature folder (the upstream defaults to project root, which is wrong for multi-feature projects).
- `feature/<name>` git branch.

Trigger: the operator describes a new feature ("voy a empezar la feature X", "vamos a implementar Y", etc.).

## What hygiene does NOT do

- It does NOT install the Claude Code CLI itself. Install instructions are at [code.claude.com/docs/en/setup](https://code.claude.com/docs/en/setup).
- It does NOT create the GitHub repo without asking (operator must answer Y to the prompt).
- It does NOT push to a remote that doesn't exist. The skill creates a private repo with `gh repo create` only after operator approval.
- It does NOT run `git add -A` on initial commit. Only `CLAUDE.md` is staged for the first hygiene commit; everything else stays untracked until the operator decides what to commit.

## Verification after bootstrap

```bash
test -f CLAUDE.md
test -f docs/PRD.md
test -f docs/SPEC.md
test -f docs/adr/0001-template-decision.md
test -d docs/plans/active && test -d docs/plans/archive && test -d docs/sessions
test -f AGENTS.md                                          # cross-tool, manifest projects
test -L .claude/rules/research-first-citations.md          # if rules opted in
grep -q '@.claude/rules/' CLAUDE.md                        # if rules opted in
git log -1 --oneline | grep -q 'project hygiene'           # initial hygiene commit
```

If any check fails, `mode=project-init` did not complete cleanly. Re-run hygiene; the skill is idempotent.
