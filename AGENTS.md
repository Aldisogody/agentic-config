# Repository Guidelines

## Project Structure & Module Organization

This repository provides global shell launch commands for multi-effort agent sessions in tmux. Top-level entrypoints live in `bin/`: `oc` launches Codex panes and `ot` launches Claude panes. Shared zsh logic is in `bin/lib/multi-effort-session.zsh`; keep reusable behavior there instead of duplicating it. `shell.zsh` adds `bin/` to `PATH`, and `bin/install.sh` writes the managed block to the user's zsh startup file. Tests live in `tests/run.sh`. Product language is documented in `CONTEXT.md`; plans and specs live under `docs/`.

## Build, Test, and Development Commands

- `zsh tests/run.sh`: runs the shell test suite for helper functions, launchers, and installer behavior.
- `zsh -n bin/install.sh bin/oc bin/ot bin/lib/multi-effort-session.zsh tests/run.sh shell.zsh`: syntax-checks all zsh scripts.
- `bin/install.sh`: installs shell integration by updating the managed block in `~/.zshrc`.
- `source shell.zsh`: loads local launch commands into the current shell without reinstalling.
- `oc` / `ot`: from any workspace directory, open or attach to the Codex or Claude multi-effort tmux session.

## Coding Style & Naming Conventions

Use zsh with `#!/usr/bin/env zsh` and `set -euo pipefail` for executable scripts. Indent with two spaces. Keep helper functions prefixed with `agentic_`, for example `agentic_session_name`, and use descriptive local names. Prefer `print -r --` for literal output and quote paths with existing helpers such as `agentic_shell_quote`. Avoid terminology that conflicts with `CONTEXT.md`.

## Testing Guidelines

Add focused tests to `tests/run.sh` for new helper behavior and launcher contracts. Use the existing assertion helpers (`assert_eq`, `assert_success`, `assert_failure`) and test function names like `test_session_name_includes_tool_and_hash`. Run both the test suite and zsh syntax check before handing off changes. For tmux behavior, follow the fake-command manual verification flow in `README.md` so real Codex or Claude sessions are not launched unnecessarily.

## Commit & Pull Request Guidelines

Git history uses Conventional Commit prefixes such as `feat:`, `fix:`, `test:`, and `docs:`. Keep commit subjects concise and imperative, for example `fix: align launcher tmux behavior`. Pull requests should describe the behavior change, list verification commands run, reference related docs or specs, and include terminal screenshots only when tmux layout or installer output changes.

## Security & Configuration Tips

Do not hard-code user-specific home paths except where installer behavior targets `${ZDOTDIR:-$HOME}/.zshrc`. Preserve the managed block markers in `bin/install.sh` so reinstalling remains idempotent. Treat `tmux` as required; `codex` and `claude` may be absent during install but must exist for their launch commands.
