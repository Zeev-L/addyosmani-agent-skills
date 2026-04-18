---
name: batuta-project-hygiene
description: Use at session start when cwd has no CLAUDE.md, and ALWAYS before creating any SPEC.md or feature-scoped CLAUDE.md. Feature SPEC.md and CLAUDE.md NEVER go at project root - they go inside src/feature/, packages/feature/, app/feature/, or features/feature/. Two modes - project-init, feature-init.
---

# Batuta Project Hygiene

## Overview

**Eliminate the manual CLAUDE.md step.** Projects need a rules file before the first code change, and features need a scoped rules file before the first spec. If the operator has to remember to create these, they will not get created. This skill auto-invokes on the two triggers where it matters: session start on an uninitialized project, and the moment a new feature is announced.

Two modes, both invoked without user typing a slash command:

- **`project-init`** — the project root has no `CLAUDE.md` but looks like a project. Bootstraps rules file + GitHub repo + first commit.
- **`feature-init`** — the operator described a new feature, capability, or slice. Creates a scoped sub-folder with its own `CLAUDE.md` and `SPEC.md`, then hands off to `spec-driven-development`.

This skill does not replace `spec-driven-development` — it prepares the filesystem so `spec-driven-development` has somewhere correct to write.

### Target layout

A project can hold one feature or many. Every feature lives in its own subfolder under the project's features root. Feature-scoped `SPEC.md` and `CLAUDE.md` NEVER live at project root.

```
<project-root>/
├── CLAUDE.md                ← project-wide rules (one file, shared by all features)
├── <manifest>               ← pyproject.toml / package.json / Cargo.toml / go.mod
└── src/                     ← features root (or packages/, app/, features/, crates/)
    ├── feature-one/
    │   ├── CLAUDE.md        ← scoped to feature-one
    │   ├── SPEC.md          ← scoped to feature-one
    │   └── <source files>
    ├── feature-two/
    │   ├── CLAUDE.md
    │   ├── SPEC.md
    │   └── <source files>
    └── feature-three/
        ├── CLAUDE.md
        ├── SPEC.md
        └── <source files>
```

## When to Use

### Mode `project-init`

Auto-trigger when **all** of these are true at session start:

- `./CLAUDE.md` does not exist.
- `./` contains at least one of: `package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, `go.mod`, `pom.xml`, `Gemfile`, `.git/`.

Do NOT trigger:
- In a plain directory with no project markers (the operator may be exploring, not initializing).
- If `CLAUDE.md` already exists, even if empty — respect the operator's choice.
- Inside `node_modules/`, `.git/`, `target/`, `dist/`, `vendor/`, or other generated directories.

### Mode `feature-init`

Auto-trigger when the operator describes a new feature with phrases like:

- "voy a empezar/hacer la feature X"
- "vamos a implementar X"
- "necesito agregar X al proyecto"
- "start/implement feature X"

Do NOT trigger:
- When the operator asks a question about an existing feature.
- When the operator asks for code inside a file that already has a feature folder.
- When the operator is in mid-session on the same feature (check git branch + recent commits).

## Process

### Mode: `project-init`

1. **Detect stack** from manifest files. Map to stack name:
   - `package.json` with `"next"` dep → `nextjs`
   - `package.json` with `"react"` dep → `react`
   - `package.json` with `"express"` / `"fastify"` → `node-api`
   - `pyproject.toml` or `requirements.txt` with `fastapi` → `fastapi`
   - `pyproject.toml` with `django` → `django`
   - `Cargo.toml` → `rust`
   - `go.mod` → `go`
   - otherwise → `generic`

2. **Invoke built-in `/init`** to get a stack-aware baseline `CLAUDE.md`. This populates Tech Stack, Commands, and Project Structure from the actual files.

3. **Append Batuta sections** to the generated `CLAUDE.md`:
   - `## Mandatory Skills for Batuta Projects` — copy verbatim from this plugin's root `CLAUDE.md`.
   - `## Feature folder convention` — **placeholder**, filled in on first `feature-init` invocation (see Mode: feature-init step 1).

4. **GitHub boilerplate** (per user-level CLAUDE.md rule "New project = GitHub repo on day 0"):
   - If no `.git/` exists: `git init && git add CLAUDE.md && git commit -m "chore: initial project hygiene"`
   - If no remote: ask operator `"Crear repo GitHub <jota-batuta/<detected-name>>? (y/n)"`. On `y`: `gh repo create jota-batuta/<name> --private --source=. --remote=origin --push`.

5. **Verification**:
   - `./CLAUDE.md` exists and contains `## Mandatory Skills for Batuta Projects`
   - `git log -1 --oneline` shows the hygiene commit
   - `git remote get-url origin` returns a URL (if GitHub step ran)

### Mode: `feature-init <name>`

**Hard constraint before any step**: the feature's `SPEC.md` and `CLAUDE.md` MUST be created inside a subfolder, NEVER at the project root. If the upstream `/spec` command would write to root, override its target. The root is reserved for project-wide files only.

1. **Read `./CLAUDE.md` `## Feature folder convention` section**:
   - If it contains a filled-in path template (e.g. `features/<name>/`, `packages/<name>/`, `src/<name>/`, `app/<name>/`) → use it.
   - If it is a placeholder or missing → **auto-detect first**, then ask only if ambiguous:
     - `pyproject.toml` + existing `src/` directory → default to `src/<name>/`
     - `package.json` + existing `packages/` directory → default to `packages/<name>/`
     - `package.json` with Next.js App Router + `app/` directory → default to `app/<name>/`
     - `package.json` without `packages/` or `app/` → default to `features/<name>/`
     - Rust (`Cargo.toml`) with workspace → `crates/<name>/`
     - Otherwise ask:
       ```
       Qué convención de carpetas usas para features en este proyecto?
         1) src/<name>/        (detected: Python src-layout or similar)
         2) packages/<name>/   (pnpm/Yarn workspace)
         3) app/<name>/        (Next.js App Router)
         4) features/<name>/
         5) otra: <ruta>

       (La respuesta queda guardada en CLAUDE.md y no se te preguntará de nuevo.)
       ```
   - After resolving (auto-detect or user answer), write the chosen template into `./CLAUDE.md` at `## Feature folder convention`.

2. **Create the feature folder** at the resolved path. Reject if it already exists (operator should use an existing-feature flow, not this mode).

3. **Create `<feature-folder>/CLAUDE.md`** with scoped rules:
   ```markdown
   # Feature: <name>

   Inherits from `../CLAUDE.md` and `~/.claude/CLAUDE.md`. Only feature-specific rules live here.

   ## Scope
   <one-sentence operator-provided description>

   ## Boundaries
   - Do not modify files outside this folder without opening a separate PR.
   - Commits must stay within this feature branch.
   - Feature tests live alongside source, not in a global test directory.
   ```

4. **Delegate SPEC creation** to the upstream `spec-driven-development` skill, **explicitly overriding its default write target** to `<feature-folder>/SPEC.md`. The upstream skill defaults to project root — that default is wrong for multi-feature projects. Pass the target path explicitly.

   If the upstream skill resists or produces `SPEC.md` at root anyway:
   - Move it: `mv SPEC.md <feature-folder>/SPEC.md`
   - Do not proceed to commit until SPEC.md is inside the feature folder.

5. **Commit**:
   ```bash
   git checkout -b feature/<name>
   git add <feature-folder>/
   git commit -m "feat(<name>): scaffold feature folder with CLAUDE.md and SPEC.md"
   ```

6. **Verification**:
   - `<feature-folder>/CLAUDE.md` exists
   - `<feature-folder>/SPEC.md` exists
   - `git branch --show-current` returns `feature/<name>`

## Anti-Rationalizations

| Excuse | Reality |
|---|---|
| "The operator didn't say 'create CLAUDE.md' so I shouldn't" | The user-level rule delegates the decision to this skill. That IS the explicit permission. |
| "`/init` alone is enough" | `/init` does not add Batuta Mandatory Skills or set up the feature convention. Use `/init` as Step 2 of project-init, not as the whole flow. |
| "Ask before creating the feature folder" | Feature naming is the only ambiguous part. If the folder name is ambiguous (e.g. operator says "auth stuff"), ask for a kebab-case name, then proceed — do not ask permission for every step. |
| "The operator will fix the CLAUDE.md later" | Later means never. The rules file exists at session start or doesn't exist. |

## Red Flags

- **SPEC.md or CLAUDE.md for a feature ending up at project root.** This is the top failure mode. If you see SPEC.md at root after a feature-init, move it immediately and check why the upstream skill wasn't redirected.
- Creating a feature folder without reading `## Feature folder convention` from the project CLAUDE.md first.
- Generating a CLAUDE.md that is a verbatim copy of another project's CLAUDE.md (always re-run stack detection).
- Committing across feature boundaries (feature-init must only touch its own folder).
- Skipping the git branch creation in feature-init mode.
- Pushing to GitHub without asking the operator first, or pushing to a public repo when the operator said `--private`.
- Ignoring auto-detection signals (if `src/` directory exists in a Python project, default to `src/<name>/`; do not ask the operator a question that the project structure already answers).

## Verification

After `project-init`:
```bash
test -f CLAUDE.md                           # exists
grep -q "Mandatory Skills for Batuta" CLAUDE.md   # Batuta section present
grep -q "Feature folder convention" CLAUDE.md     # placeholder present
git log --oneline -1 | grep -q "project hygiene"  # committed
```

After `feature-init <name>`:
```bash
test -f features/<name>/CLAUDE.md 2>/dev/null || test -f packages/<name>/CLAUDE.md 2>/dev/null || test -f src/<name>/CLAUDE.md 2>/dev/null
test -f features/<name>/SPEC.md 2>/dev/null || test -f packages/<name>/SPEC.md 2>/dev/null || test -f src/<name>/SPEC.md 2>/dev/null
git branch --show-current | grep -q "feature/<name>"
```

If any check fails, the mode did not complete — report the failure to the operator and do not proceed to the next user task.
