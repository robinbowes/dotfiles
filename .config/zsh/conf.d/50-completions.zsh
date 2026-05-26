# Completion setup.
# `compinit` must run AFTER all fpath additions (homebrew, plugins via antidote).
# antidote already loaded in .zshrc; this file runs in conf.d (after antidote).

# Add Homebrew site-functions to fpath if available.
if (( $+commands[brew] )); then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

autoload -Uz compinit
# -d puts the cache file inside ZDOTDIR rather than at $HOME.
compinit -d "${ZDOTDIR}/.zcompdump"

# Case-insensitive matching and smart partial-word completion.
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|=*' \
  'l:|=* r:|=*'

# Interactive selection menu (used by fzf-tab too).
zstyle ':completion:*' menu select

# Colour completion lists with LS_COLORS.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
