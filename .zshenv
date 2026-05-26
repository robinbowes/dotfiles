# Sets ZDOTDIR so zsh reads all other config from ~/.config/zsh/.
# This file is the one zsh file that MUST live at $HOME.
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
