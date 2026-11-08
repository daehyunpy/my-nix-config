#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

mkdir -p "$fixture/scripts"
cp "$root/scripts/check.sh" "$fixture/scripts/check.sh"
git -C "$fixture" init --quiet
printf 'invalid index\n' > "$fixture/broken-index"

if GIT_INDEX_FILE="$fixture/broken-index" bash "$fixture/scripts/check.sh" format > "$fixture/output" 2>&1; then
  cat "$fixture/output" >&2
  printf 'FAIL: formatting validation accepted a Git file-discovery failure.\n' >&2
  exit 1
fi

printf 'PASS: formatting validation rejects Git file-discovery failures.\n'
