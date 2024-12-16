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

  declare -a changed_files=()

  while read -r file ; do
    clean_file="${file#./}"
    if ! diff --brief -Bb "$clean_file" "$HOME/$clean_file" ; then
      changed_files+=("$clean_file")
    fi
  done < <(
    find . \
      -path .git -prune \
      -o -name '.*' \
      -type f
  )

  if (( ${#changed_files[@]} > 0 )) && [[ $_FORCE == "false" ]]; then
    echo "The following files will be overwritten in your home directory:"
    echo "${changed_files[@]}"
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
    -av \
    --no-perms \
    . ~

  # shellcheck source=/dev/null
  . ~/.bash_profile
}

# Invoke main with args if not sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2> /dev/null); then
    main "$@"
fi
