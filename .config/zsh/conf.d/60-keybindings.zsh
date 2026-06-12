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

# Home / End. iTerm2 (and other terminals) may emit any of several escape
# sequences for these keys depending on terminfo / keypad mode. Bind the
# common forms, then use terminfo as the authoritative fallback so the
# active terminal's actual sequence is always covered.
bindkey '^[[H'  beginning-of-line   # xterm
bindkey '^[[F'  end-of-line
bindkey '^[OH'  beginning-of-line   # application keypad mode
bindkey '^[OF'  end-of-line
bindkey '^[[1~' beginning-of-line   # Linux console / some xterms
bindkey '^[[4~' end-of-line
bindkey '^[[7~' beginning-of-line   # rxvt
bindkey '^[[8~' end-of-line

# Authoritative fallback from terminfo. Run zle -N for any widget that
# might not be defined yet; the (N) qualifier guards against an unset key.
if (( ${+terminfo[khome]} )); then
  bindkey "${terminfo[khome]}" beginning-of-line
fi
if (( ${+terminfo[kend]} )); then
  bindkey "${terminfo[kend]}" end-of-line
fi
