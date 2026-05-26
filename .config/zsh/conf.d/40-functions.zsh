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
