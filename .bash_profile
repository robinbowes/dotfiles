#!/usr/bin/env bash

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.

# Load boxen environment, if present
# shellcheck disable=SC1091
[[ -f /opt/boxen/env.sh ]] && . /opt/boxen/env.sh

# new pyenv initialisation
# eval "$(pyenv init --path)"

# .golang needs to run before .path
# .postgresql needs to run before path to set version
declare -a extra_files=(
  ~/.golang
  ~/.postgresql
  ~/.path
  ~/.bash_prompt
  ~/.python
  ~/.exports
  ~/.aliases
  ~/.functions
  ~/.extra
  ~/.java
  ~/.amazon_web_services
  ~/.google_cloud_platform
  ~/.jqconfig
  ~/.nvm/load_nvm
  ~/.gcp
#  ~/.condo_init
)
for extra_file in "${extra_files[@]}"; do
  # shellcheck disable=SC1090
  [[ -r $extra_file ]] && . "$extra_file"
done
unset extra_files

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2 | tr ' ' '\n')" scp sftp ssh

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall

# Autocomplete Grunt commands
command -v grunt &> /dev/null && eval "$(grunt --completion=bash)"

# Add completion for tfschema, if installed
tfschema_bin=$(command -v tfschema || true)
[[ -n $tfschema_bin ]] && complete -C "$tfschema_bin" tfschema

if command -v brew &>/dev/null ; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]] ; then
    . "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  else
    while read -r COMPLETION ; do
      # shellcheck disable=SC1090
      [[ -r "${COMPLETION}" ]] && . "${COMPLETION}"
    done < <(
      find "$HOMEBREW_PREFIX"/etc/bash_completion.d -type f -o -type l
    )
  fi
fi

# initialize nodenv
command -v nodenv &> /dev/null && eval "$(nodenv init -)"

# initialize rbenv
command -v rbenv &> /dev/null && eval "$(rbenv init -)"

# set up iTerm2 shell integration
# shellcheck disable=SC1090
[[ -e "${HOME}/.iterm2_shell_integration.bash" ]] && . "${HOME}/.iterm2_shell_integration.bash"

command -v fzf &>/dev/null && eval "$(fzf --bash)"

# Cross-shell prompt: https://starship.rs
command -v starship &>/dev/null && eval "$(starship init bash)"
