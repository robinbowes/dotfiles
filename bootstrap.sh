#!/usr/bin/env bash

set -euo pipefail

p1=${1:-}

cd "$(dirname "${BASH_SOURCE[0]}")"
git pull origin master

function doIt() {
	rsync --exclude ".git/" --exclude ".DS_Store" --exclude "bootstrap.sh" \
		--exclude "README.md" --exclude "LICENSE-GPL.txt" \
		--exclude "LICENSE-MIT.txt" -av --no-perms . ~
}

if [[ "$p1" == "--force" ]] || [[ "$p1" == "-f" ]]; then
	doIt
else
	read -rp "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt
	fi
fi
unset doIt

# shellcheck source=/dev/null
. ~/.bash_profile
