# GitHub Repository Configuration

`main.tf` manages repository settings and the `main-protection` ruleset for `daehyunpy/my-nix-config`, separately from Nix. Keep the existing `github_repository_ruleset` resource; CI workflow implementation remains in `.github/workflows/validate.yml` at the repository root.

Read the [shared Terraform workflow](../CLAUDE.md) for reviewed-plan approval, verification, backups, runtime environment loading, and state handoff. Run commands below from `infra/github/` in an operator checkout initialized against the authoritative state.

## CLI, authentication, and checks

Use Terraform 1.10 or newer, compatible with `required_version` in `main.tf`, and the committed `.terraform.lock.hcl`. Export the shared R2 environment before backend operations; the root `.env` is not loaded automatically or copied into worktrees. Supply repository Administration access through exported `GITHUB_TOKEN`: map the existing private environment value with `export GITHUB_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN"`, or use `export GITHUB_TOKEN="$(gh auth token)"` with an authenticated GitHub CLI. Keep tokens out of Terraform configuration, backend arguments, and Git. Anonymous refreshes omit administrative fields and can report misleading differences.

These local checks need no GitHub token. The current CI Terraform job validates Tailscale only:

```sh
terraform fmt -check
terraform init -backend=false -input=false -lockfile=readonly
terraform validate
```

## Existing resources and shared state

The S3 backend uses the [shared R2 settings](../backend.s3.hcl); `backend.tf` declares key `github/terraform.tfstate`. Existing local `terraform.tfstate` files (including historical source-layout paths) are migration sources, not the active default after cutover. Locate the authoritative state and follow the [shared migration procedure](../CLAUDE.md#worktree-state-handoff); selection alone is not proof of completed migration.

Never initialize an empty root and import a second copy of these managed resources. Only for a deliberately fresh adoption, after proving no authoritative state exists, initialize the selected backend and import both existing resources before planning. With existing state, import only bindings actually absent after checking inventory and ownership:

```sh
terraform init -backend-config=../backend.s3.hcl -input=false -lockfile=readonly
terraform import \
  github_repository.config my-nix-config
terraform import \
  github_repository_ruleset.main my-nix-config:26810140
```

The repository resource has `prevent_destroy = true` because it adopts an existing repository. Keep that guard: repository deletion is not a cleanup step. Deleting the ruleset removes its protection. State handoff must retain both bindings and a zero-drift refreshed plan.

## Saved-plan commands

With authoritative state and authentication established, create and inspect the artifact for the shared review gate:

```sh
umask 077
terraform init -backend-config=../backend.s3.hcl -input=false -lockfile=readonly
plan_dir="$(mktemp -d)"
terraform plan \
  -input=false -lock=true -out="$plan_dir/github.tfplan"
terraform show -no-color "$plan_dir/github.tfplan"
```

Stop for approval of this saved plan. After approval and the private backup below, apply it as a separate operation, retaining the same `plan_dir`:

```sh
terraform apply \
  -input=false -lock=true "$plan_dir/github.tfplan"
```

## Backup commands

Use this procedure for the shared before/after state-mutation backup requirement, with the authoritative backend initialized. R2 has no S3 bucket versioning; these private retained backups provide historical recovery:

```sh
set -eu
umask 077
backup_dir="$HOME/.config/github-iac/backups/$(date -u +%Y-%m-%d)"
mkdir -p "$backup_dir"
backup=$(mktemp "$backup_dir/state-$(date -u +%H%M%S).XXXXXX")
terraform state pull > "$backup"
jq -e '.lineage != null and .serial != null and .resources != null' "$backup" >/dev/null
printf 'Validated private backup: %s\n' "$backup"
```

## Provider-specific verification

Compare the repository settings and ruleset against the approved changes and `main.tf`, including preserved enforcement, branch scope, bypass actors, and protection rules. Confirm both resource identities and managed values in refreshed state, then require a zero-drift result from:

```sh
terraform plan \
  -refresh=true -input=false -detailed-exitcode
```

Use GitHub's repository and ruleset API endpoints for independent remote verification; an apply message or Terraform state alone does not establish the effective protection policy.
