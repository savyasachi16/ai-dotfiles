# claude-dotfiles

Cross-machine Claude Code (`~/.claude/`) configuration for Mac and Linux.

## What's managed

| File/Dir | Method | Notes |
|---|---|---|
| `settings.json` | Copied from `.tpl` | Symlink causes Claude Code bug [#764](https://github.com/anthropics/claude-code/issues/764)/[#3575](https://github.com/anthropics/claude-code/issues/3575) |
| `statusline-command.sh` | Symlinked | oh-my-zsh-inspired statusbar |
| `CLAUDE.md` | Symlinked | Global instructions for every session |
| `commands/` | Symlinked (whole dir) | Custom slash commands |
| `skills/` | Symlinked (whole dir) | Custom skills |
| `hooks/` | Symlinked (whole dir) | Lifecycle hooks |

## New machine setup

```bash
git clone git@github.com:savya/claude-dotfiles.git ~/projects/claude-dotfiles
cd ~/projects/claude-dotfiles
bash setup.sh
```

`setup.sh` is idempotent — safe to run again after pulling updates.

## Adding new slash commands / skills / hooks

Files added inside `commands/`, `skills/`, or `hooks/` are live immediately on
the current machine (dirs are symlinked). Commit and push to sync to other machines.

## What's NOT tracked

| Excluded | Reason |
|---|---|
| `history.jsonl`, `backups/`, `cache/`, `todos/` | Runtime/ephemeral state |
| `projects/`, `shell-snapshots/`, `statsig/` | Runtime/ephemeral state |
| `policy-limits.json` | Machine-specific security policy |
| `plugins/` | Marketplace downloads + personal blocklist entries |
| `settings.json` | Machine-specific copy generated from `settings.json.tpl` |

## Desktop app (claude_desktop_config.json)

`~/Library/Application Support/Claude/claude_desktop_config.json` (Mac) or
`~/.config/Claude/claude_desktop_config.json` (Linux) contains MCP server configs.
It is not tracked here because it often embeds absolute paths to local binaries
and is mixed with OAuth token cache in the same directory.

To add it in the future, use the same `@@CLAUDE_DIR@@`-style template approach.

## settings.json template

`settings.json.tpl` uses `@@CLAUDE_DIR@@` as a placeholder for `$HOME/.claude`.
`setup.sh` substitutes the correct absolute path on each machine using `sed`.
