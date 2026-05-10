#!/usr/bin/env bash
set -euo pipefail

# Get the script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Navigate from ansible/scripts/ to ansible/ (parent), then add inventories
# Structure: x-infra/ansible/scripts/preflight.sh
ANSIBLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INVENTORIES_BASE="${ANSIBLE_DIR}/inventories"

check_vault_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "❌ Missing vault file: $file"
    exit 1
  fi

  if ! head -n 1 "$file" | grep -q '^\$ANSIBLE_VAULT;'; then
    echo "❌ Vault file is NOT encrypted: $file"
    echo "   Fix: ansible-vault encrypt $file"
    exit 1
  fi

  echo "✅ Vault encrypted: $file"
}

check_env_vaults() {
  local env="$1"
  local base="${INVENTORIES_BASE}/${env}/group_vars"

  echo "🔎 Checking ${env} vaults…"

  # Always required
  check_vault_file "${base}/all/vault.yml"

  # App-specific vaults (only if the file exists)
  local optional_vaults=(
    "all/vault.blogos.yml"
    "all/vault.blogos_ai.yml"
    "all/vault.go_kutt.yml"
    "all/vault.go_graphics.yml"
    "all/vault.minio.yml"
  )
  for v in "${optional_vaults[@]}"; do
    if [[ -f "${base}/${v}" ]]; then
      check_vault_file "${base}/${v}"
    fi
  done

  # Group-scoped vaults
  if [[ -d "${base}/vecicrm" ]]; then
    check_vault_file "${base}/vecicrm/vault.yml"
  fi

  if [[ -d "${base}/vecierp" ]]; then
    check_vault_file "${base}/vecierp/vault.yml"
  fi
}

echo "Running preflight…"
echo "Debug: Script directory: $SCRIPT_DIR"
echo "Debug: Inventories base: $INVENTORIES_BASE"

check_env_vaults "production"
check_env_vaults "staging"
echo "✅ Preflight passed."