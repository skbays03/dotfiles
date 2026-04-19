export PATH="$HOME/.local/bin:$PATH"
# ── Dev tooling (added $(date +%Y-%m-%d)) ─────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
eval "$(starship init zsh)"
# ── Aliases (added $(date +%Y-%m-%d)) ─────────────────
alias cat=bat
alias ls=eza
alias ll="eza -la --git --group-directories-first"
alias tree="eza --tree --git-ignore"
# pyenv init (only affects new shells)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
