#!/usr/bin/env zsh
set -euo pipefail

agentic_print_error() {
  print -u2 "agentic-config: $*"
}

agentic_require_command() {
  local command_name="$1"
  local label="$2"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    agentic_print_error "$label is required but was not found in PATH"
    return 1
  fi
}

agentic_warn_missing_command() {
  local command_name="$1"
  local label="$2"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    agentic_print_error "warning: $label was not found in PATH"
    return 1
  fi
}

agentic_workspace_slug() {
  local workspace="$1"
  local base
  local slug

  base="${workspace:t}"
  slug="$(print -r -- "$base" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"

  if [[ -z "$slug" ]]; then
    slug="workspace"
  fi

  print -r -- "$slug"
}

agentic_path_hash() {
  local workspace="$1"

  if command -v shasum >/dev/null 2>&1; then
    print -rn -- "$workspace" | shasum -a 1 | awk '{print substr($1, 1, 8)}'
    return
  fi

  print -rn -- "$workspace" | cksum | awk '{print $1}'
}

agentic_session_name() {
  local tool="$1"
  local workspace="$2"
  local slug
  local hash

  slug="$(agentic_workspace_slug "$workspace")"
  hash="$(agentic_path_hash "$workspace")"

  print -r -- "$tool-$slug-$hash"
}

agentic_shell_quote() {
  local value="$1"
  local quoted

  quoted="$(print -r -- "$value" | sed "s/'/'\\\\''/g")"
  print -r -- "'$quoted'"
}

agentic_validate_effort() {
  local effort="$1"

  case "$effort" in
    high|medium|low)
      return 0
      ;;
    *)
      agentic_print_error "unsupported effort level: $effort"
      return 1
      ;;
  esac
}

agentic_codex_pane_command() {
  local effort="$1"
  local workspace="$2"

  agentic_validate_effort "$effort"
  print -r -- "codex -c model_reasoning_effort=\\\"$effort\\\" -C $(agentic_shell_quote "$workspace")"
}

agentic_claude_pane_command() {
  local effort="$1"

  agentic_validate_effort "$effort"
  print -r -- "claude --effort $effort"
}

agentic_tmux_pane_command() {
  local command="$1"

  print -r -- "PATH=$(agentic_shell_quote "$PATH") $command"
}

agentic_configure_tmux_session_dx() {
  local session_name="$1"

  tmux set-option -t "$session_name" mouse on
}

agentic_configure_tmux_window_dx() {
  local window_target="$1"

  tmux set-window-option -t "$window_target" pane-border-status top
  tmux set-window-option -t "$window_target" pane-border-format " #{pane_index}: #{pane_title} "
}

agentic_set_effort_pane_title() {
  local pane_target="$1"
  local effort="$2"

  tmux select-pane -t "$pane_target" -T "$effort"
}

agentic_attach_or_switch() {
  local session_name="$1"

  if [[ -n "${TMUX:-}" ]]; then
    exec tmux switch-client -t "$session_name"
  fi

  exec tmux attach-session -t "$session_name"
}

agentic_create_tmux_session() {
  local session_name="$1"
  local workspace="$2"
  local high_command="$3"
  local medium_command="$4"
  local low_command="$5"
  local path_environment="PATH=$PATH"

  tmux new-session -d -s "$session_name" -n agents -c "$workspace" -e "$path_environment" "$(agentic_tmux_pane_command "$high_command")"
  agentic_configure_tmux_session_dx "$session_name"
  agentic_configure_tmux_window_dx "${session_name}:agents"
  agentic_set_effort_pane_title "${session_name}:agents.0" high

  tmux split-window -v -t "${session_name}:agents.0" -c "$workspace" -e "$path_environment" "$(agentic_tmux_pane_command "$medium_command")"
  agentic_set_effort_pane_title "${session_name}:agents.1" medium

  tmux split-window -v -t "${session_name}:agents.1" -c "$workspace" -e "$path_environment" "$(agentic_tmux_pane_command "$low_command")"
  agentic_set_effort_pane_title "${session_name}:agents.2" low

  tmux select-layout -t "${session_name}:agents" even-vertical
  tmux select-pane -t "${session_name}:agents.0"
}

agentic_launch_multi_effort_session() {
  local tool="$1"
  local workspace="$2"
  local session_name
  local high_command
  local medium_command
  local low_command

  agentic_require_command tmux "tmux"

  case "$tool" in
    codex)
      agentic_require_command codex "codex"
      high_command="$(agentic_codex_pane_command high "$workspace")"
      medium_command="$(agentic_codex_pane_command medium "$workspace")"
      low_command="$(agentic_codex_pane_command low "$workspace")"
      ;;
    claude)
      agentic_require_command claude "claude"
      high_command="$(agentic_claude_pane_command high)"
      medium_command="$(agentic_claude_pane_command medium)"
      low_command="$(agentic_claude_pane_command low)"
      ;;
    *)
      agentic_print_error "unsupported agent tool: $tool"
      return 1
      ;;
  esac

  session_name="$(agentic_session_name "$tool" "$workspace")"

  if ! tmux has-session -t "$session_name" 2>/dev/null; then
    agentic_create_tmux_session "$session_name" "$workspace" "$high_command" "$medium_command" "$low_command"
  fi

  agentic_attach_or_switch "$session_name"
}
