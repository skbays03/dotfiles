#!/bin/sh
# =============================================================================
# install.sh — install dependencies + symlink dotfiles into place
# =============================================================================
# Idempotent: safe to re-run. Existing files get backed up as *.dotfiles-backup.
# Works on macOS (brew) and Linux/WSL Ubuntu (apt + curl scripts).
# =============================================================================

set -eu

DOTFILES="$HOME/dotfiles"

# ---- OS detection -----------------------------------------------------------

case "$(uname -s)" in
    Darwin)  OS=macos ;;
    Linux)   OS=linux ;;
    *)       echo "Unsupported OS: $(uname -s)"; exit 1 ;;
esac

echo "==> OS: $OS"
echo ""



# ---- Helper -----------------------------------------------------------------

link() {
    src="$1"
    dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "    backing up $dst -> $dst.dotfiles-backup"
        mv "$dst" "$dst.dotfiles-backup"
    fi
    [ -L "$dst" ] && rm "$dst"
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "    linked $dst"
}



# ---- Dependencies -----------------------------------------------------------

echo "==> Installing dependencies"

if [ "$OS" = macos ]; then
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not installed. Install from https://brew.sh first."
        exit 1
    fi
    # Skip packages already installed
    for pkg in tmux neovim ripgrep fd fzf gh starship zoxide eza bat direnv pyenv lazygit tldr; do
        brew list --formula "$pkg" >/dev/null 2>&1 || brew install "$pkg"
    done
    brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1 \
        || brew install --cask font-jetbrains-mono-nerd-font
    brew list --cask ghostty >/dev/null 2>&1 \
        || brew install --cask ghostty

elif [ "$OS" = linux ]; then
    sudo apt update
    sudo apt install -y \
        tmux neovim ripgrep fd-find fzf gh \
        curl unzip fontconfig build-essential git

    # fd is named fdfind on Debian/Ubuntu — alias so commands match Mac
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi

    # starship via official installer (apt version is too old)
    if ! command -v starship >/dev/null 2>&1; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi

    # JetBrainsMono Nerd Font
    FONT_DIR="$HOME/.local/share/fonts"
    if ! ls "$FONT_DIR" 2>/dev/null | grep -qi "JetBrainsMono.*Nerd"; then
        mkdir -p "$FONT_DIR"
        TMP=$(mktemp -d)
        curl -sLo "$TMP/JBM.zip" \
            "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
        unzip -q "$TMP/JBM.zip" -d "$TMP"
        cp "$TMP"/*.ttf "$FONT_DIR/"
        fc-cache -fv >/dev/null
        rm -rf "$TMP"
    fi

    echo ""
    echo "    NOTE: Ghostty must be built from source on Linux — see README.md"
    echo "    NOTE: Optional extras (zoxide, eza, bat, direnv, lazygit) not auto-installed."
    echo "          See README.md or install manually via apt/cargo as desired."
fi

echo ""



# ---- Symlinks ---------------------------------------------------------------

echo "==> Creating symlinks"

link "$DOTFILES/home/zshrc"     "$HOME/.zshrc"
link "$DOTFILES/home/gitconfig" "$HOME/.gitconfig"
link "$DOTFILES/home/tmux.conf" "$HOME/.tmux.conf"

# Symlink the entire nvim config directory (so future additions sync automatically)
link "$DOTFILES/config/nvim" "$HOME/.config/nvim"

# Ghostty: cross-platform symlink (common config) + per-OS os.conf symlink.
# The common config includes `config-file = os.conf`, which resolves to whichever
# OS-specific file we link below. Wallpaper path uses ~ so it expands per machine.
mkdir -p "$HOME/.config/ghostty"
link "$DOTFILES/config/ghostty/config" "$HOME/.config/ghostty/config"
if [ "$OS" = macos ]; then
    link "$DOTFILES/config/ghostty/os-macos.conf" "$HOME/.config/ghostty/os.conf"
else
    link "$DOTFILES/config/ghostty/os-linux.conf" "$HOME/.config/ghostty/os.conf"
fi

# Wallpaper
mkdir -p "$HOME/Pictures/wallpapers"
link "$DOTFILES/wallpapers/tokyo_neon.jpg" "$HOME/Pictures/wallpapers/tokyo_neon.jpg"

# Launcher (OS-specific)
if [ "$OS" = macos ]; then
    link "$DOTFILES/launchers/learning_tmux.command" "$HOME/Desktop/learning_tmux.command"
else
    link "$DOTFILES/launchers/learning_tmux.sh" "$HOME/Desktop/learning_tmux.sh"
fi

echo ""
echo "==> Done."
echo ""
echo "Next steps:"
echo "  - Restart your shell (or 'exec zsh') to pick up the new .zshrc."
echo "  - Clone the learning hub if you haven't:"
echo "      git clone git@github.com:skbays03/learning.git ~/Desktop/learning"
echo "  - For Twilio (Python phone_alarm project), restore creds from 1Password to"
echo "    ~/.zshrc.local in the form:"
echo "      export TWILIO_ACCOUNT_SID=..."
echo "      export TWILIO_AUTH_TOKEN=..."
echo "      export TWILIO_FROM=..."
echo "      export TWILIO_TO=..."
echo ""
if [ "$OS" = linux ]; then
    echo "  - On Linux: build Ghostty from source (see README), or use WezTerm/Windows Terminal."
fi
