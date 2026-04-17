# User-level rules (jota-batuta)

These rules apply to every Claude Code session, on every project, regardless of per-project CLAUDE.md. Project CLAUDE.md can add or narrow scope but must not contradict these.

## Research-first (non-negotiable)

Before writing code that uses any external library, API, or service:

1. Context7 lookup for the exact version in the project's dependency manifest.
2. If Context7 has no coverage or the version is outdated, web search against the official documentation domain or the library's GitHub repository.
3. Add a source-citation comment at the import site: `// Source: <url> (verified YYYY-MM-DD, <lib>@<version>)`.

Research is cheap, rework is expensive. Trust is not a substitute for verification. This is enforced by the `research-first-dev` skill from `batuta-agent-skills`.

## Divergent then convergent thinking

For any non-trivial decision (architecture, data model, flow, stack choice):

1. **Diverge** — list at least three viable approaches. Include the one that looks obviously right. Do not collapse early.
2. **Converge** — pick one, and for each alternative state the concrete reason it was rejected (cost, complexity, scope, risk). Quantify when possible.
3. Record the decision as an ADR or a bullet in the project's session notes.

Stopping at the first workable idea is the most common failure mode. Force the divergent step even when you think you know.

## Commit after every change

After every meaningful change:

1. `git status` + `git diff` — confirm scope matches intent.
2. `git add <specific files>` — never `git add -A` unless the repo is a fresh scaffold.
3. `git commit` with a message that explains the *why*, not only the *what*.

Never leave uncommitted work at the end of a session. A 10-line dirty tree tomorrow is 2 hours of re-understanding.

## New project = GitHub repo on day 0

If you start a new project:

1. `gh repo create jota-batuta/<name> --private` (or `--public` if it is an open-source artifact like a plugin fork).
2. `git init` + `git remote add origin <url>` + first commit + `git push -u origin main` before writing any feature code.
3. Open a draft PR for the first feature branch immediately. Work on the branch, push often.

A project that lives only on your disk is a project that will never ship. The GitHub repo is the real project.

## PR policy (always create, never merge)

1. Every change goes through a PR — no direct pushes to `main` or `master`.
2. Claude creates PRs via `gh pr create`. Claude never merges PRs.
3. The operator (jota-batuta) merges manually after review.
4. Commits must not include `Co-Authored-By: Claude` or any AI attribution.

## Language policy

- Conversations with the operator: Spanish.
- Artifacts (code, README, SKILL.md, commit messages, PR descriptions, ADRs, tests): English.
- User-facing guides intended for Spanish-speaking clients: Spanish.

One exception to the artifact rule: `docs/` aimed at internal team members may be Spanish if explicitly stated in the project CLAUDE.md.

## Notion KB as durable memory

Use the `notion-kb-workflow` skill from `batuta-agent-skills` at three points:

- `--read client:X project:Y` at the start of a session on an existing project.
- `--init client:X project:Y` before writing code on a brand-new project.
- `--append` at the end of a productive session.

The context window is not memory. Notion is.

## Claude Code boundaries

- Use sub-agents (Task tool) for any work that touches many files or requires research. Keep the main session's context budget under 50% utilization.
- Never block the main session waiting for a long-running process. Use `run_in_background: true` on Bash.
- For deploys, prefer local `docker compose` first; cloud after local is proven,
- For payments, auth secrets, and PII: never commit to the repo, never log in plaintext.
- Never expose secrets or keys to GitHub.

## Autonomous project hygiene

At the start of any session, before writing or editing files, invoke the `batuta-project-hygiene` skill (from the `batuta-agent-skills` plugin) with `mode=project-init` if the current working directory:

- has no `CLAUDE.md` at its root, AND
- contains at least one of: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, or a `.git/` directory.

Before starting work on a new feature — when the operator describes a new feature, capability, or slice — invoke `batuta-project-hygiene` with `mode=feature-init <name>`. The skill handles folder convention, scoped CLAUDE.md, and SPEC.md placement. Do not create CLAUDE.md or feature folders manually in these two cases — delegate to the skill.
