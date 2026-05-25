#!/usr/bin/env bash
# =============================================================================
# ghostty-learning.sh — launched by the Windows "Learning Tmux" desktop shortcut.
#
# Spawns Ghostty fully detached so wsl.exe exits immediately and Windows can
# close the parent console. Inline `bash -lc "..."` in the .lnk arguments
# is fragile (Explorer's shell-execute path mangles `&` / quoting); putting
# the logic in a script file avoids that entirely.
# =============================================================================
export DISPLAY="${DISPLAY:-:0}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

setsid -f ghostty -e "$HOME/Desktop/learning_tmux.sh" </dev/null >/dev/null 2>&1
