#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
cd "${repo_root}"

files=()

while IFS= read -r file; do
  files+=("${file}")
done < <(
  find .codex/environments .codex/scripts -type f \
    \( -name '*.toml' -o -name '*.sh' \) 2>/dev/null | sort
)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No shared Codex files found."
  exit 0
fi

patterns=(
  '/Users/'
  '~/.'
  '\.ssh'
  '\.netrc'
  'BEGIN [A-Z ]*PRIVATE KEY'
  '-----BEGIN'
  'Authorization:[[:space:]]'
  'Bearer[[:space:]]+[A-Za-z0-9._-]{10,}'
  'gh[pousr]_[A-Za-z0-9]{20,}'
  'xox[baprs]-[A-Za-z0-9-]+'
)

failed=0

for pattern in "${patterns[@]}"; do
  if rg -n -- "${pattern}" "${files[@]}"; then
    failed=1
  fi
done

if (( failed )); then
  cat >&2 <<'EOF'
error: Shared Codex files contain content that looks machine-specific or
sensitive. Keep tracked .codex files repo-relative and secret-free.
EOF
  exit 1
fi

echo "Shared Codex files passed the sensitivity check."
