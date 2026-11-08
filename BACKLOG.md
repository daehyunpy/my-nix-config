# Backlog

IDs are stable: do not renumber entries when reordering them.
Remove completed items from this document; use Git history and linked pull requests for completion records. Never reuse their IDs.

## INFRA-1 — Clarify documentation responsibilities

**Status:** Backlog
**Outcome:** Human documentation and agent instructions have distinct responsibilities and accurately describe the current repository.

**Done when:**
- `README.md` covers project purpose, current capabilities, prerequisites, setup, operation, and maintenance for humans.
- `CLAUDE.md` covers repository conventions, constraints, authorization boundaries, and verification requirements for agents.
- Planned work stays in `BACKLOG.md`; planned CI/CD, infrastructure, and restructuring are not described as implemented.
- Documented paths, machine names, configuration outputs, and commands match the current checkout; stale details are removed.
- Each piece of guidance lives in its owning document, with cross-references instead of duplicated or conflicting instructions.

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

## INFRA-4 — Rename and restructure the repository

**Status:** Backlog
**Outcome:** The repository reflects its purpose: manage my machines, development environments, and network infrastructure declaratively, with reproducible configuration and controlled deployment.
**Spec:** [Repository identity and structure](docs/superpowers/specs/2026-11-08-repository-structure-design.md) (approved).

**Done when:**
- The project purpose treats Nix as one implementation tool, not the entire repository; it includes dotfiles, cross-platform machine configuration, Tailscale infrastructure managed through OpenTofu, and planned CI/CD for infrastructure and always-on servers.
- The repository name covers machine configuration, dotfiles, infrastructure, and deployment automation.
- Directory boundaries separate those responsibilities while preserving shared and platform-specific configuration.
- Repository and checkout references, relative paths, workflows, and documentation are updated as part of the migration.
- Configuration evaluation and deployment paths are verified after restructuring.

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
- Document the discovery convention in the root `CLAUDE.md` and update human-facing validation guidance as needed. Do not port `.github/workflows/CLAUDE.md`; repository agent policy stays in the single root file.
