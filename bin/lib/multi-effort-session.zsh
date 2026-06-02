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
