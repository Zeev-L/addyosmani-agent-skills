---
name: notion-kb-workflow
description: Use at session boundaries to sync context with a Notion knowledge base. Three modes - read prior context on start, initialize client+project pages, append session decisions on close.
---

# Notion KB Workflow

## Overview

**The context window is not your memory.** Session-to-session continuity requires a durable store outside the agent. This skill treats Notion (via the official Notion MCP plugin) as that store, with three explicit modes so the agent does not contaminate its working context with raw page dumps.

Prerequisite: the Notion MCP plugin must be installed and authenticated:

```
/plugin install notion
```

All modes are invoked manually. There is no Stop hook. The intent is for the operator to decide when state is worth persisting, not for every tool call to leak into Notion.

## When to Use

Invoke one of three modes at session boundaries:

| Mode | When | Command |
|---|---|---|
| `--read` | Start of a session on an existing project | `/skill notion-kb-workflow --read client:<X> project:<Y>` |
| `--init` | Start of a brand-new project not yet in Notion | `/skill notion-kb-workflow --init client:<X> project:<Y>` |
| `--append` | End of a productive session (made commits, took decisions) | `/skill notion-kb-workflow --append` |

Do NOT use for:
- Reading individual Notion pages for reference (use the Notion MCP directly)
- Storing secrets or credentials (Notion is not a secrets store)

## Process

### Mode: `--read`

Input: `client:<name>`, `project:<name>`.

Steps:
1. Query Notion for the client page by name. If absent, stop and prompt the operator to run `--init` or correct the name.
2. Query the project page nested under the client page.
3. Fetch the latest 5 session appends (ordered by date descending).
4. Fetch the active sprint page (status = In Progress).
5. Fetch open tasks assigned to the project.
6. Emit a **structured summary** into the chat, not raw page content:
   ```
   PROJECT CONTEXT (from Notion KB)
   Stack: <from project page>
   Active sprint: <sprint name, end date>
   Pending tasks: <count, titles>
   Recent decisions: <bulleted, max 5>
   Known gotchas: <bulleted, max 5>
   ```
7. Stop. Wait for the operator to direct next actions.

Do NOT dump raw page JSON or full block content. The goal is context priming, not context flooding.

### Mode: `--init`

Input: `client:<name>`, `project:<name>`, optional `stack:<stack>`.

Steps:
1. Confirm with the operator the client and project names before writing anything.
2. Check if the client page exists. If yes, re-use. If no, create under the Notion root "Clients" database with properties: Name, Status (Active), Created.
3. Create the project page nested under the client page with properties: Name, Stack, Status (Planning), Created.
4. Create linked databases under the project page:
   - Sprints (Name, Start, End, Status)
   - Tasks (Title, Status, Sprint, Assignee)
   - Decisions (Title, Date, Rationale)
   - Gotchas (Title, Context, Workaround)
5. Emit confirmation with the project page URL.

Do NOT proceed to code until this returns.

### Mode: `--append`

Input: none (reads session state).

Steps:
1. Read `git log --oneline -n 20` in the current project. If no new commits since the last append, ask the operator to confirm an append is warranted.
2. Read `git diff --stat <last-append-sha>..HEAD`.
3. Infer and draft the following block:
   ```
   Session: <YYYY-MM-DD HH:MM>
   Commits: <sha list with subjects>
   Files touched: <counts by top-level dir>
   Libraries added / bumped: <name@version>
   Decisions: <bulleted>
   Gotchas: <bulleted>
   Next step: <one line>
   ```
4. Show the draft to the operator. Wait for approval.
5. On approval, append to the project page as a new block. Move tasks to "Done" if their IDs appear in commit subjects.

Do NOT auto-commit to Notion without operator approval.

## Anti-Rationalizations

| Excuse | Reality |
|---|---|
| "I'll remember the decisions without writing them down" | You won't. Next session starts with 0 recall. |
| "Notion read is slow, I'll skip `--read`" | Skipping = restarting every session blind. The slowness is one-time. |
| "I can auto-append via a Stop hook" | Hooks run on every stop, including interrupted sessions. Manual gate is the design. |
| "The summary is too terse, let me paste the full page" | Terse is the point. Context is scarce. |

## Red Flags

- Invoking `--read` without `client:` and `project:` args
- Creating client or project page before confirming name with operator
- Dumping raw Notion JSON into the chat
- Appending a session with 0 commits and no declared decisions
- Using `--init` when `--read` already returns a page (duplicate pages)

## Verification

For each mode:

**`--read`**:
- Output is the structured block above, not raw page content
- Summary line count ≤ 20

**`--init`**:
- Notion page URL is emitted and fetchable
- Operator confirmed names before the write occurred

**`--append`**:
- Draft shown to operator and approved before write
- Notion append block contains all 7 fields
- Tasks referenced in commit subjects are transitioned to Done

Evidence command after `--append`:
```
git log --format='%H' -n 1 > .notion-last-append.sha
```
Commit this file so the next `--append` knows where to diff from.
