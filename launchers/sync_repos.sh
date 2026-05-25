#!/bin/sh
# =============================================================================
# sync_repos.sh — pull dotfiles + learning from GitHub
# =============================================================================
# Called by:
#   - learning_tmux launchers (auto-sync before starting the tmux session)
#   - `sync` shell alias (manual sync any time)
#
# Skips a repo if it has uncommitted local changes (safe — no merge conflicts).
# Prints one status line per repo. Returns 0 always (never fails the caller).
# =============================================================================

set -u

sync_repo() {
    repo="$1"
    name=$(basename "$repo")
    if [ ! -d "$repo/.git" ]; then
        echo "  [$name] not a git repo — skipping"
        return 0
    fi
    if [ -n "$(cd "$repo" && git status -s 2>/dev/null)" ]; then
        echo "  [$name] uncommitted changes — skipping (commit + push to sync)"
        return 0
    fi
    if (cd "$repo" && git pull -q 2>/dev/null); then
        echo "  [$name] up to date"
    else
        echo "  [$name] pull failed (check network / auth)"
    fi
    return 0
}

echo "==> Syncing repos..."
sync_repo "$HOME/dotfiles"
sync_repo "$HOME/Desktop/learning"

# If a tmux session is already running, reload its config (dotfiles may have
# updated ~/.tmux.conf since the session started).
if tmux info >/dev/null 2>&1; then
    tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true
fi
