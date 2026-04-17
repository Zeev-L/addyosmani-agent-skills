---
name: ship
description: Runs the agent-skills ship workflow as an explicit compatibility alias. Use when you want the `agent-skills:ship` or `/ship` lifecycle entrypoint for release readiness.
---

# Ship

> Generated from `.claude/commands/ship.md` by `.codex/scripts/sync-wrapper-skills.py`. Edit the command file or generator instead of this wrapper directly.

Compatibility alias for the corresponding Claude command in `.claude/commands/ship.md`.

This alias exists so Codex users can invoke the lifecycle workflow explicitly as `agent-skills:ship`.
Follow the current session's higher-priority system, developer, and repo rules first.
If those rules disagree about commit, approval, documentation, or file locations, obey those rules instead of this alias.

Invoke the agent-skills:shipping-and-launch skill.

Run through the complete pre-launch checklist:

1. **Code Quality** — Tests pass, build clean, lint clean, no TODOs, no console.logs
2. **Security** — npm audit clean, no secrets in code, auth in place, headers configured
3. **Performance** — Core Web Vitals good, no N+1 queries, images optimized, bundle sized
4. **Accessibility** — Keyboard nav works, screen reader compatible, contrast adequate
5. **Infrastructure** — Env vars set, migrations ready, monitoring configured
6. **Documentation** — README current, ADRs written, changelog updated

Report any failing checks and help resolve them before deployment.
Define the rollback plan before proceeding.
