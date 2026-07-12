#!/usr/bin/env bash
set -euo pipefail

manager_cert="${1:-}"
debug_cert="0x2e8:5fbe1d09ef7b52ba35166a119b76b97cc14f85bba8e63d53810fb8468294cabb"

if [[ ! "$manager_cert" =~ ^0x[0-9a-f]+:[0-9a-f]{64}$ ]]; then
  echo "manager certificate must be 0x<lowercase DER length hex>:<lowercase SHA-256>" >&2
  exit 1
fi

if [[ "$manager_cert" == "$debug_cert" ]]; then
  echo "Android Debug certificate is forbidden for production builds" >&2
  exit 1
fi

printf '%s\n' "$manager_cert"

