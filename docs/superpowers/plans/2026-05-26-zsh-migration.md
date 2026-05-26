# Zsh Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the existing bash interactive shell configuration with an idiomatic zsh setup using antidote as the plugin manager, ZDOTDIR-based layout under `~/.config/zsh/`, and starship for the prompt.

**Architecture:** A one-line `~/.zshenv` points zsh at `$ZDOTDIR=~/.config/zsh`. `.zprofile` runs `brew shellenv`. `.zshrc` loads antidote (homebrew-installed, no fallback), sources the plugin bundle, then sources every file in `conf.d/*.zsh` in numeric-prefix order. Each `conf.d/` file owns one concern (options, path, exports, aliases, functions, completions, keybindings, integrations, local overrides).

**Tech Stack:** zsh 5.9, antidote (homebrew), starship, fzf, mise, Homebrew (Apple Silicon).

**Spec:** [`docs/superpowers/specs/2026-05-26-zsh-migration-design.md`](../specs/2026-05-26-zsh-migration-design.md)

---

## Conventions used in this plan

- All paths in `Create`/`Modify`/`Delete` blocks are relative to the repo root: `/Users/robin/code/github/robinbowes/dotfiles/`.
- The migration is built on a feature branch. **No file lands in `$HOME` until Task 13.** Until then, every change is testable in isolation via:
  ```bash
  ZDOTDIR="$PWD/.config/zsh" zsh -l
  ```
- Each task ends with a commit on the feature branch. Squash later if you prefer.
- "Verify" steps use `zsh -n <file>` (syntax-check only — does not execute) or run the isolated shell described above. Both are non-destructive.

---

## Task 0: Create the feature branch and verify clean state

**Files:**
- No files modified; branch setup only.

- [ ] **Step 1: Confirm working directory is clean**

Run:
```bash
cd /Users/robin/code/github/robinbowes/dotfiles
git status
```

Expected: `working tree clean`. If anything is dirty, stop and resolve before proceeding.

- [ ] **Step 2: Confirm you are on `main` and up to date**

Run:
```bash
git branch --show-current
git pull --ff-only origin main
```

Expected: `main` printed, then `Already up to date.` (or a fast-forward).

- [ ] **Step 3: Create the feature branch**

Run:
```bash
git checkout -b zsh-migration
```

Expected: `Switched to a new branch 'zsh-migration'`.

- [ ] **Step 4: Confirm required tools are installed locally**

Run:
```bash
command -v zsh starship fzf mise brew
zsh --version
fzf --version
```

Expected: paths for each command, zsh `5.9` or newer, fzf `0.48` or newer.

If any are missing: install via `brew install <name>` before proceeding.

- [ ] **Step 5: Install antidote via Homebrew**

Run:
```bash
brew install antidote
ls /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
```

Expected: install succeeds (or "already installed"), and the `ls` shows the file.

- [ ] **Step 6: Commit (no-op marker so the branch has at least one commit before code lands)**

Skip — no files changed yet. The branch is set up; we'll commit in Task 1.

---

## Task 1: Add the directory skeleton and `.zshenv`

**Files:**
- Create: `.zshenv`
- Create: `.config/zsh/conf.d/.gitkeep` (placeholder so the directory exists in git)

- [ ] **Step 1: Create `.config/zsh/conf.d/` directory**

Run:
```bash
mkdir -p .config/zsh/conf.d
touch .config/zsh/conf.d/.gitkeep
```

- [ ] **Step 2: Create `.zshenv`**

Create file `.zshenv` with this exact content:

```zsh
# Sets ZDOTDIR so zsh reads all other config from ~/.config/zsh/.
# This file is the one zsh file that MUST live at $HOME.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
```

- [ ] **Step 3: Syntax-check**

Run:
```bash
zsh -n .zshenv
```

Expected: exits 0, no output.

- [ ] **Step 4: Commit**

```bash
git add .zshenv .config/zsh/conf.d/.gitkeep
git commit -m "Add ZDOTDIR bootstrap and conf.d skeleton"
```

---

## Task 2: Create `.zprofile`

**Files:**
- Create: `.config/zsh/.zprofile`

- [ ] **Step 1: Create `.config/zsh/.zprofile`**

Create file `.config/zsh/.zprofile` with this exact content:

```zsh
# Login-shell init. Runs once per login.
# Keep this file PATH/env-only; interactive concerns go in .zshrc.

# Homebrew shellenv: sets PATH, MANPATH, INFOPATH, HOMEBREW_PREFIX, etc.
eval "$(/opt/homebrew/bin/brew shellenv)"
```

- [ ] **Step 2: Syntax-check**

Run:
```bash
zsh -n .config/zsh/.zprofile
```

Expected: exits 0.

- [ ] **Step 3: Commit**

```bash
git add .config/zsh/.zprofile
git commit -m "Add .zprofile with brew shellenv"
```

---

## Task 3: Create `.zsh_plugins.txt`

**Files:**
- Create: `.config/zsh/.zsh_plugins.txt`

- [ ] **Step 1: Create `.config/zsh/.zsh_plugins.txt`**

Create file `.config/zsh/.zsh_plugins.txt` with this exact content:

```
# Plugins loaded by antidote (declarative, hand-edited).
# Load order matters: fast-syntax-highlighting and history-substring-search
# must be the last two entries, in that order.

zsh-users/zsh-completions
zsh-users/zsh-autosuggestions
Aloxaf/fzf-tab
ohmyzsh/ohmyzsh path:plugins/colored-man-pages
zdharma-continuum/fast-syntax-highlighting
zsh-users/zsh-history-substring-search
```

- [ ] **Step 2: Commit**

```bash
git add .config/zsh/.zsh_plugins.txt
git commit -m "Add antidote plugin list"
```

---

## Task 4: Create `.zshrc` (skeleton)

**Files:**
- Create: `.config/zsh/.zshrc`

- [ ] **Step 1: Create `.config/zsh/.zshrc`**

Create file `.config/zsh/.zshrc` with this exact content:

```zsh
# Interactive-shell init.
# Order: antidote -> plugin bundle -> conf.d/*.zsh (in numeric order).

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

# User configuration, sourced in numeric-prefix order.
# The (N) glob qualifier makes the loop safe if conf.d/ is empty.
for f in "${ZDOTDIR}"/conf.d/*.zsh(N); do
  source "$f"
done
unset f
```

- [ ] **Step 2: Syntax-check**

Run:
```bash
zsh -n .config/zsh/.zshrc
```

Expected: exits 0.

- [ ] **Step 3: Verify the isolated-shell test command works**

Run:
```bash
ZDOTDIR="$PWD/.config/zsh" zsh -i -c 'echo loaded OK; exit'
```

Expected: antidote downloads the plugin bundle on first run (output may include `git clone` lines from antidote itself), then prints `loaded OK`. No `command not found` errors.

If antidote isn't found, the script prints the install hint and `return 1`s — fix the brew install and rerun.

- [ ] **Step 4: Commit**

```bash
git add .config/zsh/.zshrc
git commit -m "Add .zshrc that loads antidote and sources conf.d"
```

---

## Task 5: Add `conf.d/00-options.zsh`

**Files:**
- Create: `.config/zsh/conf.d/00-options.zsh`
- Delete: `.config/zsh/conf.d/.gitkeep` (no longer needed once a real file is present)

- [ ] **Step 1: Create `.config/zsh/conf.d/00-options.zsh`**

Create file `.config/zsh/conf.d/00-options.zsh` with this exact content:

```zsh
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
```

- [ ] **Step 2: Remove `.gitkeep`**

Run:
```bash
rm .config/zsh/conf.d/.gitkeep
```

- [ ] **Step 3: Syntax-check and load-test**

Run:
```bash
zsh -n .config/zsh/conf.d/00-options.zsh
ZDOTDIR="$PWD/.config/zsh" zsh -i -c 'setopt | grep -E "autocd|extendedglob|sharehistory" ; echo HIST=$HISTSIZE'
```

Expected: syntax check exits 0; the second command prints (at least) `autocd`, `extendedglob`, `sharehistory`, and `HIST=200000`.

- [ ] **Step 4: Commit**

```bash
git add .config/zsh/conf.d/00-options.zsh .config/zsh/conf.d/.gitkeep
git commit -m "Add 00-options.zsh (setopt + history config)"
```

---

## Task 6: Add `conf.d/10-path.zsh`

**Files:**
- Create: `.config/zsh/conf.d/10-path.zsh`

- [ ] **Step 1: Create `.config/zsh/conf.d/10-path.zsh`**

Create file `.config/zsh/conf.d/10-path.zsh` with this exact content:

```zsh
# PATH management using zsh's typed `path` array.
# `brew shellenv` (run in .zprofile) has already put homebrew dirs in $path.

# Keep $path deduplicated automatically.
typeset -aU path

# Prepended in highest-precedence-first order.
path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  $path
)

# Conditional entries.
[[ -n ${GOPATH:-} && -d $GOPATH/bin ]] && path=("$GOPATH/bin" $path)
[[ -n ${PG_VERSION:-} && -d /opt/homebrew/opt/postgresql@${PG_VERSION}/bin ]] \
  && path=("/opt/homebrew/opt/postgresql@${PG_VERSION}/bin" $path)

# Per-host overrides (gitignored). Create this file by hand on machines that
# need extra path entries; it's never synced from the dotfiles repo.
[[ -r "${ZDOTDIR}/path.local" ]] && source "${ZDOTDIR}/path.local"
```

- [ ] **Step 2: Syntax-check and load-test**

Run:
```bash
zsh -n .config/zsh/conf.d/10-path.zsh
ZDOTDIR="$PWD/.config/zsh" zsh -i -c 'echo $PATH | tr : "\n" | head -5'
```

Expected: the first few entries are `$HOME/bin`, `$HOME/.local/bin`, `$HOME/.cargo/bin`, then homebrew paths.

- [ ] **Step 3: Commit**

```bash
git add .config/zsh/conf.d/10-path.zsh
git commit -m "Add 10-path.zsh (zsh typed path array)"
```

---

## Task 7: Add `conf.d/20-exports.zsh`

**Files:**
- Create: `.config/zsh/conf.d/20-exports.zsh`

- [ ] **Step 1: Create `.config/zsh/conf.d/20-exports.zsh`**

Create file `.config/zsh/conf.d/20-exports.zsh` with this exact content:

```zsh
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
```

- [ ] **Step 2: Syntax-check and load-test**

Run:
```bash
zsh -n .config/zsh/conf.d/20-exports.zsh
ZDOTDIR="$PWD/.config/zsh" zsh -i -c 'echo "$EDITOR $LANG $MANPAGER"'
```

Expected: prints `vim en_GB.UTF-8 less -X`.

- [ ] **Step 3: Commit**

```bash
git add .config/zsh/conf.d/20-exports.zsh
git commit -m "Add 20-exports.zsh (env vars from .exports)"
```

---

## Task 8: Add `conf.d/30-aliases.zsh`

**Files:**
- Create: `.config/zsh/conf.d/30-aliases.zsh`

- [ ] **Step 1: Create `.config/zsh/conf.d/30-aliases.zsh`**

Create file `.config/zsh/conf.d/30-aliases.zsh` with this exact content:

```zsh
# Aliases. Ported from the bash .aliases.
# The `h` alias is rewritten for zsh; everything else is a direct port.

# --- Navigation -------------------------------------------------------------
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"

# --- Shortcuts --------------------------------------------------------------
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias ubnt="cd ~/Workspace/Clients/ubnt"
alias g="git"
alias gcm="git commit -m"
alias gsa="git sync-all"
alias h='fc -li 1'             # numbered history with timestamps (zsh idiom)
alias j="jobs"
alias v="vim"

# --- ls colour flag --------------------------------------------------------
if ls --color > /dev/null 2>&1; then
  colorflag="--color=auto"
else
  colorflag="-G"
fi

alias l="ls -l ${colorflag}"
alias la="ls -la ${colorflag}"
alias lsd='ls -l '"${colorflag}"' | grep "^d"'
alias ls="command ls ${colorflag}"

export LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'

# --- Misc shell -----------------------------------------------------------
alias sudo='sudo '
alias gurl='curl --compressed'
alias week='date +%V'

# Catch-all updater
alias update='sudo softwareupdate -i -a; brew update; brew upgrade; brew cleanup; npm update npm -g; npm update -g; sudo gem update'

# Network / sysadmin
alias ips="ifconfig -a | grep -o 'inet6\\? \\(\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\)\\|[a-fA-F0-9:]\\+\\)' | sed -e 's/inet6* //'"
alias whois="whois -h whois-servers.net"
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\\: .*|GET \\/.*\""

# Hash fallbacks (BSD systems lack GNU coreutils)
command -v md5sum > /dev/null || alias md5sum="md5"
command -v sha1sum > /dev/null || alias sha1sum="shasum"

# Clipboard / cleanup
alias c="tr -d '\\n' | pbcopy"
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"
alias rot13='tr a-zA-Z n-za-mN-ZA-M'
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl"

# Finder visibility
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# Misc
alias urlencode='python -c "import sys
if sys.version_info[0] < 3:
  import urllib
  qp = urllib.quote_plus
else:
  import urllib.parse
  qp = urllib.parse.quote_plus
print(qp(sys.argv[1]))"'

alias mergepdf='/System/Library/Automator/Combine\ PDF\ Pages.action/Contents/Resources/join.py'
alias spotoff="sudo mdutil -a -i off"
alias spoton="sudo mdutil -a -i on"
alias plistbuddy="/usr/libexec/PlistBuddy"
alias badge="tput bel"
alias map="xargs -n1"

# HTTP method shortcuts (lwp-request)
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
  alias "$method"="lwp-request -m '$method'"
done
unset method

# Terminal title
alias cwdcmd='echo -ne "\\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\\007"'

# Fun
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume 7'"
alias hax="growlnotify -a 'Activity Monitor' 'System error' -m 'WTF R U DOIN'"

alias marked="mk"

# Postgres
alias pg_start="launchctl load ~/Library/LaunchAgents"
alias pg_stop="launchctl unload ~/Library/LaunchAgents"
```

- [ ] **Step 2: Syntax-check and load-test**

Run:
```bash
zsh -n .config/zsh/conf.d/30-aliases.zsh
ZDOTDIR="$PWD/.config/zsh" zsh -i -c 'alias g; alias h; alias GET'
```

Expected:
```
g=git
h='fc -li 1'
GET='lwp-request -m '\''GET'\'''
```

- [ ] **Step 3: Commit**

```bash
git add .config/zsh/conf.d/30-aliases.zsh
git commit -m "Add 30-aliases.zsh (ported from .aliases)"
```

---

## Task 9: Add `conf.d/40-functions.zsh`

**Files:**
- Create: `.config/zsh/conf.d/40-functions.zsh`

- [ ] **Step 1: Create `.config/zsh/conf.d/40-functions.zsh`**

Create file `.config/zsh/conf.d/40-functions.zsh` with this exact content:

```zsh
# Functions. Ported from the bash .functions.
# Most are POSIX-ish; per-function notes are inline where zsh differs.

# Simple calculator
calc() {
  local result=""
  result="$(printf "scale=10;$*\n" | bc --mathlib | tr -d '\\\n')"
  if [[ "$result" == *.* ]]; then
    printf "$result" |
      sed -e 's/^\./0./'        \
          -e 's/^-\./-0./'      \
          -e 's/0*$//;s/\.$//'
  else
    printf "$result"
  fi
  printf "\n"
}

# Create a directory and cd into it. zsh's cd takes only one arg, so use $1.
mkd() {
  mkdir -p "$1" && cd "$1"
}

# cd to the top-most Finder window
cdf() {
  cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"
}

# .tar.gz an arg, preferring zopfli > pigz > gzip
targz() {
  local tmpFile="${@%/}.tar"
  tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1

  local size
  size=$(
    stat -f"%z" "${tmpFile}" 2> /dev/null;
    stat -c"%s" "${tmpFile}" 2> /dev/null
  )

  local cmd=""
  if (( size < 52428800 )) && hash zopfli 2> /dev/null; then
    cmd="zopfli"
  elif hash pigz 2> /dev/null; then
    cmd="pigz"
  else
    cmd="gzip"
  fi

  echo "Compressing .tar using \`${cmd}\`…"
  "${cmd}" -v "${tmpFile}" || return 1
  [ -f "${tmpFile}" ] && rm "${tmpFile}"
  echo "${tmpFile}.gz created successfully."
}

# Size of a file or dir
fs() {
  local arg
  if du -b /dev/null > /dev/null 2>&1; then
    arg=-sbh
  else
    arg=-sh
  fi
  if [[ -n "$@" ]]; then
    du $arg -- "$@"
  else
    du $arg .[^.]* *
  fi
}

# Create a data URL from a file
dataurl() {
  local mimeType
  mimeType=$(file -b --mime-type "$1")
  if [[ $mimeType == text/* ]]; then
    mimeType="${mimeType};charset=utf-8"
  fi
  echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# git.io short URL
gitio() {
  if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Usage: gitio slug url"
    return 1
  fi
  curl -i http://git.io/ -F "url=${2}" -F "code=${1}"
}

# Tiny HTTP server
server() {
  local port="${1:-8000}"
  sleep 1 && open "http://localhost:${port}/" &
  python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

# Tiny PHP server
phpserver() {
  local port="${1:-4000}"
  local ip
  ip=$(ipconfig getifaddr en1)
  sleep 1 && open "http://${ip}:${port}/" &
  php -S "${ip}:${port}"
}

# Compare original and gzipped file size
gz() {
  local origsize gzipsize ratio
  origsize=$(wc -c < "$1")
  gzipsize=$(gzip -c "$1" | wc -c)
  ratio=$(echo "$gzipsize * 100/ $origsize" | bc -l)
  printf "orig: %d bytes\n" "$origsize"
  printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio"
}

# Pretty-print JSON
json() {
  if [ -t 0 ]; then
    python -mjson.tool <<< "$*" | pygmentize -l javascript
  else
    python -mjson.tool | pygmentize -l javascript
  fi
}

# Verbose dig
digga() {
  dig +nocmd "$1" any +multiline +noall +answer
}

# UTF-8 byte escape
escape() {
  printf "\\\x%s" $(printf "$@" | xxd -p -c1 -u)
  if [ -t 1 ]; then echo; fi
}

# Decode \x{ABCD}-style Unicode escapes
unidecode() {
  perl -e "binmode(STDOUT, ':utf8'); print \"$@\""
  if [ -t 1 ]; then echo; fi
}

# Get a character's Unicode code point
codepoint() {
  perl -e "use utf8; print sprintf('U+%04X', ord(\"$@\"))"
  if [ -t 1 ]; then echo; fi
}

# Show CN/SAN entries from an SSL cert
getcertnames() {
  if [ -z "${1}" ]; then
    echo "ERROR: No domain specified."
    return 1
  fi

  local domain="${1}"
  echo "Testing ${domain}…"
  echo

  local tmp
  tmp=$(echo -e "GET / HTTP/1.0\nEOT" | openssl s_client -connect "${domain}:443" 2>&1)

  if [[ "${tmp}" == *"-----BEGIN CERTIFICATE-----"* ]]; then
    local certText
    certText=$(echo "${tmp}" | openssl x509 -text -certopt "no_header, no_serial, no_version, no_signame, no_validity, no_issuer, no_pubkey, no_sigdump, no_aux")
    echo "Common Name:"
    echo
    echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//"
    echo
    echo "Subject Alternative Name(s):"
    echo
    echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
      | sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
    return 0
  else
    echo "ERROR: Certificate not found."
    return 1
  fi
}

# Add note to Notes.app
note() {
  local title body
  if [ -t 0 ]; then
    title="$1"
    body="$2"
  else
    title=$(cat)
  fi
  osascript >/dev/null <<EOF
tell application "Notes"
  tell account "iCloud"
    tell folder "Notes"
      make new note with properties {name:"$title", body:"$title" & "<br><br>" & "$body"}
    end tell
  end tell
end tell
EOF
}

# Add reminder to Reminders.app
remind() {
  local text
  if [ -t 0 ]; then
    text="$1"
  else
    text=$(cat)
  fi
  osascript >/dev/null <<EOF
tell application "Reminders"
  tell the default list
    make new reminder with properties {name:"$text"}
  end tell
end tell
EOF
}

# Remove quarantine xattrs from downloaded files
unquarantine() {
  for attribute in com.apple.metadata:kMDItemDownloadedDate com.apple.metadata:kMDItemWhereFroms com.apple.quarantine; do
    xattr -r -d "$attribute" "$@"
  done
}

# Grunt: install plugins as devDependencies
gi() {
  local IFS=,
  eval npm install --save-dev grunt-{"$*"}
}

# NATS context selector (uses fzf)
ncs() {
  local choice
  choice="$(
    {
      nats context list --json 2>/dev/null | jq -r '.[] | .name' | sort -f
      echo "(unselect)"
    } | fzf --prompt='NATS context> ' --height=40% --reverse
  )" || return 1
  [[ -n "$choice" ]] || return 1
  if [[ "$choice" == "(unselect)" ]]; then
    nats context unselect
    local rc=$?
    unset NATS_CONTEXT
    [[ -n "${TMUX-}" ]] && tmux select-pane -T "ctx:unselected"
    return $rc
  fi
  export NATS_CONTEXT="$choice"
  echo "exported env var: NATS_CONTEXT=$NATS_CONTEXT"
  [[ -n "${TMUX-}" ]] && tmux select-pane -T "ctx:${NATS_CONTEXT}"
}
```

- [ ] **Step 2: Syntax-check and basic load-test**

Run:
```bash
zsh -n .config/zsh/conf.d/40-functions.zsh
ZDOTDIR="$PWD/.config/zsh" zsh -i -c 'type mkd targz fs ncs | head -20'
```

Expected: `type` reports each as `is a shell function`. No `not found` errors.

- [ ] **Step 3: Spot-check `mkd` (the only function with a deliberate behaviour change vs bash)**

Run:
```bash
ZDOTDIR="$PWD/.config/zsh" zsh -i -c '
  cd /tmp
  rm -rf zsh-migration-test
  mkd zsh-migration-test
  pwd
  rmdir /tmp/zsh-migration-test
'
```

Expected: prints `/tmp/zsh-migration-test`. Confirms the bash-to-zsh `cd "$1"` change works.

- [ ] **Step 4: Commit**

```bash
git add .config/zsh/conf.d/40-functions.zsh
git commit -m "Add 40-functions.zsh (ported from .functions; mkd uses \$1)"
```

---

## Task 10: Add `conf.d/50-completions.zsh`

**Files:**
- Create: `.config/zsh/conf.d/50-completions.zsh`

- [ ] **Step 1: Create `.config/zsh/conf.d/50-completions.zsh`**

Create file `.config/zsh/conf.d/50-completions.zsh` with this exact content:

```zsh
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
```

- [ ] **Step 2: Syntax-check and load-test**

Run:
```bash
zsh -n .config/zsh/conf.d/50-completions.zsh
ZDOTDIR="$PWD/.config/zsh" zsh -i -c '
  zstyle -L ":completion:*" matcher-list
  ls "${ZDOTDIR}/.zcompdump"
'
```

Expected: prints a `zstyle` line containing `m:{a-zA-Z}={A-Za-z}`, then the path to `.zcompdump`.

- [ ] **Step 3: Commit**

```bash
git add .config/zsh/conf.d/50-completions.zsh
git commit -m "Add 50-completions.zsh (compinit + zstyles)"
```

---

## Task 11: Add `conf.d/60-keybindings.zsh`

**Files:**
- Create: `.config/zsh/conf.d/60-keybindings.zsh`

- [ ] **Step 1: Create `.config/zsh/conf.d/60-keybindings.zsh`**

Create file `.config/zsh/conf.d/60-keybindings.zsh` with this exact content:

```zsh
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
```

- [ ] **Step 2: Syntax-check and load-test**

Run:
```bash
zsh -n .config/zsh/conf.d/60-keybindings.zsh
ZDOTDIR="$PWD/.config/zsh" zsh -i -c 'bindkey | grep history-substring'
```

Expected: four lines binding `^[[A`, `^[[B`, `^P`, `^N` to `history-substring-search-up`/`-down`.

- [ ] **Step 3: Commit**

```bash
git add .config/zsh/conf.d/60-keybindings.zsh
git commit -m "Add 60-keybindings.zsh (history substring search bindings)"
```

---

## Task 12: Add `conf.d/70-integrations.zsh` and `conf.d/99-local.zsh`

**Files:**
- Create: `.config/zsh/conf.d/70-integrations.zsh`
- Create: `.config/zsh/conf.d/99-local.zsh`

- [ ] **Step 1: Create `.config/zsh/conf.d/70-integrations.zsh`**

Create file `.config/zsh/conf.d/70-integrations.zsh` with this exact content:

```zsh
# Third-party tool integrations.
# Each is guarded so the file is harmless if the tool isn't installed.

# Starship prompt
(( $+commands[starship] )) && eval "$(starship init zsh)"

# fzf — Ctrl-T (file), Ctrl-R (history), Alt-C (cd).
# Tab-completion via fzf is provided by the Aloxaf/fzf-tab plugin, not here.
(( $+commands[fzf] )) && source <(fzf --zsh)

# mise — version manager activation hook.
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# iTerm2 shell integration (file is only present if installed via iTerm2 menu)
[[ -e "${HOME}/.iterm2_shell_integration.zsh" ]] \
  && source "${HOME}/.iterm2_shell_integration.zsh"

# atuin — kept commented to match the previous bash setup.
# (( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"
```

- [ ] **Step 2: Create `.config/zsh/conf.d/99-local.zsh`**

Create file `.config/zsh/conf.d/99-local.zsh` with this exact content:

```zsh
# Per-host local additions. Same convention as the bash setup.
# ~/.extra is gitignored (lives outside this repo) and holds machine-specific
# secrets or overrides.
[[ -r "${HOME}/.extra" ]] && source "${HOME}/.extra"
```

- [ ] **Step 3: Syntax-check and full-load smoke test**

Run:
```bash
zsh -n .config/zsh/conf.d/70-integrations.zsh
zsh -n .config/zsh/conf.d/99-local.zsh
ZDOTDIR="$PWD/.config/zsh" zsh -i -c '
  echo "starship: $(command -v starship)"
  echo "fzf: $(command -v fzf)"
  echo "mise: $(command -v mise)"
  echo "prompt-loaded: $([[ -n $STARSHIP_SESSION_KEY ]] && echo yes || echo no)"
  bindkey | grep -c fzf
'
```

Expected: each tool path printed; `prompt-loaded: yes`; the `bindkey | grep -c fzf` count is at least `3` (Ctrl-T, Ctrl-R, Alt-C all bind through fzf).

- [ ] **Step 4: Run an end-to-end interactive smoke test**

Run:
```bash
ZDOTDIR="$PWD/.config/zsh" zsh -l
```

This drops you into an isolated zsh login shell using the new config. Try:
- See the starship prompt render.
- Type `git che<Tab>` — fzf-tab should open a picker.
- Press `Ctrl-R` — fzf history search should appear.
- Type `cd ..<Up>` — substring search should match prior `cd ..` commands.
- Type `exit` to return to your previous shell.

- [ ] **Step 5: Commit**

```bash
git add .config/zsh/conf.d/70-integrations.zsh .config/zsh/conf.d/99-local.zsh
git commit -m "Add 70-integrations.zsh and 99-local.zsh"
```

---

## Task 13: Update `bootstrap.sh` to reload via `exec zsh -l` and clean up orphans

**Files:**
- Modify: `bootstrap.sh:152-155` (the `reload_config` function)
- Modify: `bootstrap.sh` (add an `cleanup_legacy_zsh_state` function called from `main`)

- [ ] **Step 1: Replace `reload_config`**

In `bootstrap.sh`, replace this block:

```bash
reload_config() {
  # shellcheck source=/dev/null
  . ~/.bash_profile
}
```

with:

```bash
reload_config() {
  # We're a bash script; we can't reload an interactive zsh in our parent.
  # Re-exec into a zsh login shell so the user lands in the new env immediately.
  exec zsh -l
}
```

- [ ] **Step 2: Add `cleanup_legacy_zsh_state`**

In `bootstrap.sh`, immediately above the `reload_config` function, add:

```bash
cleanup_legacy_zsh_state() {
  # macOS auto-created ~/.zprofile is now orphaned (ZDOTDIR moves it).
  if [[ -f "$HOME/.zprofile" ]]; then
    local zprofile_size
    zprofile_size=$(wc -c < "$HOME/.zprofile" | tr -d ' ')
    # Only remove if it's the small macOS-default file (< 200 bytes). Hand-edited
    # versions are preserved; the user can clean them up manually.
    if (( zprofile_size < 200 )); then
      echo "Removing orphaned ~/.zprofile (superseded by \$ZDOTDIR/.zprofile)"
      rm "$HOME/.zprofile"
    else
      echo "WARN: ~/.zprofile is larger than expected; leaving it in place."
      echo "      Review and remove manually if it's no longer needed."
    fi
  fi

  # Existing ~/.zsh_history would be stranded; relocate it once.
  local new_histfile="$HOME/.config/zsh/.zsh_history"
  if [[ -f "$HOME/.zsh_history" && ! -f "$new_histfile" ]]; then
    echo "Relocating ~/.zsh_history -> $new_histfile"
    mv "$HOME/.zsh_history" "$new_histfile"
  fi
}
```

- [ ] **Step 3: Call the cleanup function from `main`**

In `bootstrap.sh`, find:

```bash
main() {
  pre_flight_check
  initialize
  parse_cmdline "$@"
  if check_for_changed_files ; then
    sync_files
    reload_config
  fi
}
```

Replace it with:

```bash
main() {
  pre_flight_check
  initialize
  parse_cmdline "$@"
  if check_for_changed_files ; then
    sync_files
    cleanup_legacy_zsh_state
    reload_config
  fi
}
```

- [ ] **Step 4: Lint**

Run:
```bash
shellcheck bootstrap.sh
```

Expected: no errors. (Warnings are OK; pre-existing ones remain unchanged.)

- [ ] **Step 5: Commit**

```bash
git add bootstrap.sh
git commit -m "bootstrap: exec zsh -l on reload, clean up orphan zsh files"
```

---

## Task 14: Add `antidote` to `.brew`

**Files:**
- Modify: `.brew` (insert one line in a sensible location)

- [ ] **Step 1: Insert `brew install antidote`**

`.brew` is a long install script. Open it, find a section near the other shell-related installs (search for `brew install bash` or the start of the file). Add this line on its own:

```bash
# zsh plugin manager
brew install antidote
```

Pick a location that groups it with related installs (near `brew install bash` or `brew install zsh` if those exist; otherwise put it just below the `brew upgrade` line near the top).

- [ ] **Step 2: Lint**

Run:
```bash
shellcheck .brew
```

Expected: no new errors introduced. (Pre-existing warnings unchanged.)

- [ ] **Step 3: Commit**

```bash
git add .brew
git commit -m "brew: install antidote (required by zsh setup)"
```

---

## Task 15: Delete the bash files from the repo

**Files:**
- Delete: `.bash_profile`
- Delete: `.bashrc`
- Delete: `.git-prompt.sh`
- Delete: `.fzf`
- Delete: `.path`
- Delete: `.mise`
- Delete: `.ssh_completion`
- Delete: `.aliases`
- Delete: `.exports`
- Delete: `.functions`

- [ ] **Step 1: Remove the files**

Run:
```bash
git rm \
  .bash_profile \
  .bashrc \
  .git-prompt.sh \
  .fzf \
  .path \
  .mise \
  .ssh_completion \
  .aliases \
  .exports \
  .functions
```

Expected: each path printed with `rm` prefix.

- [ ] **Step 2: Verify `.inputrc` is still present**

Run:
```bash
ls .inputrc
```

Expected: `.inputrc` exists. (Kept intentionally — readline tweaks for python REPL etc.)

- [ ] **Step 3: Commit**

```bash
git commit -m "Remove bash interactive config files (superseded by zsh setup)"
```

---

## Task 16: Verify `Taskfile.yaml` still round-trips correctly

**Files:**
- No modifications expected, but verify.

- [ ] **Step 1: Read the relevant task**

Read `Taskfile.yaml`, focus on the `dotfiles:pull` task. The `find` command should already recurse into subdirectories (it does — `find .` walks the tree by default).

- [ ] **Step 2: Dry-run mental check**

The `find` command in `dotfiles:pull` is:

```yaml
find . \
  -path ./.git -prune -o \
  -path ./claude -prune -o \
  -type f \
  ! -name 'LICENSE-MIT.txt' \
  ...
```

`.config/zsh/conf.d/*.zsh` matches `-type f` and isn't excluded, so it round-trips. Same for `bootstrap.sh`'s `check_for_changed_files`. No change needed.

- [ ] **Step 3: Commit (no-op; nothing changed)**

Skip — no files modified.

---

## Task 17: Final pre-deploy verification

**Files:**
- No files modified.

- [ ] **Step 1: Run the full isolated config**

Run:
```bash
ZDOTDIR="$PWD/.config/zsh" zsh -l
```

In the resulting shell, verify by hand:

| Check | Command | Expected |
|---|---|---|
| Starship prompt | (look) | Prompt rendered by starship, not the default `%` |
| Aliases | `alias g` | `g=git` |
| Functions | `type mkd` | `mkd is a shell function` |
| PATH | `echo $path[1]` | `/Users/robin/bin` (or the first prepended entry) |
| Options | `setopt \| grep -i autocd` | prints `autocd` |
| Completion | `ls /opt/<Tab>` | menu of `/opt/...` items appears |
| fzf-tab | `git che<Tab>` | fzf picker opens |
| fzf history | `Ctrl-R` | fzf history opens |
| mise | `mise --version` | a version printed |
| Substring history | type any letter then `<Up>` | scrolls history matching the prefix |

Type `exit` to leave.

- [ ] **Step 2: Lint final state**

Run:
```bash
shellcheck bootstrap.sh
git status
git log --oneline main..HEAD
```

Expected: shellcheck clean; `git status` clean; commit log shows the per-task commits since `main`.

- [ ] **Step 3: Squash-or-keep decision**

If you want a single clean commit on `main`, run:

```bash
git rebase -i main
```

and squash the per-task commits. Skip this step if you'd rather merge with the full task history.

- [ ] **Step 4: No commit yet**

Don't deploy in this task. Task 18 is the actual deploy.

---

## Task 18: Deploy to `$HOME`

**Files:**
- All files in the branch are rsynced to `$HOME` via `bootstrap.sh`.

- [ ] **Step 1: Sanity check current shell**

Run:
```bash
echo $SHELL
echo "current process: $(ps -p $$ -o comm=)"
```

Expected: `$SHELL` shows `/opt/homebrew/bin/zsh` (set by `chsh`), current process shows whatever shell you're running this from. Either is fine.

- [ ] **Step 2: Run bootstrap**

Run:
```bash
./bootstrap.sh
```

Expected output:
- `git pull` runs (may report `Already up to date.`)
- A list of files to be created/overwritten is printed
- Prompt: `Proceed? (y/n)` — type `y`
- `rsync` runs
- `Removing orphaned ~/.zprofile (superseded by $ZDOTDIR/.zprofile)` (if applicable)
- `Relocating ~/.zsh_history -> /Users/robin/.config/zsh/.zsh_history` (if applicable)
- The script `exec zsh -l`s — your shell is replaced with the new zsh

You should land in the new zsh with the starship prompt. If something goes wrong, see "Rollback" below.

- [ ] **Step 3: Smoke test in the deployed shell**

Repeat the table from Task 17 Step 1 but in this real shell. All checks should pass.

- [ ] **Step 4: Open a brand-new terminal window**

Critical — `exec zsh -l` inherits the parent's env. A brand-new terminal proves the config works from cold start. Open one and re-run the smoke checks.

- [ ] **Step 5: Push the branch and open a PR (optional)**

If you keep the dotfiles repo open for review:

```bash
git push -u origin zsh-migration
gh pr create --title "Migrate interactive shell from bash to zsh" \
  --body "$(cat <<'EOF'
## Summary
Replaces the bash interactive configuration with an idiomatic zsh setup:
antidote plugin manager (homebrew), ZDOTDIR-based layout under ~/.config/zsh/,
starship prompt, fzf-tab + history substring search.

Removes .bash_profile, .bashrc, .git-prompt.sh, .fzf, .path, .mise,
.ssh_completion, .aliases, .exports, .functions. Keeps .inputrc.

See spec: docs/superpowers/specs/2026-05-26-zsh-migration-design.md

## Test plan
- [x] Isolated `ZDOTDIR=... zsh -l` test
- [x] `bootstrap.sh` deploy + smoke test
- [x] Fresh terminal smoke test
EOF
)"
```

Skip if you typically merge to `main` locally without a PR.

- [ ] **Step 6: Merge to `main`**

If you went the PR route, merge in the GitHub UI. Otherwise:

```bash
git checkout main
git merge --ff-only zsh-migration
```

---

## Rollback (if needed)

If the new shell is broken and you want to back out:

```bash
cd ~/code/github/robinbowes/dotfiles

# 1. Undo the deploy commit on main (or whatever the merge produced)
git revert <commit-sha>

# 2. Re-deploy the previous state
./bootstrap.sh -f

# 3. (Optional) switch shell back to bash
chsh -s /opt/homebrew/bin/bash
```

The `chsh` is independent of dotfiles — you can revert just the files (keeping zsh as the shell), revert just the shell (keeping the new dotfiles), or both.

---

## Self-review notes

Spec coverage check:

- ✅ ZDOTDIR layout (Tasks 1, 2)
- ✅ `.zprofile` with brew shellenv (Task 2)
- ✅ `.zshrc` with antidote + conf.d loop (Task 4)
- ✅ `.zsh_plugins.txt` with the agreed plugin list (Task 3)
- ✅ All nine `conf.d/` files (Tasks 5, 6, 7, 8, 9, 10, 11, 12)
- ✅ `.zshenv` at $HOME (Task 1)
- ✅ Hardcoded antidote homebrew path with bail-out (Task 4)
- ✅ Bash files removed (Task 15), `.inputrc` kept (Task 15 Step 2)
- ✅ `bootstrap.sh` reload via `exec zsh -l` (Task 13)
- ✅ Cleanup of orphan `~/.zprofile` and `~/.zsh_history` (Task 13)
- ✅ `brew install antidote` added to `.brew` (Task 14)
- ✅ Taskfile compatibility verified (Task 16)
- ✅ Test approach (isolated, then deploy, then fresh terminal) (Tasks 4, 12, 17, 18)
- ✅ Rollback documented (above)
