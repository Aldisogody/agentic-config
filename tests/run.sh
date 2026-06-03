#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source "$repo_root/bin/lib/multi-effort-session.zsh"

failures=0

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$actual" != "$expected" ]]; then
    print -u2 "FAIL: $message"
    print -u2 "  expected: $expected"
    print -u2 "  actual:   $actual"
    failures=$((failures + 1))
  else
    print "PASS: $message"
  fi
}

assert_success() {
  local message="$1"
  shift

  if "$@"; then
    print "PASS: $message"
  else
    print -u2 "FAIL: $message"
    failures=$((failures + 1))
  fi
}

assert_failure() {
  local message="$1"
  shift

  if "$@"; then
    print -u2 "FAIL: $message"
    failures=$((failures + 1))
  else
    print "PASS: $message"
  fi
}

assert_eval_success() {
  local message="$1"
  local expression="$2"

  if eval "$expression"; then
    print "PASS: $message"
  else
    print -u2 "FAIL: $message"
    failures=$((failures + 1))
  fi
}

assert_eval_failure() {
  local message="$1"
  local expression="$2"

  if eval "$expression"; then
    print -u2 "FAIL: $message"
    failures=$((failures + 1))
  else
    print "PASS: $message"
  fi
}

test_session_basename_slug() {
  assert_eq "agentic-config" "$(agentic_workspace_slug "/Users/example/work/agentic-config")" "uses workspace basename for simple paths"
}

test_session_slug_sanitizes_characters() {
  assert_eq "my-app-v2" "$(agentic_workspace_slug "/Users/example/My App v2!")" "sanitizes basename for tmux session names"
}

test_session_slug_handles_root() {
  assert_eq "workspace" "$(agentic_workspace_slug "/")" "uses fallback slug for root"
}

test_session_name_includes_tool_and_hash() {
  local first
  local second

  first="$(agentic_session_name "codex" "/tmp/project")"
  second="$(agentic_session_name "codex" "/var/project")"

  assert_eval_success "session name contains tool and slug" '[[ "$first" == codex-project-* ]]'
  assert_eval_failure "session names avoid same-basename collisions" '[[ "$first" == "$second" ]]'
}

test_missing_command_check() {
  assert_success "finds zsh command" agentic_require_command zsh "zsh"
  assert_failure "fails for missing command" agentic_require_command "__agentic_missing_command__" "missing test command"
}

test_quote_command() {
  assert_eq "'/tmp/my project'" "$(agentic_shell_quote "/tmp/my project")" "quotes workspace paths with spaces"
  assert_eq "'/tmp/it'\\''s-here'" "$(agentic_shell_quote "/tmp/it's-here")" "quotes workspace paths with single quotes"
}

test_codex_pane_command() {
  local command

  command="$(agentic_codex_pane_command high "/tmp/my project")"
  assert_eq "codex -c model_reasoning_effort=\\\"high\\\" -C '/tmp/my project'" "$command" "builds high-effort Codex pane command"
}

test_claude_pane_command() {
  local command

  command="$(agentic_claude_pane_command low)"
  assert_eq "claude --effort low" "$command" "builds low-effort Claude pane command"
}

test_effort_label_validation() {
  assert_success "accepts high effort" agentic_validate_effort high
  assert_success "accepts medium effort" agentic_validate_effort medium
  assert_success "accepts low effort" agentic_validate_effort low
  assert_failure "rejects unsupported effort" agentic_validate_effort extreme
}

test_tmux_session_dx_enables_mouse_selection() {
  local -a calls

  tmux() {
    calls+=("$*")
  }

  agentic_configure_tmux_session_dx codex-workspace-12345678
  unfunction tmux

  assert_eq "set-option -t codex-workspace-12345678 mouse on" "$calls[1]" "enables mouse selection for tmux panes"
}

test_tmux_window_dx_labels_pane_borders() {
  local -a calls

  tmux() {
    calls+=("$*")
  }

  agentic_configure_tmux_window_dx codex-workspace-12345678:agents
  unfunction tmux

  assert_eq "set-window-option -t codex-workspace-12345678:agents pane-border-status top" "$calls[1]" "shows pane border labels"
  assert_eq "set-window-option -t codex-workspace-12345678:agents pane-border-format  #{pane_index}: #{pane_title} | #{b:pane_current_path} #('$repo_root/bin/agentic-pane-git-segment' #{q:pane_current_path}) " "$calls[2]" "formats pane border labels with directory and Git context"
}

test_effort_pane_title_sets_tmux_pane_title() {
  local -a calls

  tmux() {
    calls+=("$*")
  }

  agentic_set_effort_pane_title codex-workspace-12345678:agents.1 medium
  unfunction tmux

  assert_eq "select-pane -t codex-workspace-12345678:agents.1 -T medium" "$calls[1]" "sets effort label as tmux pane title"
}

test_existing_session_reapplies_tmux_configuration() {
  local -a calls

  tmux() {
    calls+=("$*")
  }

  agentic_configure_existing_tmux_session "codex-workspace-12345678"
  unfunction tmux

  assert_eq "set-option -t codex-workspace-12345678 mouse on" "$calls[1]" "reapplies session configuration"
  assert_eq "set-window-option -t codex-workspace-12345678:agents pane-border-status top" "$calls[2]" "reapplies window configuration"
}

test_pane_git_segment_handles_git_worktree_states() {
  local tmp_dir
  local repo

  tmp_dir="$(mktemp -d)"
  repo="$tmp_dir/repo with spaces"
  mkdir -p "$repo"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name Test
  print "base" > "$repo/modified"
  print "base" > "$repo/deleted"
  print "base" > "$repo/renamed"
  git -C "$repo" add .
  git -C "$repo" commit -qm initial

  assert_eq " | main | clean" "$("$repo_root/bin/agentic-pane-git-segment" "$repo")" "shows clean branch"

  print "change" >> "$repo/modified"
  rm "$repo/deleted"
  git -C "$repo" mv renamed moved
  print "new" > "$repo/added"
  git -C "$repo" add added
  print "untracked" > "$repo/untracked"

  assert_eq " | main | M1 A1 D1 R1 ?1" "$("$repo_root/bin/agentic-pane-git-segment" "$repo")" "shows compact local change counts"

  git -C "$repo" checkout -q --detach HEAD
  assert_eval_success "shows detached HEAD commit" '[[ "$("$repo_root/bin/agentic-pane-git-segment" "$repo")" == " | detached@"* ]]'

  rm -rf "$tmp_dir"
}

test_pane_git_segment_omits_non_git_directories() {
  local tmp_dir

  tmp_dir="$(mktemp -d)"
  assert_eq "" "$("$repo_root/bin/agentic-pane-git-segment" "$tmp_dir")" "omits Git context outside repositories"
  rm -rf "$tmp_dir"
}

test_pane_git_segment_exists_and_is_executable() {
  assert_eval_success "agentic-pane-git-segment exists and is executable" '[[ -x "$repo_root/bin/agentic-pane-git-segment" ]]'
}

test_launcher_scripts_exist_and_are_executable() {
  assert_eval_success "oc exists and is executable" '[[ -x "$repo_root/bin/oc" ]]'
  assert_eval_success "ot exists and is executable" '[[ -x "$repo_root/bin/ot" ]]'
}

test_launcher_scripts_reference_shared_helper() {
  assert_success "oc uses shared launcher helper" grep -q "multi-effort-session.zsh" "$repo_root/bin/oc"
  assert_success "ot uses shared launcher helper" grep -q "multi-effort-session.zsh" "$repo_root/bin/ot"
}

test_shell_zsh_adds_bin_to_path_once() {
  local output

  output="$(
    AGENTIC_CONFIG_ROOT="$repo_root" zsh -c '
      source "$AGENTIC_CONFIG_ROOT/shell.zsh"
      source "$AGENTIC_CONFIG_ROOT/shell.zsh"
      count=0
      for entry in ${(s/:/)PATH}; do
        [[ "$entry" == "$AGENTIC_CONFIG_ROOT/bin" ]] && count=$((count + 1))
      done
      print "$count"
    '
  )"

  assert_eq "1" "$output" "shell.zsh adds bin directory to PATH exactly once"
}

test_install_script_exists_and_is_executable() {
  assert_eval_success "install.sh exists and is executable" '[[ -x "$repo_root/bin/install.sh" ]]'
}

test_install_script_uses_managed_block() {
  assert_success "install.sh writes managed block start marker" grep -q "BEGIN AGENTIC CONFIG MANAGED BLOCK" "$repo_root/bin/install.sh"
  assert_success "install.sh writes managed block end marker" grep -q "END AGENTIC CONFIG MANAGED BLOCK" "$repo_root/bin/install.sh"
}

test_session_basename_slug
test_session_slug_sanitizes_characters
test_session_slug_handles_root
test_session_name_includes_tool_and_hash
test_missing_command_check
test_quote_command
test_codex_pane_command
test_claude_pane_command
test_effort_label_validation
test_tmux_session_dx_enables_mouse_selection
test_tmux_window_dx_labels_pane_borders
test_effort_pane_title_sets_tmux_pane_title
test_existing_session_reapplies_tmux_configuration
test_pane_git_segment_handles_git_worktree_states
test_pane_git_segment_omits_non_git_directories
test_pane_git_segment_exists_and_is_executable
test_launcher_scripts_exist_and_are_executable
test_launcher_scripts_reference_shared_helper
test_shell_zsh_adds_bin_to_path_once
test_install_script_exists_and_is_executable
test_install_script_uses_managed_block

if (( failures > 0 )); then
  print -u2 "$failures test(s) failed"
  exit 1
fi

print "All tests passed"
