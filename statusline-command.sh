#!/bin/sh
# Claude Code status line - inspired by robbyrussell oh-my-zsh theme

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
dir=$(basename "$cwd")
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Git branch info (skip optional locks)
git_branch=""
if git_branch_raw=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_dirty=""
  if ! GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --quiet 2>/dev/null || ! GIT_OPTIONAL_LOCKS=0 git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    git_dirty=" \033[33m✗\033[0m"
  fi
  git_branch=" \033[1;34mgit:(\033[31m${git_branch_raw}\033[1;34m)${git_dirty}\033[0m"
fi

# Context usage
ctx_info=""
if [ -n "$used" ]; then
  ctx_info=" \033[2m[ctx: ${used}%]\033[0m"
fi

# Model info
model_info=""
if [ -n "$model" ]; then
  model_info=" \033[2m${model}\033[0m"
fi

printf "\033[1;32m➜\033[0m  \033[36m%s\033[0m%s%s%s" "$dir" "$git_branch" "$model_info" "$ctx_info"
