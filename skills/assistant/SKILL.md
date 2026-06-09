---
name: assistant
description: >
  Calendar and task management skill. Invoke when scheduling, reminders, follow-ups,
  deadlines, meetings, or tasks arise. Creates rich context-aware Google Calendar
  entries with conversation links, manages a local task list, detects conflicts,
  respects work preferences, and optionally inserts prep blocks.
---

# Assistant — Calendar & Task Manager

> **Invoke with `/assistant`** — Automatically triggered when the user mentions scheduling,
> follow-ups, reminders, deadlines, meetings, tasks, or asks to "remember" something.

---

## What This Skill Does

Transforms Claude into a proactive personal assistant that:
- Writes **rich, context-aware entries** directly to Google Calendar
- Maintains a **local task list** for timeless items
- Detects **scheduling conflicts** before committing
- Respects the user's **work hours and preferences**
- Links every calendar entry back to the **exact conversation transcript**
- **Optionally adds prep blocks** when appropriate (user decides per event)

---

## Session Start — Daily Digest

At the beginning of each Claude Code session, the SessionStart hook shows:

```
📅 Week ahead:              ← on Monday
   or
   Today:                   ← other days
```

This gives the user context before they start work.

---

## Workflow — Step by Step

### Step 0 — Verify setup

```bash
python3 ~/.claude/skills/assistant/scripts/calendar.py status
```

- If output is `NOT SET UP`, run `setup` and pause until user completes it
- If profile is missing, suggest: *"Run `calendar.py profile --setup` to personalize your preferences"*

---

### Step 1 — Check for conflicts and find free time

Before adding anything, run both checks in parallel:

```bash
# Check what's already there
python3 ~/.claude/skills/assistant/scripts/calendar.py list --days-back 0 --days-ahead 7

# Check for free slots if user needs scheduling help
python3 ~/.claude/skills/assistant/scripts/calendar.py free --date "this week" --duration 60
```

If an event with the same title already exists in the next 7 days, **ask the user** whether to
reschedule it or add a new entry.

---

### Step 2 — Match preferences

```bash
python3 ~/.claude/skills/assistant/scripts/calendar.py match --title "TITLE" --description "DESCRIPTION"
```

Returns JSON with `duration_minutes`, `color`, `reminder_minutes`, `matched`.
Use these as defaults — the user's preferences are suggestions, not overrides.

---

### Step 3 — Resolve the time

- If the user gave a specific time → use it directly
- If vague ("tomorrow afternoon", "end of week") → resolve to concrete ISO datetime
- If no time given → ask: *"What time should I book this for?"*
- Use natural language: `"tomorrow 3pm"`, `"next Monday 10am"`, `"Friday EOD"`

**Never assume a time the user didn't provide.**

---

### Step 4 — Build a rich description

Every calendar entry needs context so the user knows what to do when notified:

```
[2-3 bullet points: what was decided / what needs to happen]
• What:  [specific action or topic]
• Why:   [why this matters / impact if missed]
• How:   [relevant links, files, people, or steps]

────────────────────────────────────────────────
📁  /path/to/current/project
🔗  Session: [CLAUDE_SESSION_ID]
📄  Transcript: ~/.claude/projects/.../.jsonl
🕐  Added: YYYY-MM-DD HH:MM UTC
```

The `build_description()` function handles the footer — you only write the bullets.

---

### Step 5 — Optional: Add a prep block

If appropriate (meetings, calls, deep work before a deadline), ask:

> *"Should I add a 15-minute prep block before this?"*

Only add if user confirms. If yes:

```bash
--prep-minutes 15
```

This creates a yellow "Prep: [event]" block before the main event.

---

### Step 6 — Add the event (with preview)

```bash
python3 ~/.claude/skills/assistant/scripts/calendar.py add \
  --title "TITLE" \
  --start "YYYY-MM-DDTHH:MM:SS" \
  --end   "YYYY-MM-DDTHH:MM:SS" \
  --description "bullet points here" \
  [--prep-minutes 15] \
  [--recurrence "RRULE:FREQ=WEEKLY;BYDAY=MO"]
```

The script will:
1. Warn if outside work hours (from profile)
2. Show conflicts if any exist
3. Display a confirmation preview
4. Ask **Y/n** before writing

Use `--yes` / `-y` only when the user has already confirmed in the chat.

---

## All Commands — Quick Reference

### Calendar Commands

| Command | Purpose | Key flags |
|---------|---------|-----------|
| `setup` | First-time OAuth + calendar selection | — |
| `status` | Show config + profile | — |
| `list` | Browse events | `--days-back N` `--days-ahead N` `--digest` |
| `match` | Get preference for a title | `--title` `--description` |
| `add` | Create an event | `--title` `--start` `--end` `--description` `--prep-minutes` `--recurrence` `--yes` |
| `delete` | Remove an event | `--title` `--yes` |
| `reschedule` | Move event(s) | `--title` `--shift` `--new-start` OR `--date` `--shift` (bulk) |
| `free` | Find open slots | `--date` `--duration N` `--days N` |
| `profile` | View / set work hours, name, style | `--setup` `--work-start` `--work-end` `--style` |
| `update-prefs` | Add / change preference rules | `--match` `--duration` `--color` `--reminder` `--recurrence` |

### Task Commands

```bash
TASKS="python3 ~/.claude/skills/assistant/scripts/tasks.py"

$TASKS add "TITLE" [--priority high|medium|low] [--due YYYY-MM-DD] [--category work]
$TASKS list
$TASKS today
$TASKS week
$TASKS overdue
$TASKS complete "title or id"
$TASKS delete  "title or id"
$TASKS category [name]
$TASKS summary
```

---

## Calendar vs Task — Decision Guide

| Situation | Use Calendar | Use Task |
|-----------|-------------|----------|
| Has a specific time | ✅ | — |
| Needs phone/desktop notification | ✅ | — |
| Involves other people (invite) | — | ✅ (email them separately) |
| "Remember to do X" (no time) | — | ✅ |
| Recurring habit to track | ✅ | — |
| Shopping / errand list | — | ✅ |
| Deadline with a due date | ✅ | — |

When in doubt: **calendar** for time-anchored things, **task** for everything else.

---

## Color Guide

| Color | Use for |
|-------|---------|
| `bold_red` (11) | Deadlines, launches, critical blockers |
| `bold_blue` (9) | Meetings, calls, standups |
| `bold_green` (10) | Milestones, completions, wins |
| `red` (4) | Urgent reminders |
| `orange` (6) | Reviews, demos, presentations |
| `purple` (3) | Learning, courses, deep work |
| `yellow` (5) | Prep blocks (auto-set) |
| `turquoise` (7) | Personal: health, fitness |
| `green` (2) | Personal: social, fun |
| `blue` (1) | Flexible / low priority |

---

## Title Format

Good titles are **scannable in a notification**:

| ✅ Good | ❌ Avoid |
|--------|---------|
| `Follow up: Marco — API keys` | `Follow up with Marco about the API keys` |
| `Deadline: v2.1 release` | `v2.1 needs to ship` |
| `Review: PR #204 auth refactor` | `Look at the PR` |
| `Prep: Investor call @ 2pm` | `Prepare for the investor call` |
| `1:1 Sarah — Q1 goals` | `Meeting with Sarah` |

Pattern: `[Type]: [Subject] — [Key detail]`

---

## Recurring Events

Use RRULE strings:

```
RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR     ← every weekday
RRULE:FREQ=WEEKLY;BYDAY=MO                  ← every Monday
RRULE:FREQ=MONTHLY;BYDAY=1MO               ← first Monday every month
RRULE:FREQ=DAILY;COUNT=10                  ← 10 times then stop
```

---

## Conflict Handling

When `add` detects a conflict:

```
⚠️  Time conflict — 2 existing event(s):
   • Daily standup  2026-03-01 09:00
   • Team sync      2026-03-01 09:15

Schedule anyway? [y/N]:
```

- If user says yes → pass `--yes` and proceed
- If user says no → offer to find free time: `free --date "today" --duration 30`

---

## Bulk Reschedule

Move all events on a given day:

```bash
python3 ~/.claude/skills/assistant/scripts/calendar.py reschedule \
  --date "Tuesday" \
  --shift "+1d"
```

Useful: *"I'm sick tomorrow, move everything to Wednesday."*

---

## 5 Sample Use Cases

### 1 — Mid-conversation follow-up

**User says:** *"remind me to send the invoice to client X next Tuesday"*

1. `status` → OK
2. `match --title "Invoice: Client X"` → 30min, bold_blue, 10min reminder
3. Resolve "next Tuesday" → `2026-03-10T09:00:00`
4. `add --title "Invoice: Client X — send" --start "2026-03-10T09:00" --end "2026-03-10T09:15" --description "• Send invoice for March work\n• Client: X\n• Check outstanding items first"`
5. Preview → user confirms → event created with transcript link

---

### 2 — Deadline with conflict detection

**User says:** *"PR needs to merge by Friday 5pm"*

1. `match --title "Deadline: PR merge"` → bold_red, 120min reminder
2. `add` → conflict: *"Retro @ 16:00 Friday"*
3. Show conflict, ask user
4. User: *"fine, add it"* → `add --yes`
5. Event added with bold_red + 2hr popup reminder

---

### 3 — Recurring standup

**User says:** *"daily standup, 9:15am weekdays, 15 minutes"*

1. `update-prefs --match "standup" --duration 15 --recurrence "RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"`
2. `add --title "Daily Standup" --start "2026-03-02T09:15:00" --end "2026-03-02T09:30:00" --recurrence "RRULE:FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR"`
3. One command creates full recurring series

---

### 4 — Find free time + deep work

**User says:** *"need 2 hours for design doc this week — when am I free?"*

1. `free --date "this week" --duration 120`
2. Output: *"Thu: 10:00–12:00, Fri: 14:00–17:00"*
3. User picks Thursday 10am
4. `add --title "Deep work: design doc" --start "2026-03-05T10:00" --end "2026-03-05T12:00" --color "purple"`

---

### 5 — Meeting with optional prep

**User says:** *"1:1 with Sarah next Monday at 2pm, add 15 min prep"*

1. `match --title "1:1 Sarah"` → 45min, bold_blue
2. Conflict check → clear
3. User confirms prep block
4. `add --title "1:1 Sarah — weekly sync" --start "2026-03-09T14:00" --end "2026-03-09T14:45" --prep-minutes 15`
5. Main event + "Prep: 1:1 Sarah" at 13:45 both created

---

## File Locations

| File | Purpose |
|------|---------|
| `~/.claude/skills/assistant/config.json` | Calendar ID, timezone, profile |
| `~/.claude/skills/assistant/preferences.json` | Event-type rules (duration, color, reminder) |
| `~/.claude/skills/assistant/tasks.json` | Local task list |
| `~/.claude/skills/assistant/token.json` | Google OAuth token (do not commit) |
| `~/.claude/skills/assistant/credentials.json` | Google API credentials (do not commit) |
