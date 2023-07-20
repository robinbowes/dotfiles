#!/usr/bin/env bash
# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.

# Load boxen environment, if present
# shellcheck disable=SC1091
[ -f /opt/boxen/env.sh ] && . /opt/boxen/env.sh

# new pyenv initialisation
eval "$(pyenv init --path)"

OLD_GITPROMPT="${OLD_GITPROMPT:-}"
PS1="${PS1:-}"
GIT_PROMPT_OLD_DIR_WAS_GIT="${GIT_PROMPT_OLD_DIR_WAS_GIT:-}"

# .golang needs to run before .path
declare -a extra_files=(
  ~/.golang
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
#  ~/.condo_init
)
for extra_file in "${extra_files[@]}"; do
  # shellcheck disable=SC1090
  [[ -r $extra_file ]] && . "$extra_file"
done
unset extra_file

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Append to the Bash history file, rather than overwriting it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null
done

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

# If possible, add tab completion for many more commands
declare -a completion_files=(
  /etc/bash_completion
  /usr/share/bash-completion/bash_completion
  /usr/local/etc/bash_completion.d/brew
  /usr/local/etc/bash_completion.d/git-completion.bash
  /usr/local/etc/bash_completion.d/git-prompt.sh
  /usr/local/etc/bash_completion.d/pyenv.bash
  /usr/local/etc/bash_completion.d/tmux
)
command -v brew >/dev/null && completion_files+=("$(brew --prefix)/etc/bash_completion")

for completion_file in "${completion_files[@]}" ; do
  # shellcheck disable=SC1090
  [ -f "$completion_file" ] && source "$completion_file"
done

# initialize nodenv
command -v nodenv &> /dev/null && eval "$(nodenv init -)"

# initialize rbenv
command -v rbenv &> /dev/null && eval "$(rbenv init -)"

# set up iTerm2 shell integration
# shellcheck disable=SC1090
test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"
