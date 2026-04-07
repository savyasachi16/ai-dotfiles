---
name: Git default branch should be main
description: Always use main as the default branch, never master
type: feedback
---

Always use `main` as the default git branch, not `master`.

**Why:** User preference — explicitly corrected when master was used.

**How to apply:** When initializing a git repo, rename immediately with `git branch -m master main` before any other operations, or configure git to default to main.
