# Environment variables. Ported from the bash .exports.
# HIST* settings live in 00-options.zsh as zsh options instead.

# --- Editor -----------------------------------------------------------------
export EDITOR="vim"
export VISUAL="vim"

# --- Locale -----------------------------------------------------------------
export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"

# --- Pager / less -----------------------------------------------------------
export LESSOPEN="|lesspipe.sh %s"
export LESS_ADVANCED_PREPROCESSOR=1
export MANPAGER="less -X"

# --- Homebrew ---------------------------------------------------------------
export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# --- Krypton/assh SSH ------------------------------------------------------
# https://krypt.co/docs/use-krypton-with/advanced-ssh.html
export KR_SKIP_SSH_CONFIG=1
