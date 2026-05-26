# Keybindings. Replaces the readline keybindings that .inputrc provided
# (zsh uses ZLE, not readline).

# Emacs keymap. Default in zsh when EDITOR isn't 'vi', but set explicitly.
bindkey -e

# History substring search on arrow keys. Requires the
# zsh-history-substring-search plugin (loaded by antidote).
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P'   history-substring-search-up
bindkey '^N'   history-substring-search-down

# Alt+Delete to delete the preceding word (matches the .inputrc binding).
bindkey '^[[3;3~' kill-word
