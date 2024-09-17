# shellcheck shell=bash

# Initialise asdf version manager

# check brew exists
command -v brew &>/dev/null || return

# define asdf init file
asdf_file="$(brew --prefix asdf)/libexec/asdf.sh"

# check & source asdf init file
# shellcheck disable=SC1090
[[ -r $asdf_file ]] && . "$asdf_file"