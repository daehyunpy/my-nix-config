# GitHub Repository Configuration

`main.tf` manages repository settings and the `main-protection` ruleset for `daehyunpy/my-nix-config`, separately from Nix. Keep the existing `github_repository_ruleset` resource; CI workflow implementation remains in `.github/workflows/validate.yml` at the repository root.

Read the [shared Terraform workflow](../CLAUDE.md) for reviewed-plan approval, verification, backups, and state handoff. Run commands below from `terraform/github/` in the checkout holding this module's authoritative state.

## CLI, authentication, and checks

Use Terraform compatible with `required_version` in `main.tf` and the committed `.terraform.lock.hcl`. Use the existing GitHub CLI login with repository Administration read/write access. `gh auth token` must succeed; pass its token to the provider at runtime, never in configuration or a credentials file.

These local checks need no GitHub token. The current CI Terraform job validates Tailscale only:

```sh
terraform fmt -check
terraform init -backend=false -input=false -lockfile=readonly
terraform validate
```

## Existing resources and local state

The default local backend uses `terraform.tfstate` in this module directory. Locate existing authoritative state before starting work in another checkout; follow the shared handoff procedure rather than importing a second active copy.

For a deliberately fresh adoption, initialize and import both existing resources before planning. With existing state, import only bindings actually absent after checking inventory and ownership:

```sh
terraform init -input=false -lockfile=readonly
env GITHUB_TOKEN="$(gh auth token)" terraform import \
  github_repository.config my-nix-config
env GITHUB_TOKEN="$(gh auth token)" terraform import \
  github_repository_ruleset.main my-nix-config:26810140
```

The repository resource has `prevent_destroy = true` because it adopts an existing repository. Keep that guard: repository deletion is not a cleanup step. Deleting the ruleset removes its protection. State handoff must retain both bindings and a zero-drift refreshed plan.

## Saved-plan commands

With authoritative state and authentication established, create and inspect the artifact for the shared review gate:

```sh
umask 077
terraform init -input=false -lockfile=readonly
plan_dir="$(mktemp -d)"
env GITHUB_TOKEN="$(gh auth token)" terraform plan \
  -input=false -lock=true -out="$plan_dir/github.tfplan"
terraform show -no-color "$plan_dir/github.tfplan"
```

Stop for approval of this saved plan. After approval and the private backup below, apply it as a separate operation, retaining the same `plan_dir`:

```sh
env GITHUB_TOKEN="$(gh auth token)" terraform apply \
  -input=false -lock=true "$plan_dir/github.tfplan"
```

## Backup commands

Use this procedure for the shared before/after state-mutation backup requirement:

```sh
set -eu
umask 077
backup_dir="$HOME/.config/github-iac/backups/$(date -u +%Y-%m-%d)"
mkdir -p "$backup_dir"
backup=$(mktemp "$backup_dir/local-$(date -u +%H%M%S).XXXXXX")
terraform state pull > "$backup"
jq -e '.lineage != null and .serial != null and .resources != null' "$backup" >/dev/null
printf 'Validated private backup: %s\n' "$backup"
```

## Provider-specific verification

Compare the repository settings and ruleset against the approved changes and `main.tf`, including preserved enforcement, branch scope, bypass actors, and protection rules. Confirm both resource identities and managed values in refreshed state, then require a zero-drift result from:

```sh
env GITHUB_TOKEN="$(gh auth token)" terraform plan \
  -refresh=true -input=false -detailed-exitcode
```

Use GitHub's repository and ruleset API endpoints for independent remote verification; an apply message or Terraform state alone does not establish the effective protection policy.
