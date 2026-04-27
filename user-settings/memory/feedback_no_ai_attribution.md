---
name: feedback_no_ai_attribution
description: Never include Co-Authored-By Claude or any AI attribution in commits, PRs, or any artifact
type: feedback
---

# No AI attribution in commits or PRs

## The rule

Commits and PR descriptions MUST NOT contain `Co-Authored-By: Claude`, `🤖 Generated with Claude Code`, or any other AI-attribution footer.

**Why:** the operator considers AI attribution noise that pollutes git history. The work is the operator's; tooling used to produce it is irrelevant to the historical record. This is documented as a hard rule in `~/.claude/CLAUDE.md` "PR policy" section.

**How to apply:**

- When generating commit messages: stop at the message body. Do not append any attribution footer, even when default templates suggest one.
- When generating PR descriptions: same — body only, no footer.
- When generating release notes or CHANGELOG entries: same.

## Exceptions

None. This applies to all repos and all branches the operator owns.

## Enforcement signal

If you catch yourself about to add a footer, stop. The user-level `CLAUDE.md` is loaded at every session start; the rule is always in context. There is no acceptable scenario for adding the attribution.
