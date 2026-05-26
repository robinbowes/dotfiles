# Shell options (setopt) and history configuration.
# Mirrors the behaviour previously expressed via `shopt` in .bashrc and
# HIST* exports in .exports.

# --- Navigation -------------------------------------------------------------
setopt AUTO_CD              # `cd foo` is implicit when `foo` is a directory
setopt CDABLE_VARS          # `cd varname` expands varname as a directory
setopt CORRECT              # offer correction for mistyped commands

# --- Globbing ---------------------------------------------------------------
setopt EXTENDED_GLOB        # ^, ~, #, etc. in globs
setopt NO_CASE_GLOB         # case-insensitive globbing

# --- History ----------------------------------------------------------------
HISTFILE="${ZDOTDIR}/.zsh_history"
HISTSIZE=200000
SAVEHIST=200000

setopt APPEND_HISTORY       # don't overwrite history on shell exit
setopt INC_APPEND_HISTORY   # append each command as it's typed
setopt SHARE_HISTORY        # share history across concurrent shells
setopt HIST_IGNORE_SPACE    # leading-space commands aren't recorded
setopt HIST_IGNORE_DUPS     # don't record an immediate duplicate
setopt HIST_IGNORE_ALL_DUPS # remove older duplicates entirely
setopt HIST_REDUCE_BLANKS   # collapse runs of whitespace
setopt HIST_VERIFY          # `!!` etc. show the expanded command before run
