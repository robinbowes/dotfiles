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
alias ips="ifconfig -a | grep -o 'inet6\? \(\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)\|[a-fA-F0-9:]\+\)' | sed -e 's/inet6* //'"
alias whois="whois -h whois-servers.net"
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"
alias sniff="sudo ngrep -d 'en1' -t '^(GET|POST) ' 'tcp and port 80'"
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \\/.*\""

# Hash fallbacks (BSD systems lack GNU coreutils)
command -v md5sum > /dev/null || alias md5sum="md5"
command -v sha1sum > /dev/null || alias sha1sum="shasum"

# Clipboard / cleanup
alias c="tr -d '\n' | pbcopy"
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
alias cwdcmd='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD/$HOME/~}\007"'

# Fun
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume 7'"
alias hax="growlnotify -a 'Activity Monitor' 'System error' -m 'WTF R U DOIN'"

alias marked="mk"

# Postgres
alias pg_start="launchctl load ~/Library/LaunchAgents"
alias pg_stop="launchctl unload ~/Library/LaunchAgents"
