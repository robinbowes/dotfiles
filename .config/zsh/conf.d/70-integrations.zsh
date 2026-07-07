# Third-party tool integrations.
# Each is guarded so the file is harmless if the tool isn't installed.

# Starship prompt
(( $+commands[starship] )) && eval "$(starship init zsh)"

# fzf — Ctrl-T (file), Ctrl-R (history), Alt-C (cd).
# Tab-completion via fzf is provided by the Aloxaf/fzf-tab plugin, not here.
(( $+commands[fzf] )) && source <(fzf --zsh)

# mise — version manager activation hook.
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# direnv — per-directory environment loader.
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# iTerm2 shell integration (file is only present if installed via iTerm2 menu)
[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] \
  && source "${HOME}/.iterm2_shell_integration.zsh"

# atuin — kept commented to match the previous bash setup.
# (( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"
