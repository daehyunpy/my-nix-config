#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: bash scripts/check.sh [all|format|linux|darwin]\n'
}

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 2
fi

scope=${1:-all}
case "$scope" in
  all|format|linux|darwin) ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ "$scope" == all ]]; then
  printf '\n==> Checking validation regressions\n'
  bash scripts/check-test.sh
fi

if [[ "$scope" == all || "$scope" == format ]]; then
  printf '\n==> Checking Nix formatting\n'
  file_list=$(mktemp)
  trap 'rm -f "$file_list"' EXIT
  # Discover files in the foreground so Git failures stop validation.
  git ls-files --cached --others --exclude-standard -z -- '*.nix' > "$file_list"
  files=()
  while IFS= read -r -d '' file; do
    if [[ -s "$file" ]]; then
      files+=("./$file")
    fi
  done < "$file_list"
  if [[ ${#files[@]} -gt 0 ]]; then
    nix shell --no-update-lock-file --inputs-from ./nix/linux nixpkgs#nixfmt \
      --command nixfmt --check "${files[@]}"
  fi
fi

evaluate_configurations() {
  local flake=$1 output=$2 build_attribute=$3
  printf '\n==> Evaluating %s: %s\n' "$flake" "$output"
  nix eval --no-update-lock-file --json "$flake#$output" --apply "
    configurations:
      if builtins.attrNames configurations == [] then
        throw \"No $output configurations declared in $flake\"
      else
        builtins.mapAttrs (_: configuration: configuration.$build_attribute.drvPath) configurations
  "
  printf '\n'
}

if [[ "$scope" == all || "$scope" == linux ]]; then
  evaluate_configurations ./nix/linux homeConfigurations activationPackage
fi

if [[ "$scope" == all || "$scope" == darwin ]]; then
  evaluate_configurations ./nix/darwin darwinConfigurations system
fi

printf '\nChecks passed (%s).\n' "$scope"
