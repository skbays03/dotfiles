# dotfiles

Cross-platform dotfiles for macOS and Linux/WSL Ubuntu. Drives:

- Shell (zsh) — aliases, tooling init, defensive `command -v` guards so it works on machines missing any optional tool.
- **Ghostty** terminal — JetBrainsMono Nerd Font, TokyoNight Night theme, Tokyo neon wallpaper at low opacity.
- **tmux** — vim-style pane navigation, leader `C-a`, transparent status bar (lets the Ghostty wallpaper show through).
- **Neovim** — lazy.nvim plugin manager, tokyonight (transparent), LSP (clangd/pyright/lua_ls), telescope, neo-tree, treesitter, nvim-cmp, Comment.nvim.

## Layout

```
~/dotfiles/
├── README.md              (this file)
├── install.sh             (OS-aware installer + symlinker)
├── SNAPSHOT.md            (brew/system snapshot from initial capture)
├── .gitignore
├── home/
│   ├── zshrc              (-> ~/.zshrc)
│   ├── gitconfig          (-> ~/.gitconfig)
│   └── tmux.conf          (-> ~/.tmux.conf)
├── config/
│   ├── ghostty/config     (-> ~/.config/ghostty/config; filtered on Linux)
│   └── nvim/              (-> ~/.config/nvim/)
├── wallpapers/
│   └── tokyo_neon.jpg     (-> ~/Pictures/wallpapers/tokyo_neon.jpg)
└── launchers/
    ├── learning_tmux.command  (-> ~/Desktop/learning_tmux.command on macOS)
    └── learning_tmux.sh       (-> ~/Desktop/learning_tmux.sh on Linux/WSL)
```

## Setup on a new machine

```sh
git clone https://github.com/skbays03/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` is idempotent — safe to re-run.

What it does:

1. Detects OS (macOS or Linux).
2. Installs dependencies (`brew` on macOS, `apt` + a few curl scripts on Linux).
3. Installs JetBrainsMono Nerd Font.
4. Symlinks files from `~/dotfiles/` into `$HOME` and `~/.config/`.
5. Backs up any existing files first (renames to `*.dotfiles-backup`).

## Per-machine secrets

`~/.zshrc.local` is sourced by `.zshrc` if it exists, but **never** committed to this repo. Use it for:

- API tokens (Twilio, etc.)
- Per-machine `PATH` additions
- Anything sensitive or machine-specific

Restore secrets from 1Password (or wherever you back them up) on each new machine.

## Ghostty on Linux / WSL

The macOS install assumes `brew install --cask ghostty`. On Linux, Ghostty doesn't have an apt package — build from source:

```sh
# Install Zig at the version Ghostty's README pins to (changes monthly — check)
# https://ziglang.org/download/

# Ghostty's deps on Ubuntu 24.04+
sudo apt install -y \
    libgtk-4-dev libadwaita-1-dev libxml2-utils \
    blueprint-compiler gettext libonig-dev pkg-config \
    build-essential

# Build
git clone https://github.com/ghostty-org/ghostty.git ~/src/ghostty
cd ~/src/ghostty
zig build -Doptimize=ReleaseFast
sudo zig build install -Doptimize=ReleaseFast --prefix /usr/local
```

WSL Ubuntu: GUI app works via **WSLg** (Windows 11+). GPU acceleration depends on the host's graphics driver — may fall back to software rendering. If that's painful, **WezTerm on Windows** with WSL integration is a drop-in alternative.

`install.sh` strips the `macos-option-as-alt` line from `ghostty/config` on Linux installs (Ghostty errors on unknown keys).

## Files this does NOT manage

- `~/.ssh/` — set up per-machine
- 1Password / secrets — managed externally
- `~/.claude/` — Claude Code's per-project memory; tied to absolute paths so doesn't directly sync across machines
- The **learning hub itself** lives in its own repo (`skbays03/learning`) — clone separately to `~/Desktop/learning/`

## Multi-machine workflow

### `lazy-lock.json` — plugin version sync

`config/nvim/lazy-lock.json` pins every nvim plugin to a specific commit SHA. It's tracked in git so both machines run the same plugin versions.

**Discipline: run `:Lazy update` on ONE machine only** (designate the Mac, for instance). Sync the other machine via `git pull`.

If both machines update plugins independently, they each produce a different lock file. The next push/pull collides and you have to resolve a merge conflict on a file full of opaque SHAs.

#### Workflow

1. On the "update" machine: open nvim, run `:Lazy update`. Review what's changing. When done, the lock file reflects the new versions.
2. Commit + push:
   ```sh
   c "lazy: update plugins $(date +%Y-%m-%d)"
   ```
3. On the other machine: `git pull` (or open the launcher, which auto-pulls). Open nvim — lazy.nvim sees the updated lock and installs the matching versions automatically.

#### If a merge conflict happens anyway

From `~/dotfiles` after a conflicting `git pull`:

```sh
# Accept the remote version (what you just pulled). Usually what you want.
git checkout --theirs config/nvim/lazy-lock.json
git add config/nvim/lazy-lock.json
git commit
# Then re-sync nvim's installed plugins to the lock file:
nvim -c ':Lazy restore' -c ':qa'
```

To accept the LOCAL version instead, use `--ours` in place of `--theirs`. `--theirs`/`--ours` flip meaning during a rebase vs a pull-merge — for a plain `git pull`, `--theirs = remote`.

## Companion repo

- `skbays03/learning` (private) — the CS prep hub: per-subject topic files, working code, the sift / sentinel / fs projects, the meta-skills doc. Clone to `~/Desktop/learning/` so the launcher script finds it.
