# Zsh Migration Design

**Date:** 2026-05-26
**Status:** Approved
**Repo:** `robinbowes/dotfiles`

## Goal

Migrate the interactive shell configuration from bash to idiomatic zsh while
preserving the existing behaviour (starship prompt, fzf integration, mise,
aliases, functions, completions). Bash remains installed for shell scripting
work, but its interactive config files are removed from the repo.

## Decisions

- **Framework:** [antidote](https://getantidote.github.io/) plugin manager.
  Static plugin file, compiled bundle, no theme opinions (starship stays).
- **Layout:** `ZDOTDIR="$HOME/.config/zsh"`. Only `~/.zshenv` lives at `$HOME`.
- **Bash files:** Delete `.bash_profile`, `.bashrc`, `.git-prompt.sh`, `.fzf`,
  `.path`, `.mise`, `.ssh_completion`, `.aliases`, `.exports`, `.functions`.
  Keep `.inputrc` (used by python REPL, sqlite3, gdb — anything linked to
  readline).
- **Bootstrap reload:** `exec zsh -l` after sync.
- **Conf file ordering:** numeric prefixes in `conf.d/` (so order is explicit
  and a new concern can be slotted between existing ones without renames).

## File layout (mirrors `$HOME` after deploy)

```
.zshenv                     # one-liner: export ZDOTDIR="$HOME/.config/zsh"
.inputrc                    # unchanged (readline, not bash-specific)
.config/zsh/
  .zprofile                 # login-shell: brew shellenv, PATH-affecting tools
  .zshrc                    # interactive: options, plugins, completions
  .zsh_plugins.txt          # antidote plugin list (hand-edited)
  conf.d/                   # auto-sourced by .zshrc in glob order
    00-options.zsh
    10-path.zsh
    20-exports.zsh
    30-aliases.zsh
    40-functions.zsh
    50-completions.zsh
    60-keybindings.zsh
    70-integrations.zsh
    99-local.zsh
```

`.zshrc` ends with:

```zsh
for f in "$ZDOTDIR"/conf.d/*.zsh(N); do
  source "$f"
done
```

The `(N)` glob qualifier makes the loop safe if `conf.d/` is empty.

## File-by-file content

### `~/.zshenv`

```zsh
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
```

Zsh reads this before any other config and must live at `$HOME`.

### `$ZDOTDIR/.zprofile`

Login-shell init. Runs once per login. Contains only things that affect the
environment (PATH, shellenv-style exports).

```zsh
# Homebrew shellenv (sets PATH, MANPATH, INFOPATH, HOMEBREW_*)
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Replaces the existing `~/.zprofile` that macOS auto-created.

### `$ZDOTDIR/.zshrc`

Interactive-shell init. Loads antidote, sources the plugin bundle, then sources
all `conf.d/*.zsh` files in order.

```zsh
# antidote (homebrew-installed; no git fallback)
antidote_init="/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"
if [[ ! -r $antidote_init ]]; then
  print -u2 "zshrc: antidote not found at $antidote_init"
  print -u2 "       install with: brew install antidote"
  return 1
fi
source "$antidote_init"
antidote load "${ZDOTDIR}/.zsh_plugins.txt"
unset antidote_init

# user config
for f in "${ZDOTDIR}"/conf.d/*.zsh(N); do
  source "$f"
done
```

Path is hardcoded for Apple Silicon Homebrew (matches the existing
`/opt/homebrew/bin/brew` reference in `.zprofile`). Calling `brew --prefix` on
every shell start would add ~50 ms of latency for no gain on a single-arch
machine. The `return 1` aborts `.zshrc` cleanly so the shell still works as a
plain zsh — you can fix the install then `exec zsh`.

### `$ZDOTDIR/.zsh_plugins.txt`

Starting set — user will extend as gaps appear:

```
zsh-users/zsh-completions
zsh-users/zsh-autosuggestions
zdharma-continuum/fast-syntax-highlighting
zsh-users/zsh-history-substring-search
Aloxaf/fzf-tab
ohmyzsh/ohmyzsh path:plugins/colored-man-pages
```

Load order matters: `fast-syntax-highlighting` and `zsh-history-substring-search`
must be the last two entries (in that order) per their docs.

### `$ZDOTDIR/conf.d/00-options.zsh`

```zsh
# Navigation
setopt AUTO_CD
setopt CDABLE_VARS
setopt CORRECT

# Globbing
setopt EXTENDED_GLOB
setopt NO_CASE_GLOB

# History
HISTFILE="${ZDOTDIR}/.zsh_history"
HISTSIZE=200000
SAVEHIST=200000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
```

### `$ZDOTDIR/conf.d/10-path.zsh`

```zsh
typeset -aU path

# Prepended (highest precedence first)
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  $path
)

# Conditional entries
[[ -n ${GOPATH:-} && -d $GOPATH/bin ]] && path=("$GOPATH/bin" $path)
[[ -n ${PG_VERSION:-} && -d /opt/homebrew/opt/postgresql@${PG_VERSION}/bin ]] \
  && path=("/opt/homebrew/opt/postgresql@${PG_VERSION}/bin" $path)

# Local overrides (gitignored, per-host)
[[ -r "${ZDOTDIR}/path.local" ]] && source "${ZDOTDIR}/path.local"
```

`typeset -aU path` keeps `$path` deduplicated automatically. Note that
`brew shellenv` already ran in `.zprofile`, so homebrew is in `$path` before
this file runs.

### `$ZDOTDIR/conf.d/20-exports.zsh`

Direct port of `.exports`:

```zsh
export EDITOR="vim"
export VISUAL="vim"

export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"

export LESSOPEN="|lesspipe.sh %s"
export LESS_ADVANCED_PREPROCESSOR=1
export MANPAGER="less -X"

export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# Krypton/assh SSH config skip
export KR_SKIP_SSH_CONFIG=1
```

Bash-specific `HIST*` exports drop — those live in `00-options.zsh` as zsh
options instead.

### `$ZDOTDIR/conf.d/30-aliases.zsh`

Almost verbatim port of `.aliases`. Notable changes:

- The `for method in GET HEAD POST PUT DELETE TRACE OPTIONS` loop works
  identically in zsh.
- `alias -- -="cd -"` works in zsh.
- The `h` alias (`awk ... < <(HISTTIMEFORMAT= history)`) needs adjustment —
  zsh's `history` builtin takes different args. New form:
  `alias h='fc -li 1'` (shows numbered history with timestamps).
- Drop `HISTTIMEFORMAT` references — zsh doesn't use it.

### `$ZDOTDIR/conf.d/40-functions.zsh`

Direct port of `.functions`. Most functions are POSIX-ish and will work
unchanged. Specific notes:

- `function name() { … }` syntax is supported by zsh — no change needed.
- `$@` and `$*` behave the same enough for these functions.
- `mkd()`: change `mkdir -p "$@" && cd "$@"` to `mkdir -p "$1" && cd "$1"`
  (zsh's `cd` doesn't accept multiple args).
- `ncs()`: works unchanged.
- Test each non-trivial function during implementation.

### `$ZDOTDIR/conf.d/50-completions.zsh`

```zsh
# Add homebrew completions to fpath BEFORE compinit
if command -v brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# Completion cache location
autoload -Uz compinit
compinit -d "${ZDOTDIR}/.zcompdump"

# Case-insensitive matching, smart completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# SSH completion uses known_hosts and ~/.ssh/config automatically — no manual
# `complete -F` needed (this replaces .ssh_completion).
```

### `$ZDOTDIR/conf.d/60-keybindings.zsh`

```zsh
# Emacs keymap (default; explicit for clarity)
bindkey -e

# History substring search on arrow keys (replaces .inputrc behaviour)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P'   history-substring-search-up
bindkey '^N'   history-substring-search-down

# Alt+Delete to delete word
bindkey '^[[3;3~' kill-word
```

Other `.inputrc` settings translate as follows (set via `zstyle` in
`50-completions.zsh` above):

- `completion-ignore-case on` → matcher-list above
- `show-all-if-ambiguous on` → `setopt LIST_AMBIGUOUS` (default)
- `match-hidden-files off` → `setopt GLOB_DOTS` left off (default)

### `$ZDOTDIR/conf.d/70-integrations.zsh`

```zsh
# Cross-shell prompt
command -v starship &>/dev/null && eval "$(starship init zsh)"

# fzf — fuzzy finder
command -v fzf &>/dev/null && source <(fzf --zsh)

# mise — version manager
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# iTerm2 shell integration
[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] \
  && source "${HOME}/.iterm2_shell_integration.zsh"

# Optional: atuin (currently commented out in .bash_profile — preserve state)
# command -v atuin &>/dev/null && eval "$(atuin init zsh --disable-up-arrow)"
```

### `$ZDOTDIR/conf.d/99-local.zsh`

```zsh
# Per-host local additions (gitignored)
[[ -r "${HOME}/.extra" ]] && source "${HOME}/.extra"
```

## Bootstrap script changes

`bootstrap.sh` needs two updates:

1. **`reload_config()`:** replace `. ~/.bash_profile` with:

   ```bash
   reload_config() {
     exec zsh -l
   }
   ```

   You can't reload an interactive zsh from a bash parent — `exec` replaces
   the current process so the new env is in effect immediately.

2. **antidote install:** add `brew install antidote` to `.brew` (which is a
   bash install script, not a Brewfile). `.zshrc` requires antidote and bails
   with an actionable message if missing (no git fallback). On a fresh
   machine the order is: install Homebrew → `./.brew` → `chsh -s` → open new
   terminal. If you ever land in a shell with antidote missing, you'll get
   the hint and can `brew install antidote && exec zsh`.

`check_for_changed_files` and `sync_files` already recurse via `find` and
`rsync -av`, so the new `.config/zsh/` tree is picked up automatically. No
structural change needed.

## Taskfile changes

`dotfiles:pull` uses the same `find` recursion as `bootstrap.sh`, so
`.config/zsh/conf.d/*.zsh` round-trips correctly. Verify after first run.

## Files removed from repo

- `.bash_profile`
- `.bashrc`
- `.git-prompt.sh` (starship provides git status)
- `.fzf` (replaced by integration in `70-integrations.zsh`)
- `.path` (replaced by `10-path.zsh`)
- `.mise` (replaced by `mise activate zsh` in `70-integrations.zsh`)
- `.ssh_completion` (zsh's built-in `_ssh` reads known_hosts automatically)
- `.aliases` (content moves to `30-aliases.zsh`)
- `.exports` (content moves to `20-exports.zsh`)
- `.functions` (content moves to `40-functions.zsh`)

Files kept:

- `.inputrc` (readline, used by tools beyond bash)
- All other dotfiles (`.gitconfig`, `.tmux.conf`, `.vimrc`, etc.) unchanged.

## Testing approach

Implementation happens on a feature branch. Validation in three stages:

1. **Isolated shell test** (no deploy):
   ```bash
   ZDOTDIR="$PWD/.config/zsh" zsh -l
   ```
   Run from the repo root. Verifies the config loads cleanly without
   touching `$HOME`. Iterate here until clean.

2. **Deploy + smoke test:**
   ```bash
   ./bootstrap.sh
   ```
   Open a new terminal window (not `exec zsh` inside an old session — that
   inherits stale env). Confirm:
   - Starship prompt renders
   - `Ctrl-R` opens fzf history search
   - `cd <repo-path>` triggers mise activation (if `.mise.toml` present)
   - `git <Tab>` shows git subcommand completions
   - `brew <Tab>` shows brew completions
   - `ssh <Tab>` shows known hosts
   - Arrow keys do substring history search after typing a prefix

3. **Per-function spot check:** Run a handful of ported functions
   (`mkd`, `targz`, `fs`, `ncs`) to confirm zsh semantics didn't break them.

## Existing files in $HOME to clean up

After `ZDOTDIR` is set in `~/.zshenv`, zsh stops reading the following files
(they become orphaned, not removed). The deploy should explicitly handle them:

- `~/.zprofile` — currently a one-line `brew shellenv` that macOS created.
  Its content is superseded by `$ZDOTDIR/.zprofile`. **Delete** as part of
  deploy.
- `~/.zsh_history` — existing history (a few hundred lines from before the
  shell switch). `HISTFILE` now points at `$ZDOTDIR/.zsh_history`. **Move**
  the old file to the new location so existing history is preserved:
  `mv ~/.zsh_history "$ZDOTDIR/.zsh_history"` (only if the destination does
  not yet exist).
- `~/.zsh_sessions/` — managed by macOS for per-session history. Harmless if
  left alone. No action needed.

These steps run once, during deploy. Add them to `bootstrap.sh` as a guarded
one-shot block, or document them as a manual post-deploy step. Plan will
decide.

## Rollback

If something goes wrong post-deploy:

```bash
cd ~/code/github/robinbowes/dotfiles
git revert <deploy-commit-sha>
./bootstrap.sh -f
chsh -s /opt/homebrew/bin/bash   # if you also want to revert the shell
```

The `chsh` change is independent of the dotfiles change — you can revert the
files without changing shells, or vice versa.

## Out of scope

- No zsh prompt theme (starship handles this).
- No migration of `.brew`, `.osx`, `.gitconfig`, `.vimrc`, etc. — they're
  shell-independent.
- No changes to the `claude/` subdirectory.
- `atuin` stays commented out (matches current state).
