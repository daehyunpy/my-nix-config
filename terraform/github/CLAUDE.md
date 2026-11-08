# GitHub Repository Configuration

`main.tf` manages the `main-protection` repository ruleset for `daehyunpy/my-nix-config`, separately from Nix. Use `github_repository_ruleset`: the provider's classic REST branch protection resource rejects personal-account repositories. CI workflow implementation remains in `.github/workflows/validate.yml` at the repository root.

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

## Existing Ruleset and Local State

The backend is local: `terraform.tfstate` in this module directory. Preserve existing state when moving work between worktrees. If `github_repository_ruleset.main` is absent from state, initialize the module and import the existing ruleset before planning or applying:

```sh
terraform init
env GITHUB_TOKEN="$(gh auth token)" terraform import \
  github_repository_ruleset.main my-nix-config:26810140
```

`terraform destroy` removes the ruleset and its protection; it is not a cleanup step.
