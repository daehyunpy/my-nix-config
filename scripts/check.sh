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

if [[ "$scope" == all || "$scope" == format ]]; then
  printf '\n==> Checking Nix formatting\n'
  files=()
  while IFS= read -r -d '' file; do
    if [[ -s "$file" ]]; then
      files+=("./$file")
    fi
  done < <(git ls-files --cached --others --exclude-standard -z -- '*.nix')
  if [[ ${#files[@]} -gt 0 ]]; then
    nix shell --no-update-lock-file --inputs-from ./linux nixpkgs#nixfmt \
      --command nixfmt --check "${files[@]}"
  fi
fi

if [[ "$scope" == all || "$scope" == linux ]]; then
  printf '\n==> Evaluating Linux: daehyun@charon\n'
  nix eval --no-update-lock-file --raw './linux#homeConfigurations."daehyun@charon".activationPackage.drvPath'
  printf '\n'
fi

if [[ "$scope" == all || "$scope" == darwin ]]; then
  for host in apollo thales; do
    printf '\n==> Evaluating Darwin: %s\n' "$host"
    nix eval --no-update-lock-file --raw "./darwin#darwinConfigurations.$host.system.drvPath"
    printf '\n'
  done
fi

printf '\nChecks passed (%s).\n' "$scope"
