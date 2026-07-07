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
[[ -d ${KREW_ROOT:-$HOME/.krew}/bin ]] && path=("${KREW_ROOT:-$HOME/.krew}/bin" $path)
[[ -n ${GOPATH:-} && -d $GOPATH/bin ]] && path=("$GOPATH/bin" $path)
[[ -n ${PG_VERSION:-} && -d /opt/homebrew/opt/postgresql@${PG_VERSION}/bin ]] \
  && path=("/opt/homebrew/opt/postgresql@${PG_VERSION}/bin" $path)

# Per-host overrides (gitignored). Create this file by hand on machines that
# need extra path entries; it's never synced from the dotfiles repo.
[[ -r "${ZDOTDIR}/path.local" ]] && source "${ZDOTDIR}/path.local"
