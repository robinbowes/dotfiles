#!/usr/bin/env bash

# Enable xtrace if the DEBUG environment variable is set
if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
  set -o xtrace       # Trace the execution of the script (debug)
fi

set -o errexit      # Exit on most errors (see the manual)
set -o nounset      # Disallow expansion of unset variables
set -o pipefail     # Use last non-zero exit code in a pipeline

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

# write output to stderr
echoerr() { printf "%s\n" "$*" >&2; }
exiterr() { echoerr "$@" ; exit 1; }

# prompt user to confirm an operation
confirm() {
  local prompt="$1"
  read -rp "$prompt" -n 1
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    return 0
  else
    return 1
  fi
}

# Check we have all the required tools installed
pre_flight_check() {
  local error=0
  declare -a required_cmds=(
    git
    rsync
    diff
  )
  for cmd in "${required_cmds[@]}" ; do
    if ! command -v "$cmd" >/dev/null ; then
      echoerr "Command '$cmd' not found"
      error=1
    fi
  done
  [[ error -eq 0 ]] || exit 1
}

initialize() {
  # get directory containing this script
  local dir
  local source
  source="${BASH_SOURCE[0]}"
  while [[ -h $source ]]; do # resolve $source until the file is no longer a symlink
    dir="$( cd -P "$( dirname "$source" )" >/dev/null && pwd )"
    source="$(readlink "$source")"
     # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    [[ $source != /* ]] && source="$dir/$source"
  done
  _SCRIPT_DIR="${source%/*}"
  _SCRIPT_NAME="${BASH_SOURCE[0]##*/}"
}

parse_cmdline() {
  first_param=${1:-}
  _FORCE=false
  if [[ "$first_param" == "--force" ]] || [[ "$first_param" == "-f" ]]; then
    _FORCE=true
  fi
}

check_for_changed_files() {
  cd "$_SCRIPT_DIR"

  git pull origin main || exiterr "Error updating the local working directory."

  declare -a created_files=()
  declare -a overwritten_files=()

  while read -r file ; do
    clean_file="${file#./}"
    if ! diff --brief -Bb "$clean_file" "$HOME/$clean_file" >/dev/null 2>&1 ; then
      if [[ -f "$HOME/$clean_file" ]] ; then
        overwritten_files+=("$clean_file")
      else
        created_files+=("$clean_file")
      fi
    fi
  done < <(
    find . \
      -path ./.git -prune \
      -o \
      -path ./claude -prune \
      -o \
      -path ./docs -prune \
      -o \
      -name '*' \
      ! -name 'LICENSE-MIT.txt' \
      ! -name 'README.md' \
      ! -name 'bootstrap.sh' \
      ! -name 'LICENSE-GPL.txt' \
      ! -name '.zsh_plugins.zsh' \
      ! -name '.zcompdump*' \
      ! -name '.zsh_history' \
      -type f \
      -print
  )

  local prompt=false
  if (( ${#overwritten_files[@]} > 0 )) ; then
    echo
    echo "The following files will be created in your home directory:"
    echo "${created_files[@]}"
    prompt=true
  fi

  if (( ${#overwritten_files[@]} > 0 )) ; then
    echo
    echo "The following files will be overwritten in your home directory:"
    echo "${overwritten_files[@]}"
    prompt=true
  fi

  if [[ $prompt == "true" ]] && [[ $_FORCE == "false" ]] ; then
    echo
    if ! confirm "Proceed? (y/n) " ; then
      return 1
    fi
  fi

  return 0
}

sync_files() {

  cd "$_SCRIPT_DIR"

  rsync \
    --exclude ".git/" \
    --exclude ".DS_Store" \
    --exclude "bootstrap.sh" \
    --exclude "README.md" \
    --exclude "LICENSE-GPL.txt" \
    --exclude "LICENSE-MIT.txt" \
    --exclude "claude/" \
    --exclude "docs/" \
    --exclude ".zsh_plugins.zsh" \
    --exclude ".zcompdump*" \
    --exclude ".zsh_history" \
    --exclude ".antidote/" \
    --exclude "path.local" \
    -av \
    --no-perms \
    . ~
}

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

reload_config() {
  # We're a bash script; we can't reload an interactive zsh in our parent.
  # Re-exec into a zsh login shell so the user lands in the new env immediately.
  exec zsh -l
}

# Invoke main with args if not sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2> /dev/null); then
    main "$@"
fi
