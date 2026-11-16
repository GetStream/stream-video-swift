#!/usr/bin/env bash
set -euo pipefail

helper="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/openapi_generate_helpers.sh"

if grep -n "sed -i ''" "$helper"; then
  echo "BSD sed -i remains in $helper" >&2
  exit 1
fi

dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT
printf 'func send<Response: Codable>() {}\n' > "$dir/DefaultAPI.swift"
perl -pi -e 's/send<Response: Codable>/send<Response: Decodable>/' "$dir/DefaultAPI.swift"
grep -q 'send<Response: Decodable>()' "$dir/DefaultAPI.swift"

echo "openapi_generate_helpers_test: ok"
