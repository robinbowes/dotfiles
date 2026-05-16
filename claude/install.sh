#!/usr/bin/env bash
#
# Restore Claude Code skills and plugins on a fresh machine.
#
# Skills are installed via `npx skills` from skill-lock.json.
# Plugins are reconciled into ~/.claude/settings.json from settings.snippet.json
# (marketplaces are registered; plugins enabled flags are set). The actual
# plugin downloads happen the first time Claude Code starts.

set -o errexit
set -o nounset
set -o pipefail

if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
  set -o xtrace
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly LOCKFILE="${SCRIPT_DIR}/skill-lock.json"
readonly SETTINGS_SNIPPET="${SCRIPT_DIR}/settings.snippet.json"
readonly CLAUDE_SETTINGS="${HOME}/.claude/settings.json"
readonly AGENTS_LOCKFILE="${HOME}/.agents/.skill-lock.json"

log() { printf "[claude-install] %s\n" "$*"; }
die() {
  printf "[claude-install] %s\n" "$*" >&2
  exit 1
}

require() {
  command -v "$1" >/dev/null 2>&1 || die "missing required tool: $1"
}

require npx
require jq

[[ -f "${LOCKFILE}" ]] || die "lockfile not found: ${LOCKFILE}"
[[ -f "${SETTINGS_SNIPPET}" ]] || die "settings snippet not found: ${SETTINGS_SNIPPET}"

install_skills() {
  log "restoring skill lockfile to ${AGENTS_LOCKFILE}"
  mkdir -p "$(dirname "${AGENTS_LOCKFILE}")"
  cp "${LOCKFILE}" "${AGENTS_LOCKFILE}"

  local count
  count=$(jq -r '.skills | length' "${LOCKFILE}")
  log "installing ${count} skill(s) globally via npx skills"

  local name source
  while IFS=$'\t' read -r name source; do
    log "  -> ${name} (from ${source})"
    npx -y skills@latest add "${source}" -g -s "${name}" -y >/dev/null
  done < <(jq -r '.skills | to_entries[] | "\(.key)\t\(.value.source)"' "${LOCKFILE}")
}

merge_settings() {
  if [[ ! -f "${CLAUDE_SETTINGS}" ]]; then
    log "no existing ${CLAUDE_SETTINGS} — writing snippet as-is"
    mkdir -p "$(dirname "${CLAUDE_SETTINGS}")"
    cp "${SETTINGS_SNIPPET}" "${CLAUDE_SETTINGS}"
    return
  fi

  log "merging marketplaces and enabledPlugins into ${CLAUDE_SETTINGS}"
  local tmp
  tmp=$(mktemp)
  jq -s '.[0] * .[1]' "${CLAUDE_SETTINGS}" "${SETTINGS_SNIPPET}" >"${tmp}"
  mv "${tmp}" "${CLAUDE_SETTINGS}"
}

main() {
  install_skills
  merge_settings
  log "done — start Claude Code so it can download enabled plugins from their marketplaces"
}

main "$@"
