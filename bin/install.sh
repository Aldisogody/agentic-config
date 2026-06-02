#!/usr/bin/env zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
source "$repo_root/bin/lib/multi-effort-session.zsh"

zshrc="${ZDOTDIR:-$HOME}/.zshrc"
block_start="# BEGIN AGENTIC CONFIG MANAGED BLOCK"
block_end="# END AGENTIC CONFIG MANAGED BLOCK"
source_line="source \"$repo_root/shell.zsh\""

agentic_require_command tmux "tmux"
agentic_warn_missing_command codex "codex" || true
agentic_warn_missing_command claude "claude" || true

mkdir -p "$(dirname "$zshrc")"
touch "$zshrc"

tmp_file="$(mktemp)"

awk -v start="$block_start" -v end="$block_end" '
  $0 == start { skipping = 1; next }
  $0 == end { skipping = 0; next }
  skipping != 1 { print }
' "$zshrc" > "$tmp_file"

{
  cat "$tmp_file"
  print ""
  print "$block_start"
  print "$source_line"
  print "$block_end"
} > "$zshrc"

rm -f "$tmp_file"

print "Installed Agentic Config shell integration in $zshrc"
print "Open a new zsh terminal or run: source $(agentic_shell_quote "$repo_root/shell.zsh")"
