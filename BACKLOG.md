# Backlog

- [ ] Define and enforce the scopes of `README.md` and `CLAUDE.md`, updating both to match the repository's current state.
  - Keep `README.md` human-facing: project purpose, current capabilities, prerequisites, setup, operation, and maintenance.
  - Keep `CLAUDE.md` agent-facing: repository conventions, constraints, authorization boundaries, and verification requirements.
  - Keep planned work in `BACKLOG.md`; do not describe planned CI/CD, infrastructure, or restructuring as already implemented.
  - Verify documented paths, machine names, configuration outputs, and commands against the current checkout; remove stale details.
  - Keep each piece of guidance in its owning document and cross-reference it rather than duplicating instructions or maintaining conflicting copies.

- [ ] Add CI/CD for deploying Tailscale settings managed by OpenTofu.
  - Plan changes on pull requests.
  - Apply reviewed changes through a protected deployment workflow.
  - Define secure credentials, shared state with locking, and deployment concurrency.
  - Document deployment, verification, and recovery in `README.md`.

- [ ] Add CI/CD for deploying Nix configurations to always-on servers such as Thales.
  - Validate and build each target configuration before deployment.
  - Define secure remote access and a protected workflow for activating reviewed configurations.
  - Verify server health and connectivity after activation, with a recovery path if deployment fails.
  - Document supported servers, deployment, and rollback in `README.md`.

- [ ] Rename and restructure the repository to reflect its broader purpose beyond Nix configuration.
  - State the purpose explicitly: manage my machines, development environments, and network infrastructure declaratively, with reproducible configuration and controlled deployment.
  - Treat Nix as one implementation tool, not the repository's entire purpose; include dotfiles, cross-platform machine configuration, Tailscale infrastructure managed through OpenTofu, and planned CI/CD for infrastructure and always-on servers.
  - Choose a name covering machine configuration, dotfiles, infrastructure, and deployment automation.
  - Define directory boundaries for those responsibilities while preserving shared and platform-specific configuration.
  - Update repository and checkout references, relative paths, workflows, and documentation as part of the migration.
  - Verify configuration evaluation and deployment paths after restructuring.

- [ ] Implement the deferred Tailscale Nix client/service management phase.
  - Follow the deferred phase in `docs/superpowers/specs/2026-10-18-tailscale-management-design.md` on `feat/tailscale-terraform`; reconcile the older spec on `main` before implementation.
  - Install the shared CLI through Home Manager and manage native services through reusable nix-darwin/NixOS modules or a Fedora/WSL vendor-service drop-in.
  - Keep host package/service management separate from OpenTofu tailnet settings and deployment CI/CD.
  - Preserve device identities, authentication state, local preferences, and Apollo's encrypted-state protection; establish recovery access before migrating one host at a time.
  - Verify actual daemon connectivity, SSH, DNS, routing, and startup behavior after separately authorized activation.
