# ai-dotfiles

Cross-machine AI agent configuration for Mac and Linux.

## Agents supported

| Agent | Config location | Instructions |
|-------|---------------|--------------|
| Claude Code | `~/.claude/` | `CLAUDE.md` |
| OpenCode | `~/.config/opencode/` | `OPENCODE.md` |

## Claude Code

| File/Dir | Method | Notes |
|---|---|---|
| `settings.json` | Copied from `.tpl` | Symlink causes Claude Code bug [#764](https://github.com/anthropics/claude-code/issues/764)/[#3575](https://github.com/anthropics/claude-code/issues/764) |
| `statusline-command.sh` | Symlinked | oh-my-zsh-inspired statusbar |
| `CLAUDE.md` | Symlinked | Global instructions |
| `commands/`, `skills/`, `hooks/` | Symlinked (whole dir) | Custom slash commands, skills, hooks |

## OpenCode

| File/Dir | Method | Notes |
|---|---|---|
| `opencode.json` | Copied from `.tpl` | Settings |
| `OPENCODE.md` | Symlinked | Global instructions |
| `commands/`, `skills/` | Symlinked (whole dir) | Custom slash commands, skills |

## New machine setup

```bash
git clone git@github.com:savya/ai-dotfiles.git ~/projects/ai-dotfiles
cd ~/projects/ai-dotfiles
bash setup.sh
```

`setup.sh` is idempotent — safe to run again after pulling updates.

## Adding new slash commands / skills

Files added inside `commands/` or `skills/` are live immediately on
the current machine (dirs are symlinked). Commit and push to sync to other machines.

## What's NOT tracked

Claude Code:

| Excluded | Reason |
|---|---|
| `history.jsonl`, `backups/`, `cache/`, `todos/` | Runtime/ephemeral state |
| `projects/`, `shell-snapshots/`, `statsig/` | Runtime/ephemeral state |
| `policy-limits.json` | Machine-specific security policy |
| `plugins/` | Marketplace downloads + personal blocklist entries |
| `settings.json` | Machine-specific copy generated from `settings.json.tpl` |

OpenCode:

| Excluded | Reason |
|---|---|
| `agents/`, `modes/`, `plugins/`, `tools/`, `themes/` | Runtime/ephemeral state |
| `file-history/`, `sessions/`, `tasks/`, `telemetry/` | Runtime/ephemeral state |

## Desktop app configs

Claude: `~/Library/Application Support/Claude/claude_desktop_config.json` (Mac) or
`~/.config/Claude/claude_desktop_config.json` (Linux) contains MCP server configs.

OpenCode: `~/Library/Application Support/opencode/` (Mac) or
`~/.config/opencode/` (Linux) contains MCP server configs.

Neither is tracked here because they often embed absolute paths to local binaries
and OAuth tokens.

## Templates

Templates use `@@OPENCODE_DIR@@` as a placeholder for `~/.config/opencode`.
`setup.sh` substitutes the correct absolute path on each machine using `sed`.
