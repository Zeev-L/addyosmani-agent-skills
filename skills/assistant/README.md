# 📅 Assistant — Calendar & Task Manager

A Claude Code skill that turns scheduling into a collaborative act. Write rich, context-aware Google Calendar entries directly from conversations, manage a local task list, detect conflicts, and every entry links back to the exact conversation that created it.

---

## ✨ Why This Is Different

Most calendar tools take a title and time. This skill adds **context**.

When you schedule something in a conversation:

```
• Sync API keys with Marco before deploy
• Why: deploy is Friday 3pm, keys expire Thursday  
• How: Marco's calendar → book 30min Thursday morning
```

When the notification fires, you don't need to remember anything. The full context is right there.

---

## 🚀 Features

| Feature | What it does |
|---------|------------|
| 📅 **Google Calendar** | Real events — phone notifications, shared calendars, invites |
| 🔍 **Conflict detection** | Warns before double-booking, shows what's in the way |
| ⏱️ **Free slot finder** | Queries your actual schedule for open windows |
| 🎨 **Preference system** | "standups are always 15min bold_blue" — learns your defaults |
| 📋 **Task list** | Lightweight local tasks for timeless items |
| 👤 **User profile** | Work hours, preferred name, schedule style |
| 🔄 **Recurring events** | Full RRULE support for daily, weekly, monthly series |
| 🟡 **Prep blocks** | Optional: auto-insert a yellow prep block before meetings |
| 📦 **Bulk reschedule** | Move all events on a day in one command |
| 🗑️ **Delete** | Remove events cleanly with confirmation |
| ☀️ **Daily digest** | Shows today's events + tasks at session start |

---

## 📋 Quick Examples

### Follow-up you'd forget

> *"remind me to follow up with Marco about API keys next Thursday morning"*

Claude checks your calendar, matches the preference (15min, bold_blue), and creates an event with full context from this conversation. Thursday morning you get a reminder that includes everything you need to know.

### Deadline that actually reminds you

> *"don't let me forget — PR has to merge before Friday 5pm"*

Claude detects the conflict (you have a code review at 3:30), shows you the conflict, and creates a bold_red event with a 2-hour reminder. Friday at 3pm it pops up.

### Recurring standup, set once

> *"daily standup, 9:15am weekdays, 15 minutes"*

Claude saves the preference and creates a recurring series in Google Calendar. It learns from this that standups are 15min and bold_blue — next time you mention a standup, it uses those defaults.

### Deep work block

> *"need 2 hours for design doc this week — when am I free?"*

Claude checks your actual schedule and shows you the open windows. You pick Thursday 10am, it adds a 2-hour purple block called "Deep work: design doc".

### Meeting with optional prep

> *"1:1 with Sarah next Monday at 2pm, add 15 min prep"*

Claude asks if you want a prep block. You say yes. It creates the main event at 2pm and a yellow "Prep: 1:1 Sarah" at 1:45pm.

---

## 🔧 Setup

### First Time

```bash
python3 ~/.claude/skills/assistant/scripts/calendar.py setup
```

This opens OAuth flow, detects your timezone, and lets you pick which calendar to use.

### Personalize Your Preferences

```bash
python3 ~/.claude/skills/assistant/scripts/calendar.py profile --setup
```

Set your work hours, preferred name, and whether you're a morning or evening person.

---

## 📖 How It Works

When you mention scheduling, deadlines, follow-ups, or tasks:

1. **Check your schedule** — look for conflicts and find free time if needed
2. **Match preferences** — if you've set rules like "standups = 15min blue", use them
3. **Build context** — extract action items and relevant details from this conversation
4. **Show preview** — title, time, color, reminder duration, any conflicts
5. **Confirm** — you review and approve before anything gets added
6. **Link it** — every event gets the conversation session ID + transcript path

If something already exists (duplicate titles within 7 days), Claude asks if you want to reschedule the old one or add a new entry.

---

## 🎨 Colors

- **bold_red**: deadlines, launches, critical blockers
- **bold_blue**: meetings, calls, standups
- **bold_green**: milestones, wins
- **purple**: learning, deep work
- **yellow**: prep blocks (auto-set)
- **orange**: reviews, demos, presentations
- **turquoise**: personal (health, fitness)
- **green**: personal (social, fun)

---

## 📝 Task List vs Calendar

**Use Calendar for:**
- Anything with a specific time
- Things that need notifications
- Recurring habits to track

**Use Task List for:**
- "Remember to X" (no time)
- Shopping lists, errands
- Things without a deadline

---

## ⚙️ Commands

### Calendar

- `status` — show config + profile
- `list` — browse events
- `add` — create an event (with conflict detection)
- `delete` — remove an event
- `reschedule` — move event(s) or bulk-shift a day
- `free` — find open time slots
- `match` — look up preference defaults for a title
- `update-prefs` — save new preference rules
- `profile` — view or update work hours, name, schedule style

### Tasks

- `add` — create a task with optional priority and due date
- `list` — show all tasks
- `today` / `week` / `overdue` — filtered views
- `complete` — mark a task done
- `delete` — remove a task
- `category` — organize by category
- `summary` — overview of what's pending

Full details: see `SKILL.md`.

---

## 💾 Files

- `~/.claude/skills/assistant/config.json` — calendar ID, timezone
- `~/.claude/skills/assistant/preferences.json` — your event-type rules
- `~/.claude/skills/assistant/tasks.json` — local task list
- `~/.claude/skills/assistant/token.json` — Google OAuth token (do not commit)

---

## 🤔 Common Patterns

### Bulk reschedule (sick day)

> *"I'm sick tomorrow, move everything to Wednesday"*

```bash
reschedule --date "Tuesday" --shift "+1d"
```

### Quick free-time check

> *"when am I free Friday?"*

```bash
free --date "Friday" --duration 30
```

### Add to your preferences

> *"code reviews are always 30min orange"*

```bash
update-prefs --match "code review" --duration 30 --color orange
```

---

## 🐛 Troubleshooting

**"NOT SET UP" error?**
Run `calendar.py setup` and complete the OAuth flow.

**Calendar not selected?**
Run `calendar.py status` to see which calendar is active. If wrong, run `setup` again.

**Events outside work hours?**
Claude will warn before creating them. If you want to override: confirm `[y]` when prompted.

**Conflict detected but I want it anyway?**
Claude shows the conflict and asks for confirmation. Answer `y` to proceed.

**Prep block didn't show up?**
Prep blocks are optional — Claude asks if you want one. If the answer was "no", none will be added.

---

## 🎯 Philosophy

This skill is about **remembering context**, not just scheduling time.

Every reminder you get includes:
- What you're supposed to do
- Why it matters
- How to do it (links, people, resources)
- The exact conversation where you decided this

So when the notification fires, you can act immediately instead of hunting through your chat history.

---

## 📄 License

Built by [@googlarz](https://github.com/googlarz) for Claude Code.

---

## 🚦 Status

**v1.0** — Stable. Used daily for real scheduling. No maintenance commitment; contributions welcome.
