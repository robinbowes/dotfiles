#!/usr/bin/env bash

set -euo pipefail

# ── Configuration ────────────────────────────────────────
OP_VAULT="Backups"
OP_ITEM="Personal Home Directory"
BACKUP_FILE_NAME="secure_content-$(gdate -Isec).tar.gz"
# ─────────────────────────────────────────────────────────

echo "Creating backup file $BACKUP_FILE_NAME"

tar czf "$BACKUP_FILE_NAME" \
  --exclude '.DS_Store' \
  --exclude '.aws/cli/cache/*' \
  --exclude '.aws/sso/cache/*' \
  --exclude '.config/gcloud/logs/*' \
  --exclude '.config/gcloud/virtenv/*' \
  --exclude '.config/iterm2/sockets/*' \
  --exclude '.config/op/op-daemon.sock' \
  --exclude '.gnupg/S.*' \
  --exclude '.ssh/agent' \
  --exclude '.ssh/stratus*' \
  .aws \
  .config \
  .extra \
  .gitconfig \
  .gitconfig.local \
  .gitconfig.personal \
  .gitconfig.synadia \
  .gnupg* \
  .keys \
  .ssh \
  .terraform* \
  Taskfile.yaml

if [[ ! -f "$BACKUP_FILE_NAME" ]]; then
  echo "ERROR: file not found: $BACKUP_FILE_NAME" >&2
  exit 1
fi

# Require the token in the environment
if [[ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]]; then
  echo "ERROR: OP_SERVICE_ACCOUNT_TOKEN is not set" >&2
  exit 1
fi

# Build a label from the filename (e.g. "backup-2026-04-15.tar.gz")
label="$(basename "$BACKUP_FILE_NAME")"
# Escape periods in label name to keep 1Password happy
label="${label//./\\.}"

echo "Attaching ${label} to '${OP_ITEM}' in vault '${OP_VAULT}'..."

op item edit "$OP_ITEM" \
  --vault "$OP_VAULT" \
  "${label}[file]=${BACKUP_FILE_NAME}"

echo "Deleting backup file $BACKUP_FILE_NAME"

rm -f "$BACKUP_FILE_NAME"

echo "Done."
