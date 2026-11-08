# GitHub Repository Configuration

`main.tf` manages repository settings and the `main-protection` ruleset for `daehyunpy/my-nix-config`, separately from Nix. Use `github_repository_ruleset`: the provider's classic REST branch protection resource rejects personal-account repositories. CI workflow implementation remains in `.github/workflows/validate.yml` at the repository root.

Follow `../CLAUDE.md` for the shared Terraform workflow. Run the following commands from this module directory in the active worktree.

## Authentication

Use the existing GitHub CLI login with repository Administration read/write access. Pass its token to the provider at runtime, never in configuration or a credentials file:

```sh
env GITHUB_TOKEN="$(gh auth token)" terraform plan -detailed-exitcode
```

After reviewing the plan and obtaining authorization under the root repository policy:

```sh
env GITHUB_TOKEN="$(gh auth token)" terraform apply
```

## Existing Resources and Local State

The backend is local: `terraform.tfstate` in this module directory. Preserve existing state when moving work between worktrees. On a fresh state, initialize the module and import both existing resources before planning or applying. If state already exists, import only resources absent from it:

```sh
terraform init
env GITHUB_TOKEN="$(gh auth token)" terraform import \
  github_repository.config my-nix-config
env GITHUB_TOKEN="$(gh auth token)" terraform import \
  github_repository_ruleset.main my-nix-config:26810140
```

The repository resource has `prevent_destroy = true` because it adopts an existing repository. Keep that guard: repository deletion is not a cleanup step. Removing the ruleset separately would remove its protection.
