# Repository Structure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply INFRA-4's responsibility-first layout in the `docs/infra-4-structure` worktree without changing effective machine configuration, infrastructure resources, or local state.

**Architecture:** Keep separate Darwin and Linux flakes, extract ordinary shared/host modules, and move dotfile payloads without modification. Relocate only tracked OpenTofu source to `infra/tailscale/`; local operator state stays untouched until a separately authorized operational handoff. Shared validation remains the same CLI, and tests stay with their owning subsystem.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager, Bash, GitHub Actions, OpenTofu 1.13.1.

**Spec:** [Repository identity and structure](../specs/2026-11-08-repository-structure-design.md).

**Integration baseline:** `origin/main` at `01ce185`. Worktree: `.worktrees/infra-4-structure/` at the main repository root. Do not modify the main checkout, activate systems, rename the remote, push, commit, or move operator state as part of this execution.

---

## Task 1: Establish preservation baselines

**Files:** No production changes. Use disposable verification artifacts only.

- [x] Rebase the spec branch onto `origin/main`; preserve all user changes.
- [x] Review the spec against integrated Tailscale source and update its migration contract.
- [x] Inventory existing ignored local state and backups without logging contents; retain in-memory byte fingerprints and metadata for post-migration comparison. Leave their locations unchanged. Do not create additional active state copies.
- [x] Capture evaluated package selections, user identities, shell settings, Darwin defaults, sudo policy, Home Manager settings, and application lists for Apollo, Thales, and Charon. Select concrete options rather than evaluating removed compatibility options.
- [x] Capture byte fingerprints for both Nix lockfiles, the OpenTofu source/provider lock/CLI pin, and all tracked dotfile payloads.
- [x] Run the current validation baseline:

```sh
bash scripts/check.sh all
```

Expected: all checks pass; existing dirty-tree and man-cache warnings do not represent changes caused by restructuring.

## Task 2: Relocate and compose Nix environments

**Files:** Move root `home.nix` and `packages.nix` to `nix/home/default.nix` and `nix/home/packages.nix`; move `darwin/` and `linux/` to `nix/darwin/` and `nix/linux/`; move `home-files/` payloads to `dotfiles/`. Create `nix/darwin/configuration.nix`, `nix/darwin/hosts/apollo.nix`, `nix/darwin/hosts/thales.nix`, `nix/linux/configuration.nix`, and `nix/linux/hosts/charon.nix`.

- [x] Check language-server support before moving files. Nil exposes no file-operation capability, and workers had no LSP route; use filesystem moves while preserving both flake input sets, lockfiles, and exported output names.
- [x] Extract the Darwin flake's existing shared `configuration` body into its new ordinary module. Supply `self` and `nixpkgs-unstable` through explicit module arguments. Preserve every existing setting, with only module ownership changing.
- [x] Centralize common nix-homebrew and Home Manager settings in the Darwin shared module. The platform flake supplies the native integration modules explicitly:

```nix
modules = [
  nix-homebrew.darwinModules.nix-homebrew
  home-manager.darwinModules.home-manager
  ./configuration.nix
  ./hosts/apollo.nix
];
specialArgs = { inherit self nixpkgs-unstable; };
```

For Thales, use the same composition with `./hosts/thales.nix`. Preserve the original separate Home Manager definition boundaries inside `configuration.nix`:

```nix
imports = [
  { home-manager.users.daehyun = import ../home; }
  { home-manager.users.daehyun = import ./home.nix; }
];
```

Combining these into `users.daehyun.imports` changes package and Fish initialization merge order. Exact before/after evaluated inventories confirmed that the separate definitions preserve the existing order without priority overrides.

- [x] Host modules own user identity/home/shell and the existing host exceptions. Keep the Thales cask order and selections unchanged. Avoid a custom host-construction framework.
- [x] Extract Linux common setup to `nix/linux/configuration.nix`; move its home-directory and Git-email override into `hosts/charon.nix`. Pass `nixpkgs-unstable` explicitly and keep `homeConfigurations."daehyun@charon"` unchanged. Its module composition is:

```nix
modules = [
  ./configuration.nix
  ../home
  ./home.nix
  ./hosts/charon.nix
];
extraSpecialArgs = { inherit nixpkgs-unstable; };
```

- [x] Update copied sources in the shared Home Manager module to `../../dotfiles/conda`, `../../dotfiles/tmux`, and `../../dotfiles/wezterm`. Update only the source prefix in the three existing out-of-store link declarations from `.config/nix/home-files/` to `.config/nix/dotfiles/`. Preserve user-home destinations, file contents, and live-link behavior.
- [x] Remove the still-empty platform `packages.nix` files and their `home.packages` imports. Preserve all non-package platform settings; adjust unused module arguments only where those imports were their only use.
- [x] Remove the still-empty `nixos/flake.nix` and Kubernetes placeholder after confirming no real content was added concurrently. Do not create unused test directories.

## Task 3: Relocate existing infrastructure source

**Files:** Move tracked `terraform/tailscale/` source to `infra/tailscale/`; move `terraform/CLAUDE.md` to `infra/CLAUDE.md`. Keep `.gitignore` state/cache exclusions intact.

- [x] Move only tracked source, not ignored state, backups, provider caches, or credentials. Preserve all `.tf` files, policy, `.opentofu-version`, and `.terraform.lock.hcl` byte-for-byte.
- [x] Update scoped workflow commands and current source paths to `infra/tailscale/`. Preserve historical deployment evidence and the same default local backend.
- [x] Add an explicit source-layout cutover warning: existing authoritative state remains in its original operator checkout until exclusive backup/handoff verification. Do not plan or apply against an empty relocated root. Do not choose a new backend or custom state path.
- [x] Do not run authenticated planning, refresh, imports, apply, destroy, or state-mutating operations.

## Task 4: Migrate validation and current documentation

**Files:** `scripts/check.sh`, `tests/check.sh` to `scripts/check-test.sh`, `.github/workflows/validate.yml`, `README.md`, root `CLAUDE.md`, `BACKLOG.md`, and the active spec.

- [x] Preserve the check script's CLI and Git-discovery error propagation. Change only its paths:

```sh
bash scripts/check-test.sh
nix shell --no-update-lock-file --inputs-from ./nix/linux nixpkgs#nixfmt --command nixfmt --check "${files[@]}"
nix eval --no-update-lock-file --raw './nix/linux#homeConfigurations."daehyun@charon".activationPackage.drvPath'
nix eval --no-update-lock-file --raw "./nix/darwin#darwinConfigurations.$host.system.drvPath"
```

- [x] Move the existing shell regression test without changing its behavioral assertion. Update local and CI callers; leave no forwarding wrapper.
- [x] Update CI's OpenTofu pin and `-chdir` paths to `infra/tailscale/`. Keep it credential-free with backend-disabled initialization and no plan/apply steps.
- [x] Update README identity to `system-config`, explain the unchanged `~/.config/nix` checkout and separately pending remote rename, and document the new ownership boundaries and entry points. Describe existing infrastructure as implemented and deployment automation as planned.
- [x] Update root policy's project map, Nix paths, live-dotfile paths, infrastructure guide links, and machine-specific-module convention without changing authorization rules or unrelated agent setup. Keep the existing scoped infrastructure workflow guide and root policy roles distinct.
- [x] Retire delivered backlog entries INFRA-1 and INFRA-4 as requested; preserve remote rename, state handoff, Linux-build, hosted-CI, and host-cutover gates in the specification without claiming those operations completed.
- [x] Historical specs/plans retain their evidence. Add a brief supersession note to the active Tailscale design/plan if they still provide conflicting operational paths; do not rewrite historical observations or deferred behavior.

## Task 5: Integrate, review, and prove behavior

Run these checks once after all implementation slices finish; no agent runs builds, tests, formatters, or linters mid-flight.

- [x] Simplify the changed Nix composition and review all changed boundaries and callers for spec compliance and error handling. Resolve substantive findings before final verification.
- [x] Stage only owned relocated/new source files so Git-backed flakes include their imports. This is not authorization to commit.
- [x] Format only the changed Nix modules, then run:

```sh
bash scripts/check.sh all
tofu -chdir=infra/tailscale fmt -check
tofu -chdir=infra/tailscale init -backend=false -input=false -lockfile=readonly
tofu -chdir=infra/tailscale validate
```

Expected: all succeed without tailnet credentials, state creation, lockfile changes, or activation.

- [x] Repeat the selected configuration inventory at the new flake paths. Compare all captured behaviors against baseline, normalizing only relocated source/store paths. Assert exact byte equality for dotfiles, infrastructure source, and all locks.
- [x] Build both Darwin outputs without activation:

```sh
nix build --no-link --no-update-lock-file ./nix/darwin#darwinConfigurations.apollo.system
nix build --no-link --no-update-lock-file ./nix/darwin#darwinConfigurations.thales.system
```

- [x] Inspect generated Home Manager artifacts to prove copied payloads exist and out-of-store links target the new `dotfiles/` locations. These generated targets are not proof of host activation.
- [ ] Linux activation build requires an available `x86_64-linux` builder. The attempted build failed with a platform mismatch on this `aarch64-darwin` host; no remote builder is configured. Linux evaluation passed, but its build remains unverified.
- [x] Exercise the real validation CLI from outside its working directory, including its error path, and observe output/exit codes. Verify workflow/document links and no obsolete active entry points.
- [x] Verify every inventoried local state/backup file has unchanged bytes and location, remains ignored, and is absent from the staged changes and Nix source snapshots. No disposable verification scripts were added to the repository; fixture directories were cleaned by the existing regression test.
- [x] Record only exercised evidence and outstanding authorization/runtime gates in the spec and final report. No automatic commit, push, remote rename, state handoff, or activation.

## Subsequent rebase integration

Rebased onto `origin/main` at `7a26e3f`, preserving the staged implementation. Resolved the README, root policy, and shared infrastructure-guide conflicts by retaining both the new layout and upstream repository-map, safe-formatting, and provider-specific workflow changes.

The new GitHub module follows the existing directory rename into `infra/github/`. Its resource declarations and provider lock are unchanged from main; its module guide retains Terraform usage and follows the shared explicit operator-state handoff boundary. No local state moved.

The full local Nix suite and credential-free GitHub Terraform formatting, backend-disabled initialization, and validation passed after restoration. Unaffected migration files matched the temporary stash exactly, and all six current local state/backup files remained unchanged. No commit, push, activation, or authenticated infrastructure operation was performed.

A later rebase onto `c8860fb` retains the upstream split shared/provider-specific guides at their relocated paths. Current verification is recorded in the [specification evidence](../specs/2026-11-08-repository-structure-design.md#implementation-evidence).

## Requested documentation ownership and backlog closure

- [x] Move Nix-specific conventions, package policy, dotfile installation, validation, activation references, and formatting from root `CLAUDE.md` into `nix/CLAUDE.md`.
- [x] Preserve root authorization, PR/merge, worktree-cleanup, and tool-compatibility policy unchanged; link the scoped guide from the root, README, and focused Nix command.
- [x] Review current ticket criteria and merged work; remove delivered INFRA-1 and INFRA-4 without renumbering unfinished INFRA-2, INFRA-3, INFRA-5, INFRA-6, or INFRA-7.
- [x] Replace the retired backlog-anchor link with this specification's durable ticket record, and keep separately authorized operational gates visible.
