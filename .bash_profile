# Add `~/bin` to the `$PATH`
export PATH="$HOME/.rbenv/bin:$HOME/bin:$PATH"

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
  [ -r "$file" ] && source "$file"
done
unset file

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
which grunt &> /dev/null && eval "$(grunt --completion=bash)"

# If possible, add tab completion for many more commands
[ -f /etc/bash_completion ] && source /etc/bash_completion

[ -f /usr/share/bash-completion/bash_completion ] && source /usr/share/bash-completion/bash_completion

function parse_git_dirty {
    if [[ $(git status --porcelain 2> /dev/null) == "" ]]; then
        echo -e '\033[0;32m✔'
    else
        echo -e '\033[0;31m✗✗✗'
    fi
}

function parse_svn_dirty {
if [[ ($(svn st 2> /dev/null) == "") || ($(svn st 2> /dev/null | wc -l) == 1 && $(svn st 2> /dev/null | sed -e 's/\s*\(.\)\s*.*/\1/') == 'S') ]]; then
        echo -e '\033[0;32m✔'
    else
        echo -e '\033[0;31m✗✗✗'
    fi
}

function parse_git_branch {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/$(echo -e '\033[00m') on $(echo -e '\033[1;37m')\1$(echo -e '\033[00m')[git]$(parse_git_dirty)/"
}

function parse_svn_branch {
    svn info 2> /dev/null | grep -i url | sed -e "s#url: $REPO\/\(.*\)#$(echo -e '\033[00m') on $(echo -e '\033[1;37m')\1$(echo -e '\033[00m')[svn]$(parse_svn_dirty)#i"
}

function prompt {
    # An extravagent PS1 http://blog.bigdinosaur.org/easy-ps1-colors/
    # 30m - Black
    # 31m - Red
    # 32m - Green
    # 33m - Yellow
    # 34m - Blue
    # 35m - Purple
    # 36m - Cyan
    # 37m - White
    # 0 - Normal
    # 1 - Bold
    local BLACK="\[\033[0;30m\]"
    local BLACKBOLD="\[\033[1;30m\]"
    local RED="\[\033[0;31m\]"
    local REDBOLD="\[\033[1;31m\]"
    local GREEN="\[\033[0;32m\]"
    local GREENBOLD="\[\033[1;32m\]"
    local YELLOW="\[\033[0;33m\]"
    local YELLOWBOLD="\[\033[1;33m\]"
    local BLUE="\[\033[0;34m\]"
    local BLUEBOLD="\[\033[1;34m\]"
    local PURPLE="\[\033[0;35m\]"
    local PURPLEBOLD="\[\033[1;35m\]"
    local CYAN="\[\033[0;36m\]"
    local CYANBOLD="\[\033[1;36m\]"
    local WHITE="\[\033[0;37m\]"
    local WHITEBOLD="\[\033[1;37m\]"
    local NORMAL="\[\033[00m\]"
    # Minimal prompt
#    PS1="$WHITEBOLD# $PURPLE\u$NORMAL at $BLUE\h$NORMAL in $GREEN\w$NORMAL\$(parse_git_branch)\$(parse_svn_branch)\n  $NORMAL"
    PS1="$WHITEBOLD# $PURPLE\u$NORMAL at $BLUE\h$NORMAL in $GREEN\w$NORMAL\$(parse_git_branch)\n  $NORMAL"
    # Verbose prompt
    # PS1="$WHITEBOLD# $GREEN\u$WHITEBOLD. $BLUE\h$WHITEBOLD. $YELLOW\d$WHITE at $PURPLE\@$WHITEBOLD. $CYAN\w$NORMAL\$(parse_svn_branch)\n  $NORMAL"
}
prompt

# Load boxen environment, if present
[ -f /opt/boxen/env.sh ] && source /opt/boxen/env.sh

# initialize rbenv
eval "$(rbenv init -)"
