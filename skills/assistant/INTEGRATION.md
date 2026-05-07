# Integration Guide — Adding Assistant to agent-skills

This guide walks through adding the `/assistant` skill to your agent-skills fork.

---

## File Structure

```
agent-skills/skills/assistant/
├── SKILL.md                          # Skill definition + workflow
├── README.md                         # User-facing guide
├── preferences.json                  # Event-type pattern defaults
├── scripts/
│   ├── calendar.py                  # Main calendar CLI (1064 lines)
│   ├── tasks.py                     # Task list CLI (337 lines)
│   └── mcp_server.py                # Optional MCP wrapper (310 lines)
└── .gitignore                       # Ignore token.json + credentials.json
```

---

## Step-by-Step

### 1. Copy the skill into your fork

```bash
cd ~/Claude\ Code/Dev/agent-skills
mkdir -p skills/assistant/scripts
cp ~/claude-assistant/SKILL.md skills/assistant/
cp ~/claude-assistant/README.md skills/assistant/
cp ~/claude-assistant/preferences.json skills/assistant/
cp ~/claude-assistant/scripts/*.py skills/assistant/scripts/
cp ~/claude-assistant/.gitignore skills/assistant/
```

### 2. Verify the structure

```bash
ls -la skills/assistant/
```

Should show: `SKILL.md`, `README.md`, `preferences.json`, `scripts/`, `.gitignore`.

### 3. Add to skills index

Open `skills/index.json` (or wherever agent-skills catalogs available skills) and add:

```json
{
  "name": "assistant",
  "description": "Calendar and task management. Creates rich context-aware Google Calendar entries with conversation links, detects conflicts, respects work preferences.",
  "tags": ["productivity", "calendar", "tasks", "scheduling"],
  "author": "@googlarz",
  "status": "stable",
  "maintenance": "low"
}
```

### 4. Add to skill discovery (optional)

If agent-skills has a discovery mechanism or skill recommendations system, add keywords:

- Triggers: `schedule`, `calendar`, `meeting`, `remind`, `deadline`, `task`, `follow-up`
- Categories: `productivity`, `time-management`

### 5. Update README

Add a brief mention in the main agent-skills README:

```markdown
#### `/assistant` — Calendar & Task Manager

Create rich, context-aware Google Calendar entries from conversations. Every event links back to the transcript.

- Detect scheduling conflicts before booking
- Find free time slots
- Manage a local task list  
- Learn your preferences (recurring patterns)
- Optional prep blocks before meetings

See [`skills/assistant/README.md`](skills/assistant/README.md) for full docs and examples.
```

### 6. First-time setup for users

When a user invokes `/assistant` for the first time, Claude should guide them:

```
This skill needs OAuth access to your Google Calendar.

Run: python3 ~/.claude/skills/assistant/scripts/calendar.py setup

This will:
1. Open a browser for Google OAuth
2. Detect your timezone
3. Let you pick which calendar to use

After setup, customize your preferences:
python3 ~/.claude/skills/assistant/scripts/calendar.py profile --setup
```

---

## What's Included

### Python Scripts (~1700 lines total)

- **calendar.py**: Full CLI for calendar ops (setup, add, delete, list, free, reschedule, etc.)
- **tasks.py**: Lightweight task management (no external deps)
- **mcp_server.py**: Optional MCP wrapper (for future native tool access)

### Documentation

- **SKILL.md**: Complete workflow reference + command docs (copy-pasted from your current version, with features refined)
- **README.md**: User guide with examples and philosophy

### Config

- **preferences.json**: Event-type pattern matching (standup, deadline, 1:1, review, etc.)
- **.gitignore**: Excludes `token.json` and `credentials.json` (OAuth secrets)

---

## Testing Before Merge

### 1. Verify it works locally

```bash
/assistant
```

In a Claude Code conversation, invoke the skill. It should ask you to set up if you haven't already.

### 2. Run the setup

```bash
python3 ~/.claude/skills/assistant/scripts/calendar.py setup
```

Complete the OAuth flow and verify calendar selection.

### 3. Test a real event

Try creating an event from a conversation:

> *"remind me to review the design doc next Monday at 2pm"*

Claude should:
1. Check your calendar
2. Show a preview
3. Ask for confirmation
4. Create the event with a transcript link

### 4. Verify the transcript link

The event description should include a path like:

```
📄  Transcript: ~/.claude/projects/.../f1936594.jsonl
```

Open that file — it should be the actual conversation JSONL.

---

## Minimal Deps

The scripts require:
- Python 3.8+
- `google-auth-oauthlib` (pip install, OAuth flow)
- `google-auth-httplib2` (pip install, Google API client)
- `google-api-python-client` (pip install)
- Standard library (json, argparse, datetime, pathlib)

**No external dependencies** for the task list — it's pure local JSON.

Setup script can prompt users to `pip install` if deps are missing.

---

## Known Limitations

- **No attendee support**: Events can't invite others (feature cut for v1.0)
- **No search**: Can't search by keyword (feature cut for v1.0)
- **Prep blocks are optional**: User decides per event
- **Local task list only**: No sync across devices
- **No email invites**: For multi-person events, user needs to share calendar link separately

These are intentional cuts to ship v1.0 focused. Can add in future iterations based on feedback.

---

## Future Iterations

Potential improvements (not in v1.0):

1. **Attendee support** — allow inviting others, with explicit confirmation
2. **Search** — full-text search across past/future events
3. **Cloud task sync** — sync task list across devices
4. **Notification customization** — change reminder types per event
5. **MCP native integration** — replace shell-outs with native tool calls

---

## Support & Maintenance

- **Status**: Stable, used daily for real scheduling
- **Maintenance**: No commitment; contributions welcome
- **Issues**: Post to agent-skills issues; tag with `@assistant`
- **Roadmap**: Driven by feedback

---

## Quick Checklist

- [ ] Copy files to `skills/assistant/`
- [ ] Add to skills index
- [ ] Update main README with skill mention
- [ ] Test setup + OAuth flow
- [ ] Test creating an event
- [ ] Verify transcript linking
- [ ] Commit + PR with message: "Add /assistant — Calendar & Task Manager skill"
