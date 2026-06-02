# Agentic Config

This context describes local command-line configuration for starting coordinated AI coding sessions from any terminal on the machine.

## Language

**Agent Launch Command**:
A short shell command that starts a predefined AI coding workspace with live agents already running.
_Avoid_: alias, shortcut

**Workspace Directory**:
The current working directory where an **Agent Launch Command** is invoked.
_Avoid_: project install, repo copy

**Workspace Session**:
A stable tmux session for one **Agent Tool** and one **Workspace Directory**.
_Avoid_: duplicate session, temporary session

**Managed Shell Block**:
An idempotent section in a shell startup file that loads this repo's shell integration.
_Avoid_: manual setup, copied alias

**Multi-Effort Session**:
A tmux session containing one vertically stacked tmux window with three panes for the same tool, split by high, medium, and low reasoning effort.
_Avoid_: parallel window setup, terminal window setup

**Effort Lane**:
One pane in a **Multi-Effort Session**, distinguished only by its reasoning effort level.
_Avoid_: role, persona

**Agent Tool**:
A supported AI coding CLI that can be launched inside a **Multi-Effort Session**.
_Avoid_: AI app, model

**Effort Mapping**:
The command-line arguments that configure an **Agent Tool** for an **Effort Lane**.
_Avoid_: role prompt, lane prompt

## Relationships

- An **Agent Launch Command** starts exactly one **Multi-Effort Session**
- An **Agent Launch Command** attaches to an existing **Workspace Session** when one already exists
- An **Agent Launch Command** attaches in the current terminal, using tmux client switching when already inside tmux
- An **Agent Launch Command** uses the **Workspace Directory** as the working directory for every **Effort Lane**
- A **Multi-Effort Session** targets exactly one **Agent Tool**
- An **Agent Tool** may have one or more **Agent Launch Commands**
- A **Multi-Effort Session** contains exactly three panes: high effort, medium effort, and low effort
- An **Effort Lane** does not imply a task role; the developer provides the task prompt manually after launch
- An **Effort Lane** has exactly one **Effort Mapping** for its target **Agent Tool**
- A **Managed Shell Block** is created by the installer and may be safely refreshed by re-running it
- tmux is required to create a **Multi-Effort Session**; individual **Agent Tools** may be installed independently

## Example dialogue

> **Dev:** "When I run `oc`, should it open three separate Terminal.app windows?"
> **Domain expert:** "No — `oc` starts a **Multi-Effort Session** in tmux for Codex, with high, medium, and low effort panes."

## Flagged ambiguities

- "window setup" was used to mean terminal windows or panes; resolved: this project uses tmux sessions with three panes or windows, not OS terminal windows.
- "three panes/windows" was used ambiguously; resolved: the default layout is three panes in one tmux window.
- "parallel setup" was ambiguous about geometry; resolved: panes are stacked vertically by default to remain readable in Cursor's narrow left terminal.
- "support any project" was ambiguous about copying files into each project; resolved: this repo is installed once globally, and launch commands run from the current working directory.
- "open" could mean always creating a new session; resolved: launch commands are idempotent per agent tool and workspace, attaching to the existing workspace session when present.
- "support claude and codex" could imply a configurable adapter system; resolved: v1 supports fixed launch commands for Codex and Claude only.
- "support claude and codex" could imply empty tool-specific directories; resolved: v1 support is proven by working launch commands, and tool-specific directories are added only when they contain real configuration.
