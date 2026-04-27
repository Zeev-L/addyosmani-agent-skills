---
name: feedback_pr_policy
description: Claude creates PRs via gh pr create but never merges; operator merges manually after review
type: feedback
---

# PR policy: create yes, merge no

## The rule

- Every change goes through a PR. No direct pushes to `main` or `master`.
- Claude opens PRs with `gh pr create` (or equivalent). Claude **never** runs `gh pr merge`, `git merge`, or any other merge-equivalent.
- The operator (jota-batuta) merges manually from GitHub UI after review.

**Why:** merge authority is an operator-only decision. PR creation is mechanical work that automates the operator's workflow; merging is the gate where the operator validates the work and accepts ownership of the change in production. Removing that gate would erase the operator's review step.

**How to apply:**

- After completing a slice and passing audit chain, run `git push -u origin <branch>` and then `gh pr create --repo jota-batuta/<repo> --base main --head <branch> --title ... --body ...`.
- Always pass `--repo` explicitly when the local git remote is a fork (e.g. `addyosmani/agent-skills` is the upstream of `jota-batuta/batuta-agent-skills`); without it, `gh` defaults to the upstream and the PR fails with "no commits between branches".
- After creating the PR, return the URL to the operator. **Stop there.** Do not propose merging, do not run any merge command.
- If the operator says "ya mergeaste" or "ya está mergeado", that is information from them about an action they took, not authorization for you to retro-merge.

## Common confusion to avoid

- "PR único final con commits por fase" was the operator's pattern in long sessions: one branch, multiple commits, one PR — but still operator-merged at the end. Multiple commits ≠ multiple PRs ≠ Claude merging.
- `gh pr create` failing with "Head sha can't be blank" usually means missing `--repo` flag (default upstream selection bug).
