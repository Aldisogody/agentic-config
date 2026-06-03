# Agentic Config

Global Agent Launch Commands for opening Multi-Effort Sessions in tmux.

## Install

```bash
bin/install.sh
```

The installer requires `tmux`, warns when `codex` or `claude` are missing, and adds a managed block to `~/.zshrc` that sources `shell.zsh`.

Open a new zsh terminal after install, or run:

```bash
source shell.zsh
```

## Commands

Run from the Workspace Directory you want all panes to use:

```bash
oc
ot
```

`oc` opens or attaches to a Codex Workspace Session with:

```zsh
codex -c model_reasoning_effort=\"high\" -C "$workspace"
codex -c model_reasoning_effort=\"medium\" -C "$workspace"
codex -c model_reasoning_effort=\"low\" -C "$workspace"
```

`ot` opens or attaches to a Claude Workspace Session with:

```zsh
claude --effort high
claude --effort medium
claude --effort low
```

Each session has one tmux window with three vertically stacked panes ordered high, medium, low. Re-running a command from the same Workspace Directory attaches to the existing Workspace Session. Running from inside tmux switches the current tmux client instead of nesting tmux.

The panes are labeled by effort level and show the current directory, Git branch, and local working tree changes:

```text
0: high | agentic-config | main | M2 A1 ?1
```

Clean Git worktrees show `clean`:

```text
0: high | agentic-config | main | clean
```

Non-Git directories show only the directory name. Git information refreshes through tmux without wrapping or modifying the Agent Tool processes.

Click a pane to focus it, or use tmux keyboard navigation:

```text
Ctrl-b Up
Ctrl-b Down
```

Detach with:

```text
Ctrl-b d
```

## Tests

```bash
zsh tests/run.sh
zsh -n bin/install.sh bin/oc bin/ot bin/agentic-pane-git-segment bin/lib/multi-effort-session.zsh tests/run.sh shell.zsh
```

## Manual Verification

Use fake Agent Tool commands to verify tmux behavior without launching real agents:

```bash
tmp_bin="$(mktemp -d)"
tmp_project="$(mktemp -d)"
cat > "$tmp_bin/codex" <<'EOF'
#!/usr/bin/env zsh
print "codex $*"
exec zsh
EOF
cat > "$tmp_bin/claude" <<'EOF'
#!/usr/bin/env zsh
print "claude $*"
exec zsh
EOF
chmod +x "$tmp_bin/codex" "$tmp_bin/claude"
cd "$tmp_project"
PATH="$tmp_bin:$PATH" /absolute/path/to/agentic-config/bin/oc
```

Confirm each pane border shows the directory name, Git branch, and `clean`. Create or modify a file and confirm the Git change counts appear. Detach with `Ctrl-b d`, then re-run the same command and confirm it attaches to the existing session. Repeat with `ot`.

Clean up:

```bash
tmux kill-session -t "$(PATH="$tmp_bin:$PATH" zsh -c 'source /absolute/path/to/agentic-config/bin/lib/multi-effort-session.zsh; agentic_session_name codex "'"$tmp_project"'"')" 2>/dev/null || true
tmux kill-session -t "$(PATH="$tmp_bin:$PATH" zsh -c 'source /absolute/path/to/agentic-config/bin/lib/multi-effort-session.zsh; agentic_session_name claude "'"$tmp_project"'"')" 2>/dev/null || true
rm -rf "$tmp_bin" "$tmp_project"
```
