# Per-host local additions. Same convention as the bash setup.
# ~/.extra is gitignored (lives outside this repo) and holds machine-specific
# secrets or overrides.
[[ -r "${HOME}/.extra" ]] && source "${HOME}/.extra"
