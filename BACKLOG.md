# Backlog

IDs are stable: do not renumber entries when reordering them.
Remove completed items from this document; use Git history and linked pull requests for completion records. Never reuse their IDs.

## INFRA-2 — Automate Tailscale deployments

**Status:** Backlog
**Outcome:** Reviewed Tailscale settings managed by OpenTofu can be deployed through CI/CD.

**Done when:**
- Pull requests produce plans for review.
- A protected deployment workflow applies reviewed changes.
- Credentials, shared state with locking, and deployment concurrency are defined securely.
- `README.md` documents deployment, verification, and recovery.

## INFRA-3 — Automate Nix server deployments

**Status:** Backlog
**Outcome:** Reviewed Nix configurations can be deployed to always-on servers such as Thales.

**Done when:**
- Each target configuration is validated and built before deployment.
- Secure remote access and a protected workflow support activation of reviewed configurations.
- Server health and connectivity are verified after activation, with a recovery path if deployment fails.
- `README.md` documents supported servers, deployment, and rollback.

## INFRA-5 — Manage Tailscale clients and services through Nix

**Status:** Deferred
**Outcome:** Host-side Tailscale tooling and services are managed declaratively without changing device identity or existing behavior.
**References:** Deferred phase in `docs/superpowers/specs/2026-10-18-tailscale-management-design.md`; stash named `WIP: Tailscale Nix configuration (not applied)` from `feat/tailscale-iac`; earlier committed implementation on `review/cursor-tailscale-pr1` at `314e775`.
**Work left behind:** The host-side implementation and output rename were left out of `feat/tailscale-terraform`. The later draft remains in the stash from `feat/tailscale-iac`, not in that branch's committed files. The earlier shared CLI, native daemon module, output rename, and module-validation CI remain committed on `review/cursor-tailscale-pr1`.
**Dependency:** Reconcile the older spec on `main` before implementation.

**Done when:**
- Home Manager installs the shared CLI, and reusable nix-darwin/NixOS modules or a Fedora/WSL vendor-service drop-in manage native services.
- Review both the earlier Cursor implementation and the later stash against current package versions and host state before reusing them. Do not merge the Cursor branch wholesale: its `infra/tailscale/` root, Muse-tag policy, historical Thales identity/subnet, and assumption that Poseidon uses NixOS are superseded by the Terraform-only design and current inventory.
- Rename the standalone Home Manager output from `daehyun@charon` to `daehyun@poseidon`, updating all active commands, checks, and documentation without an alias. Do not rename the OS, WSL registration, or Tailscale node.
- Host package/service management remains separate from OpenTofu tailnet settings and deployment CI/CD.
- Device identities, authentication state, local preferences, and Apollo's encrypted-state protection are preserved; recovery access is established before migrating one host at a time.
- Actual daemon connectivity, SSH, DNS, routing, and startup behavior are verified after separately authorized activation.

## INFRA-6 — Choose OpenTofu state storage and execution

**Status:** Backlog
**Outcome:** Select a state-management/backend strategy after starting with default local state.

**Done when:**
- Evaluate all options without preselecting one: default local state, SSH-based execution, SMB/shared filesystems, rclone for backups or S3 serving, HTTP state services, S3-compatible storage, PostgreSQL, and managed cloud/state services.
- Compare locking/concurrent writes, atomicity and interrupted-write recovery, durability/versioning, authentication/encryption, backups, operating complexity, and recovery when the tailnet or a host is unavailable.
- Treat Thales as a candidate, not a selected host; no protocol, product, or custom state location is committed to before evaluation.
- Plan any future migration with protected backups and verified locking/recovery before moving authoritative state.

## INFRA-7 — Discover all declared Nix configurations in shared validation

**Status:** Backlog
**Outcome:** Local and CI validation cover every declared Home Manager and Darwin configuration without maintaining host-name lists.
**Reference:** Discovery-based CI changes on `feat/tailscale-iac`, excluded from the Terraform-only port.
**Work left behind:** The discovery implementation and workflow guidance remain committed on `feat/tailscale-iac` at `3cb17b6`; they were not brought into `feat/tailscale-terraform`. Use that branch as the reference when adapting this work to the current shared validation and single-file agent policy.

**Done when:**
- Move configuration discovery into `scripts/check.sh`, keeping it the shared local/CI entry point rather than restoring duplicated inline workflow commands.
- Evaluate every declared `homeConfigurations` activation package and `darwinConfigurations` system, and fail when a configuration set is empty or any evaluation fails.
- Preserve existing formatting, file-discovery error handling, platform selectors, and credential-free Terraform validation.
- Verify coverage with an additional temporary configuration and verify that empty sets and failed evaluations return nonzero.
- Document the discovery convention in `nix/CLAUDE.md` and update human-facing validation guidance as needed. Do not port `.github/workflows/CLAUDE.md`; repository-wide agent policy stays in the single root file.

## INFRA-8 — Rename the GitHub repository through Terraform

**Status:** Backlog
**Outcome:** The existing `daehyunpy/my-nix-config` repository is renamed to `system-config` without replacing the repository or weakening its protections.
**Reference:** Remaining rename gate in the [repository structure spec](docs/superpowers/specs/2026-11-08-repository-structure-design.md#authorized-operational-completion).

**Done when:**
- Set `github_repository.config.name` to `system-config` in `infra/github/main.tf`, preserving the resource address, `prevent_destroy`, and the ruleset's repository reference.
- Privately back up the existing local state and review a saved plan containing only the intended in-place rename and dependent reference updates, with no resource creation, destruction, replacement, or unrelated setting changes.
- Apply only the exact reviewed plan after explicit user approval. Verify the repository's immutable identity, history, access, and existing ruleset identity/protections are preserved; require a fresh refreshed plan with exit 0 and no changes.
- Update Git remotes and current documentation, operational links, and import examples to the new name. Keep the checkout at `~/.config/nix` and preserve local state and backup locations; do not rewrite historical evidence indiscriminately.

## INFRA-9 — Verify Linux Home Manager configuration builds

**Status:** Backlog
**Outcome:** The declared Linux Home Manager activation package is successfully built with the committed flake inputs, without activating it.
**Reference:** Outstanding Linux build verification in the [repository structure plan](docs/superpowers/plans/2026-11-08-repository-structure.md#task-5-integrate-review-and-prove-behavior).

**Done when:**
- Select a suitable `x86_64-linux` host or CI runner. A remote builder configured on the Mac is not required.
- Successfully run `nix build --no-link --no-update-lock-file './nix/linux#homeConfigurations."daehyun@charon".activationPackage'` on the selected Linux builder, using the committed lockfile.
- Record the tested revision, build platform, and resulting activation-package output. Evaluation or obtaining a derivation path alone does not count as build verification.
- Diagnose any build failure and review necessary configuration or dependency fixes explicitly; do not silently remove packages or update inputs to force success. Do not run Home Manager activation or change host services as part of this verification.
