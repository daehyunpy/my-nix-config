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

write_flake() {
  local platform=$1 output=$2 configurations=$3
  mkdir -p "$fixture/nix/$platform"
  cat > "$fixture/nix/$platform/flake.nix" <<EOF
{
  outputs = { self }: let
    package = builtins.derivation {
      name = "validation-fixture";
      system = "x86_64-linux";
      builder = "/bin/sh";
    };
  in {
    $output = $configurations;
  };
}
EOF
  git -C "$fixture" add "nix/$platform/flake.nix"
}

expect_evaluation_failure() {
  local platform=$1 diagnostic=${2:-}
  if bash "$fixture/scripts/check.sh" "$platform" > "$fixture/output" 2>&1; then
    cat "$fixture/output" >&2
    printf 'FAIL: %s validation accepted an invalid configuration set.\n' "$platform" >&2
    exit 1
  fi
  if [[ -n "$diagnostic" && "$(< "$fixture/output")" != *"$diagnostic"* ]]; then
    cat "$fixture/output" >&2
    printf 'FAIL: %s validation did not reach the failing configuration.\n' "$platform" >&2
    exit 1
  fi
}

for platform in linux darwin; do
  if [[ "$platform" == linux ]]; then
    output=homeConfigurations
    build_attribute=activationPackage
    other_platform=darwin
    other_output=darwinConfigurations
  else
    output=darwinConfigurations
    build_attribute=system
    other_platform=linux
    other_output=homeConfigurations
  fi

  write_flake "$platform" "$output" \
    "{ baseline.$build_attribute = package; extra.$build_attribute = throw \"additional configuration failed\"; }"
  expect_evaluation_failure "$platform" 'additional configuration failed'
  printf 'PASS: %s validation rejects a failing additional configuration.\n' "$platform"

  write_flake "$platform" "$output" '{}'
  expect_evaluation_failure "$platform"
  printf 'PASS: %s validation rejects an empty configuration set.\n' "$platform"

  write_flake "$platform" "$output" \
    "{ \"fixture host.with.dot\".$build_attribute = package; }"
  write_flake "$other_platform" "$other_output" 'throw "unselected platform was evaluated"'
  if ! bash "$fixture/scripts/check.sh" "$platform" > "$fixture/output" 2>&1; then
    cat "$fixture/output" >&2
    printf 'FAIL: %s validation did not isolate the selected platform and discover its configuration.\n' "$platform" >&2
    exit 1
  fi
  printf 'PASS: %s validation discovers arbitrary names without evaluating the other platform.\n' "$platform"
done
