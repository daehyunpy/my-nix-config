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
**Reference:** Deferred phase in `docs/superpowers/specs/2026-10-18-tailscale-management-design.md` on `feat/tailscale-terraform`.
**Dependency:** Reconcile the older spec on `main` before implementation.

**Done when:**
- Home Manager installs the shared CLI, and reusable nix-darwin/NixOS modules or a Fedora/WSL vendor-service drop-in manage native services.
- Host package/service management remains separate from OpenTofu tailnet settings and deployment CI/CD.
- Device identities, authentication state, local preferences, and Apollo's encrypted-state protection are preserved; recovery access is established before migrating one host at a time.
- Actual daemon connectivity, SSH, DNS, routing, and startup behavior are verified after separately authorized activation.
