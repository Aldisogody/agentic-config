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

test_session_basename_slug
test_session_slug_sanitizes_characters
test_session_slug_handles_root
test_session_name_includes_tool_and_hash
test_missing_command_check
test_quote_command

if (( failures > 0 )); then
  print -u2 "$failures test(s) failed"
  exit 1
fi

print "All tests passed"
