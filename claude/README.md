# Claude Code setup

Reproduces this machine's Claude Code skills and plugins on a fresh box.

## Files

- `skill-lock.json` — snapshot of `~/.agents/.skill-lock.json` (the `npx skills`
  lockfile). Pins every globally-installed skill to a source repo and commit
  hash so a fresh machine resolves to the same content.
- `settings.snippet.json` — the `enabledPlugins` and `extraKnownMarketplaces`
  blocks from `~/.claude/settings.json`. Anything personal (statusline path,
  effort level, etc.) is excluded.
- `install.sh` — bootstrap: restores skills via `npx skills` and merges the
  settings snippet into `~/.claude/settings.json`.

## Fresh-machine reproduction

```bash
cd ~/code/github/robinbowes/dotfiles
./claude/install.sh
```

What it does:

1. Copies `skill-lock.json` into `~/.agents/.skill-lock.json`.
2. Loops the lockfile and runs `npx skills add <source> -g -s <name> -y` for
   each entry. Symlinks land under `~/.claude/skills/`.
3. Merges `settings.snippet.json` into `~/.claude/settings.json` with `jq`:
   marketplaces are registered, plugins flagged enabled. Plugin payloads
   download the next time Claude Code starts.

Requires `npx` (Node 22+) and `jq` on `$PATH`.

## Updating the snapshot

After installing a new skill or plugin on this machine:

```bash
# Skills — copy the current global lockfile
cp ~/.agents/.skill-lock.json ~/code/github/robinbowes/dotfiles/claude/skill-lock.json

# Plugins — re-extract the two blocks we care about
jq '{enabledPlugins, extraKnownMarketplaces}' ~/.claude/settings.json \
  > ~/code/github/robinbowes/dotfiles/claude/settings.snippet.json
```

Then commit the diff.

## Caveats

- `npx skills` only manages **skills**. Plugins that ship slash commands,
  subagents, hooks, or output styles (`commit-commands`, `code-simplifier`,
  `explanatory-output-style`, `security-guidance`, `gopls-lsp`) must stay as
  plugins — they cannot be migrated to `npx skills`.
- The settings merge uses `jq '.[0] * .[1]'` which is a *shallow* merge at the
  top level and a recursive merge for objects. Existing keys in the destination
  file are kept; the snippet only adds/overrides `enabledPlugins` and
  `extraKnownMarketplaces`.
- Plugins are not downloaded by `install.sh`. Claude Code does that on next
  launch once the marketplaces are registered and the plugins flagged enabled.
