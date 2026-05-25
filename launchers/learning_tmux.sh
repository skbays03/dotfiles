#!/usr/bin/env bash
# =============================================================================
# learning_tmux.sh — launch the "learning" tmux session (Linux / WSL Ubuntu)
# =============================================================================
# Linux/WSL equivalent of learning_tmux.command. Same behavior:
#   - Attach to existing "learning" tmux session if running, or
#   - Create one with two panes:
#       LEFT  — Claude Code (claude /start)
#       RIGHT — nvim
#
# Requires:
#   - tmux            (sudo apt install tmux)
#   - claude CLI      (Claude Code; install separately)
#   - nvim            (sudo apt install neovim)
#   - the learning repo cloned to ~/Desktop/learning
#       (git clone git@github.com:skbays03/learning.git ~/Desktop/learning)
# =============================================================================

SESSION="learning"
LEARN_DIR="$HOME/Desktop/learning"

# Inherit a sane PATH (the script may be launched from a file manager that doesn't pass one)
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Auto-sync repos from GitHub before starting the session. Picks up any changes
# pushed from the other machine; safe to skip if uncommitted changes exist.
if [ -x "$HOME/dotfiles/launchers/sync_repos.sh" ]; then
    "$HOME/dotfiles/launchers/sync_repos.sh"
    echo ""
fi

if ! command -v tmux >/dev/null 2>&1; then
    echo "tmux not installed.  Install with:  sudo apt install tmux"
    read -n 1 -s -r -p "Press any key to close..."
    exit 1
fi

# Already running? Attach.
if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach -t "$SESSION"
fi

cd "$LEARN_DIR" || {
    echo "Couldn't find $LEARN_DIR"
    echo "Clone the learning repo first:"
    echo "  git clone git@github.com:skbays03/learning.git $LEARN_DIR"
    read -n 1 -s -r -p "Press any key to close..."
    exit 1
}

# Create the session, detached, with one window split into two panes.
tmux new-session -d -s "$SESSION" -n main -c "$LEARN_DIR"

# Right pane (nvim) starts in ~/Desktop so it can reach projects outside the hub.
tmux split-window -h -t "$SESSION:main" -c "$HOME/Desktop"

# Launch tools in each pane.
tmux send-keys -t "$SESSION:main.1" "claude /start" C-m
tmux send-keys -t "$SESSION:main.2" "nvim"          C-m

# Put focus on the LEFT pane (Claude) so you start there.
tmux select-pane -t "$SESSION:main.1"

# Attach so the user sees the session.
exec tmux attach -t "$SESSION"
