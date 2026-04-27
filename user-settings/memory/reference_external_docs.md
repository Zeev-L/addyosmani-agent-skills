---
name: reference_external_docs
description: Authoritative external references — Claude Code docs, AGENTS.md spec, GitHub Spec Kit, Notion KB workflow
type: reference
---

# External documentation references

## Claude Code (Anthropic, official)

- **Memory system + `@<path>` imports:** https://code.claude.com/docs/en/memory.md (covers the `@<filepath>` directive, recursion limit of 5 hops, approval dialog on first use, no `${CLAUDE_PLUGIN_ROOT}` expansion in CLAUDE.md)
- **Hooks reference:** https://code.claude.com/docs/en/hooks.md (PreToolUse output schema with `hookSpecificOutput.permissionDecision`, exit-code 2 alternative, `agent_id` + `hook_event_name` in stdin JSON for subagent detection, plugin-level vs user-level placement)
- **Permissions reference:** https://code.claude.com/docs/en/permissions.md (Read/Edit allow/deny syntax, no per-caller distinction — that's why the Rule #0 enforcement is a hook, not a permissions rule)
- **Best practices:** https://www.anthropic.com/engineering/claude-code-best-practices (subagent usage, context budget < 50%, nested CLAUDE.md, run_in_background)
- **Sub-agents reference:** https://docs.anthropic.com/en/docs/claude-code/sub-agents

Claude Code version we standardize on: **2.1.119** (verified 2026-04-26 via `claude --version`). Ship-time guarantees may differ in earlier 1.x or future 2.x.

## AGENTS.md cross-tool standard

- **Spec:** https://agents.md (open standard for AI-coding-agent rules across tools — adopted by Codex CLI, Cursor as complement, Aider via `read:`, Gemini CLI, OpenCode, Windsurf; Claude Code reads it as fallback if no `CLAUDE.md`)

## GitHub Spec Kit (formalizes spec-driven development)

- **Repo:** https://github.com/github/spec-kit (PRD/SPEC/Plan/Tasks separation, slash commands `/specify` `/plan` `/tasks`)

## Aider conventions

- **`.aider.conf.yml`:** https://aider.chat/docs/usage/conventions.html (`read:` directive to pre-load files at session start, including `AGENTS.md`)

## Notion KB workflow (operator's external memory)

The `notion-kb-workflow` skill in `batuta-agent-skills` operates against the operator's Notion workspace. Three modes:

- `--read client:X project:Y` at session start on existing project
- `--init client:X project:Y` for new project
- `--append` at end of productive session

The skill's MCP integration is configured via `~/.claude/mcp.json` (notion server). When in doubt about state across machines, Notion is the durable source.

## When to consult these

- Implementing a hook → check `hooks.md` for current schema (it has changed across versions; never trust legacy `decision: block` shape without re-reading)
- Writing a CLAUDE.md `@<path>` import → check `memory.md` for path resolution rules
- Cross-tool work → check `agents.md` standard if a non-Claude-Code tool is in scope
- Adopting a new pattern → check Anthropic best-practices post for current guidance
