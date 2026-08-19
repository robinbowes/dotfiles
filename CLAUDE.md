# dotfiles

Personal dotfiles, deployed to `$HOME` by **copying**, not symlinking. Editing a
file here does **not** change live behaviour until it is synced.

## Deployment

Two directions, and they can clobber each other:

| Direction | Command | Notes |
| --- | --- | --- |
| repo → `$HOME` | `./bootstrap.sh` (`-f` to skip the prompt) | `git pull origin main`, then `rsync -av . ~`, then `exec zsh -l` |
| `$HOME` → repo | `task dotfiles:pull` | Copies files that differ in `$HOME` back over the repo copies |

**Before editing, know which way the last sync went.** `task dotfiles:pull`
overwrites repo files with the `$HOME` copies, so running it while the repo holds
newer, un-synced edits silently reverts them.

**`bootstrap.sh` runs `git pull origin main` first.** Don't run it from a feature
branch — it merges `main` into whatever branch is checked out. Sync only from
`main`, after merging.

**`rsync` runs without `--delete`.** Deleting a file here does not remove it from
`$HOME`; do that by hand.

Excluded from both directions: `.git/`, `claude/`, `.claude/`, `docs/`,
`bootstrap.sh`, `README.md`, the licences, and generated zsh state
(`.zsh_plugins.zsh`, `.zcompdump*`, `.zsh_history`).

## Layout

- `.vimrc` — the whole vim config; `.vim/init.vim` is a symlink to it
- `.vim/pack/<author>/start/<plugin>` — plugins as **git submodules**, loaded by
  `packloadall`. Updating one is a submodule pointer bump, committed here.
- `.vim/after/plugin/*.vim` — local overrides and custom linter definitions,
  loaded after the packages
- `.config/`, `bin/`, `claude/` — XDG config, scripts, Claude Code snapshots
- `.config/nvim/` is an **unmodified LazyVim starter and is not in use** — vim is
  the editor here. Don't change it expecting an effect.

## Testing vim changes without deploying

Run vim against the repo copy directly, so `$HOME` stays untouched:

```bash
REPO=~/code/github.com/robinbowes/dotfiles
vim -N --cmd "set packpath=$REPO/.vim" \
       --cmd "set rtp=$REPO/.vim,\$VIMRUNTIME,$REPO/.vim/after" \
       -u "$REPO/.vimrc" path/to/file
```

Add `-X -n --not-a-term` and `-S script.vim` for a headless check. For ALE, wait
in a `sleep 500m` loop and read `ale#engine#GetLoclist(bufnr(''))` — results are
async, so asserting immediately gives a false negative.

## ALE

Linters and fixers are configured in `.vimrc` (`g:ale_linters`, `g:ale_fixers`).
Two behaviours that bite:

- **`g:ale_linters` is an override map, not an allowlist.** A filetype with no
  key falls back to ALE's defaults, and a filetype ALE has no default for falls
  all the way through to `'all'` — every linter registered for it. `g:ale_fixers`
  is different: it falls back to a `'*'` key, which is unset here, so no fixer
  runs unless named.
- **Executable lookup falls back to `$PATH`.** `ale#path#FindExecutable` tries the
  project-local path first, then the bare command name, even with
  `..._use_global` at 0. Combined with `g:ale_fix_on_save = 1`, a fixer naming a
  tool that happens to be installed globally will run on files whose project
  never asked for it.

TypeScript uses `tsgo` (`.vim/after/plugin/ale-tsgo.vim`), a custom LSP linter
driving `tsc --lsp --stdio`. TypeScript 7 dropped the `tsserver` binary and
speaks LSP directly, so ALE's built-in `tsserver` linter is dead here. The repos
this targets are still on TS 6, where the linter stays silent until they migrate.
Formatting is **not** wired to ALE — `oxfmt` runs at the CLI, and letting an LSP
formatter near these files would fight it.
