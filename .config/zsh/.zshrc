# Interactive-shell init.
# Order: antidote -> plugin bundle -> conf.d/*.zsh (in numeric order).

# antidote (homebrew-installed; no git fallback)
antidote_init="/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"
if [[ ! -r $antidote_init ]]; then
  print -u2 "zshrc: antidote not found at $antidote_init"
  print -u2 "       install with: brew install antidote"
  return 1
fi
source "$antidote_init"
antidote load "${ZDOTDIR}/.zsh_plugins.txt"
unset antidote_init

# User configuration, sourced in numeric-prefix order.
# The (N) glob qualifier makes the loop safe if conf.d/ is empty.
for f in "${ZDOTDIR}"/conf.d/*.zsh(N); do
  source "$f"
done
unset f
