#!/bin/zsh
# =============================================================================
# learning_tmux.command — launch the "learning" tmux session
# =============================================================================
# Double-click to:
#   1. Open Terminal (macOS handles this automatically for .command files).
#   2. Either ATTACH to the existing "learning" tmux session if it's already
#      running, or CREATE a fresh one with two panes:
#        LEFT  — Claude Code (claude /start)
#        RIGHT — nvim
#   3. cd into ~/Desktop/learning so both panes start in the hub root.
#
# Sister file: learning.command (the non-tmux launcher — single pane, Claude only).
# Use this file when you want Claude + nvim side-by-side.
#
# tmux cheatsheet (your prefix is Ctrl-a; see ~/.tmux.conf):
#   <prefix> h / j / k / l       switch panes (vim-style)
#   <prefix> H / J / K / L       resize panes (5 cells per press)
#   <prefix> z                    zoom (toggle pane to fullscreen)
#   <prefix> d                    detach from session (it keeps running in background)
#   <prefix> [                    enter copy mode (scroll/select with vim keys; q to exit)
#   <prefix> ?                    show all keymaps
# =============================================================================

SESSION="learning"

# Finder-launched scripts don't always inherit the user's shell PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/bin:$HOME/.local/bin:$PATH"

LEARN_DIR="$HOME/Desktop/learning"

# Auto-sync repos from GitHub before starting the session. Picks up any changes
# pushed from the other machine; safe to skip if uncommitted changes exist.
if [ -x "$HOME/dotfiles/launchers/sync_repos.sh" ]; then
    "$HOME/dotfiles/launchers/sync_repos.sh"
    echo ""
fi

if ! command -v tmux >/dev/null 2>&1; then
    echo "tmux not installed. Install with: brew install tmux"
    read -n 1 -s -r -p "Press any key to close..."
    exit 1
fi

# Already running? Attach instead of creating a new session.
if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach -t "$SESSION"
fi

# Create the session, detached, with one window split into two panes.
cd "$LEARN_DIR" || {
    echo "Couldn't find $LEARN_DIR — did you move or rename it?"
    read -n 1 -s -r -p "Press any key to close..."
    exit 1
}

#   new-session   -d (detached) -s NAME -n WINDOW -c CWD
# LEFT pane starts in ~/Desktop/learning so Claude auto-loads the hub's CLAUDE.md.
tmux new-session -d -s "$SESSION" -n main -c "$LEARN_DIR"

#   split-window  -h (horizontal split = new pane to the RIGHT) -c CWD
# RIGHT pane (nvim) starts in ~/Desktop so file navigation reaches projects
# OUTSIDE the learning hub too. <leader>ff / <leader>n in nvim are scoped to cwd.
tmux split-window -h -t "$SESSION:main" -c "$HOME/Desktop"

# Launch tools in each pane.
#   Pane 1 (LEFT)  — Claude Code with /start (auto-loads hub context).
#   Pane 2 (RIGHT) — nvim with no file (use <leader>ff or :e to open).
tmux send-keys -t "$SESSION:main.1" "claude /start" C-m
tmux send-keys -t "$SESSION:main.2" "nvim"          C-m

# Put focus on the LEFT pane (Claude) so you start there.
tmux select-pane -t "$SESSION:main.1"

# Attach so the user sees the session.
exec tmux attach -t "$SESSION"
