#!/usr/bin/env bash
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
validator="$script_dir/validate-manager-cert.sh"
bash_bin="${BASH}"
debug_cert="0x2e8:5fbe1d09ef7b52ba35166a119b76b97cc14f85bba8e63d53810fb8468294cabb"
valid_cert="0x400:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

if "$bash_bin" "$validator" "" >/dev/null 2>&1; then
  echo "empty identity was accepted" >&2
  exit 1
fi

if "$bash_bin" "$validator" "$debug_cert" >/dev/null 2>&1; then
  echo "Android Debug identity was accepted" >&2
  exit 1
fi

"$bash_bin" "$validator" "$valid_cert" >/dev/null
