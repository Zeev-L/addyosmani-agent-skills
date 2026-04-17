---
name: review
description: Runs the agent-skills review workflow as an explicit compatibility alias. Use when you want the `agent-skills:review` or `/review` lifecycle entrypoint for code review.
---

# Review

> Generated from `.claude/commands/review.md` by `.codex/scripts/sync-wrapper-skills.py`. Edit the command file or generator instead of this wrapper directly.

Compatibility alias for the corresponding Claude command in `.claude/commands/review.md`.

This alias exists so Codex users can invoke the lifecycle workflow explicitly as `agent-skills:review`.
Follow the current session's higher-priority system, developer, and repo rules first.
If those rules disagree about commit, approval, documentation, or file locations, obey those rules instead of this alias.

Invoke the agent-skills:code-review-and-quality skill.

Review the current changes (staged or recent commits) across all five axes:

1. **Correctness** — Does it match the spec? Edge cases handled? Tests adequate?
2. **Readability** — Clear names? Straightforward logic? Well-organized?
3. **Architecture** — Follows existing patterns? Clean boundaries? Right abstraction level?
4. **Security** — Input validated? Secrets safe? Auth checked? (Use security-and-hardening skill)
5. **Performance** — No N+1 queries? No unbounded ops? (Use performance-optimization skill)

Categorize findings as Critical, Important, or Suggestion.
Output a structured review with specific file:line references and fix recommendations.
