# INFRA-4 — Repository identity and responsibility-first structure

**Status:** Approved
**Ticket:** [INFRA-4](../../../BACKLOG.md#infra-4--rename-and-restructure-the-repository)
**Selected direction:** Responsibility-first layout; repository name `system-config`.

## Problem

The repository manages machine environments and dotfiles, with network infrastructure and deployment automation planned. Its current name, `my-nix-config`, presents Nix as the entire purpose. Shared Home Manager configuration lives at the root, platform flakes embed both shared settings and machine definitions, and managed dotfiles live under `home-files/`.

The layout should make ownership clear without changing machine behavior or combining restructuring with infrastructure adoption. Current main has two Darwin outputs, `apollo` and `thales`, and one standalone Linux Home Manager output, `daehyun@charon`. These actual outputs, rather than older machine inventories in historical documents, define the migration baseline.

## Goals

- Name the repository `system-config`, covering machine environments, dotfiles, network infrastructure, and deployment automation.
- Separate Nix configuration, dotfile payloads, and external infrastructure by responsibility.
- Make shared platform configuration and machine-specific exceptions independently readable.
- Preserve all existing configuration outputs and effective machine settings.
- Update operational paths, validation, and documentation as one coherent cutover, with no obsolete entry-point aliases.

## Non-goals

- Consolidating flakes, updating dependencies, or changing package selections.
- Renaming hosts, changing Home Manager output keys, or adopting a full NixOS system.
- Implementing Tailscale resources or host services, OpenTofu state backends, or deployment automation. These remain INFRA-2, INFRA-3, and INFRA-5 work.
- Moving the checkout out of `~/.config/nix`, or renaming Nix's own `~/.config/nix/nix.conf`.
- Changing dotfile contents or their live-symlink versus copied-source behavior.
- Activating systems, renaming the remote repository, pushing changes, or changing local remotes without separate explicit authorization.

## Decisions and alternatives

The user selected a responsibility-first layout over machine-first organization and minimal relocation. Machine-first organization makes individual machines easy to locate but gives shared user configuration and tailnet-wide resources a less natural home. Minimal relocation has a smaller diff but retains embedded machine definitions and repeated platform wiring.

The repository will be named `system-config`. Its local checkout remains `~/.config/nix`: repository identity and checkout location do not need to match. Retaining the checkout avoids a second migration of absolute live-dotfile paths and keeps the existing Nix configuration directory intact. Documentation must explain this distinction.

Keep the independent Darwin and Linux flakes and their lockfiles. A single root flake would introduce an input-management decision beyond the directory migration. No root flake, automatic module discovery, or custom host-construction framework is introduced.

## Target layout

This tree defines ownership. Directories for unimplemented capabilities are not created merely to match the tree.

```text
system-config/
├── README.md
├── CLAUDE.md
├── BACKLOG.md
├── nix/
│   ├── home/
│   │   ├── default.nix
│   │   ├── packages.nix
│   │   └── tests/                  # Only when shared behavioral tests exist
│   ├── darwin/
│   │   ├── flake.nix
│   │   ├── flake.lock
│   │   ├── configuration.nix
│   │   ├── home.nix
│   │   ├── brews.nix
│   │   ├── casks.nix
│   │   ├── mas.nix
│   │   ├── hosts/
│   │   │   ├── apollo.nix
│   │   │   └── thales.nix
│   │   └── tests/                  # Only when platform tests exist
│   └── linux/
│       ├── flake.nix
│       ├── flake.lock
│       ├── configuration.nix
│       ├── home.nix
│       ├── hosts/
│       │   └── charon.nix
│       └── tests/                  # Only when platform tests exist
├── dotfiles/
│   ├── conda/
│   ├── direnv/
│   ├── omp/
│   ├── ssh/
│   ├── tmux/
│   ├── wezterm/
│   └── zed/
├── infra/
│   └── tailscale/                 # Owned by separate infrastructure work
│       └── tests/                # Only when infrastructure tests exist
├── scripts/
│   ├── check.sh
│   └── check-test.sh
├── docs/
│   └── superpowers/
│       ├── specs/
│       └── plans/
├── .github/
│   └── workflows/
├── .claude/
└── .omp/
```

Existing root support files, including `.gitignore`, `.env.example`, and `.envrc`, retain their roles. Ignored local secrets are not read, moved into version control, or copied into Nix sources. `.worktrees/` remains at the repository root; the main checkout remains on `main`.

## Ownership and composition

### Nix environments

- `nix/home/default.nix` owns shared Home Manager settings and dotfile installation declarations. `nix/home/packages.nix` owns shared Nix package selections.
- Each platform's `flake.nix` declares inputs, the existing output names, and explicit module composition. It does not embed machine settings or duplicate shared Home Manager integration between machines.
- `nix/darwin/configuration.nix` owns shared macOS system settings and common nix-homebrew/Home Manager integration. The flake supplies required input modules and arguments explicitly. `nix/darwin/home.nix` owns macOS user overrides.
- `nix/linux/configuration.nix` owns the common standalone Linux Home Manager setup currently embedded in its flake. `nix/linux/home.nix` retains Linux-specific user settings. No Linux system-management layer is implied.
- `hosts/*.nix` are ordinary modules, not additional flakes. They own machine identity and exceptions. Apollo and Thales retain their existing identity and settings; Thales retains its additional applications. Charon retains its home directory and Git identity override.
- Preserve each platform's existing stable and unstable package inputs and overlay behavior. Preserve `home.stateVersion`, `system.stateVersion`, application-link handling, garbage-collection settings, login shells, and unrestricted passwordless sudo.
- Preserve the Homebrew-versus-Nix package policy. Existing empty platform `packages.nix` lists and their imports are removed rather than moved; nonempty platform lists present at migration time remain platform-owned.

### Dotfiles

Move the existing `home-files/` payloads to `dotfiles/` without changing their contents. A directory's presence does not mean all of its files are currently installed; do not add new Home Manager mappings during this migration.

Copied sources reference `../../dotfiles/...` from `nix/home/default.nix`. Existing out-of-store links target the corresponding files beneath `${home.homeDirectory}/.config/nix/dotfiles/...`. Their destination paths in the user's home directory remain unchanged.

Shared agent resources remain in root `.claude/`, OMP integration remains in root `.omp/`, and all repository agent policy remains in the single root `CLAUDE.md`. Installed user configuration under `dotfiles/omp/` has a different role and is not merged into root `.omp/`.

### External infrastructure and deployment

`infra/tailscale/` is the destination for separately implemented OpenTofu tailnet configuration. Host-side packages and service lifecycle configuration belong under `nix/`; they are not OpenTofu responsibilities.

GitHub workflows remain in `.github/workflows/`. Shared validation orchestration remains in `scripts/`; subsystem tests live with their owning subsystem as described below. Future subsystem-specific deployment logic belongs with the subsystem that owns it; no generic deployment framework or empty `deploy/` hierarchy is added.

Remove the currently empty `nixos/flake.nix` and Kubernetes placeholder rather than preserving empty future subsystems. If concurrent work gives either path real content before migration, preserve and reconcile that content instead of treating it as disposable.

### Test ownership and development workflow

Keep test code in separate files within the subsystem it exercises. Shared Home Manager tests belong in `nix/home/tests/`, platform-specific tests in `nix/darwin/tests/` or `nix/linux/tests/`, and OpenTofu tests in `infra/tailscale/tests/`. Test-only fixtures stay with their tests. Do not create directories or add tests solely to populate this layout.

Nix test definitions are explicitly exposed through the appropriate flakes' `checks.<system>.<name>` outputs; directory names do not provide automatic discovery. OpenTofu test files use the subsystem-local `tests/` directory and explicit `command = plan` for plan-only checks. Planning can still require provider access; separate files do not provide execution isolation or make live infrastructure changes safe.

Tests may depend on production configuration, but runtime configuration must not depend on test fixtures or test-only helpers. Tests must isolate temporary files and state. Live tests that change host or remote infrastructure state require separate explicit authorization; they are not part of default validation.

Move the existing validation-script regression test from `tests/check.sh` to `scripts/check-test.sh`. Preserve its failure-propagation coverage and update its callers in both the validation script and CI. Do not retain an old-path wrapper. A root `tests/` directory is reserved for genuine cross-subsystem integration tests if needed later, not a mirrored hierarchy for all tests.

For new behavior or bug fixes, write a behavioral test first, observe the expected failure, implement the smallest correct change, and refactor with checks passing. Tests protect observable behavior, boundaries, errors, and invariants rather than source text, filenames, or copied defaults. Pure restructuring starts from passing baseline checks and preserves them; do not manufacture failing tests to enforce the new directory layout. Existing evaluation/build checks and smoke verification remain necessary.

These rules define where future tests belong and how behavioral changes are developed. INFRA-4 does not introduce new infrastructure resources, test suites, or validation command scopes.

## Migration contract

| Current location | Target location or treatment |
|---|---|
| Root `home.nix` | `nix/home/default.nix` |
| Root `packages.nix` | `nix/home/packages.nix` |
| `darwin/` | `nix/darwin/`, extracting shared settings and host modules |
| `linux/` | `nix/linux/`, extracting shared settings and host modules |
| `home-files/` | `dotfiles/` |
| `nixos/flake.nix`, `kubernetes/.gitkeep` | Remove only while still empty placeholders |
| `tests/check.sh` | `scripts/check-test.sh`; update validation and CI callers |
| Other scripts, workflows, agent resources, and documentation | Retain locations; update current operational references |

Preserve both lockfiles byte-for-byte unless a separately reviewed dependency change requires otherwise. Relative imports and dotfile source references must resolve within the new layout. Do not leave forwarding flakes, old directory aliases, or permanent compatibility symlinks.

The shell interface remains `bash scripts/check.sh [all|format|linux|darwin]`. Update its formatter input source to `./nix/linux`, its evaluation targets to the relocated flakes, and its regression-test invocation to `scripts/check-test.sh`. Preserve failure propagation, tracked/untracked Nix discovery, and exclusion of ignored worktrees. Existing CI jobs continue to call this interface; update the direct regression-test invocation and any path filters or direct flake references present when the migration occurs.

Update current README instructions, repository policy, backlog links, and applicable active plans. Preserve historical evidence in older specs; use explicit supersession notes for still-active instructions that conflict with this layout. This spec supersedes older path guidance only, not their infrastructure behavior or scope decisions. Do not describe planned deployments or infrastructure as already implemented.

### Operational entry points after cutover

- macOS flake: `~/.config/nix/nix/darwin`, with outputs `apollo` and `thales`.
- Linux flake: `~/.config/nix/nix/linux`, with output `daehyun@charon`.
- Repository-local checks: `bash scripts/check.sh all`.
- Input updates target `nix/darwin` or `nix/linux`; setup and activation examples use those same relocated paths.

Activation commands remain human-authorized operations, not a side effect of validation or migration scripts.

## Live-link cutover and recovery

Keeping the checkout location does not eliminate the `home-files/` rename hazard: already activated out-of-store links still point at the old payload paths. A Git checkout of the new layout alone can therefore break live editor, OMP, and SSH configuration links before Home Manager is activated.

Prepare and validate the migration in a separate root `.worktrees/` checkout while the main checkout and its live payloads remain unchanged. Evaluation or builds from a worktree do not prove that the main checkout's live links have been migrated.

Before moving the live checkout to the new layout, inventory the affected managed links and preserve locally modified payloads. Arrange an explicitly authorized maintenance window with the relevant activation build prepared and a recovery shell available. Treat the checkout update and authorized activation as one operational cutover; a brief broken-link interval is a known risk, not an atomic transaction. Do not rely on the SSH configuration being migrated as the only recovery path.

After authorized activation, verify that the managed destinations resolve to `dotfiles/` and their contents remain usable. If activation cannot proceed or fails, restore the previous layout and preserved local payloads before resuming normal use. Any configuration rollback also requires explicit authorization. No permanent old-path compatibility links remain after success.

Renaming the remote repository and changing remotes are separately authorized publication operations. Implementation can finish local restructuring without claiming that the remote has been renamed. INFRA-4 remains incomplete until the authorized rename and all applicable cutover checks have actually occurred.

## Verification and acceptance criteria

### Repository implementation

- [ ] New directories follow the ownership rules; no empty future-service scaffolds or obsolete entry points remain.
- [ ] The three existing configuration outputs retain their names and evaluate at the new flake locations without lockfile updates.
- [ ] Both lockfiles are unchanged, and effective package selections, identities, settings, and state-version baselines match a pre-migration inventory. Compare normalized behavior, allowing source/store paths to differ because files moved; derivation-path equality alone is not required.
- [ ] `bash scripts/check.sh all` succeeds, exercising formatting, Linux and Darwin evaluation, and validation error handling. Existing Linux and macOS CI jobs succeed through the same entry point.
- [ ] Validation-script regression coverage runs from `scripts/check-test.sh` through local validation and CI, with no old-path wrapper. Any existing subsystem tests and fixtures follow the ownership rules and remain runnable after migration.
- [ ] Build both Darwin system outputs on a suitable Darwin builder and the Linux activation package on a suitable Linux builder without activation. Record unavailable builders as unverified rather than substituting evaluation for build evidence.
- [ ] Copied dotfiles are included in generated outputs, and generated live-link targets point to the intended `dotfiles/` paths without changing home-directory destinations.
- [ ] Current operational documentation uses relocated entry points and distinguishes `system-config` from the retained `~/.config/nix` checkout. Historical references are not blindly rewritten.
- [ ] No secrets, state files, private keys, infrastructure applies, host changes, or unrelated dependency updates are introduced.

### Authorized operational completion

- [ ] The remote repository is named `system-config`, and authorized local remote references use the new identity.
- [ ] Each affected machine's live-checkout cutover is coordinated with separately authorized activation; managed links resolve correctly afterward. Unavailable machines remain explicitly unverified.
- [ ] Smoke checks after authorized activation demonstrate that affected editor, OMP model configuration, and SSH configuration remain accessible without printing sensitive contents.
- [ ] No old-path compatibility symlinks or forwarding flakes remain, and recovery instructions describe restoring the old layout if activation fails.

Writing this specification or merging the structural changes does not satisfy the operational criteria by itself.

## Dependencies and review

Coordinate the migration with concurrent infrastructure and validation work so callers are updated once against the current integration baseline. `infra/tailscale/` already matches the destination proposed in the older Tailscale design, but that design's deferred host-service scope is not adopted by INFRA-4.

The user approved this specification, including the subsystem-local testing approach. Implementation planning has not started. There is no scheduled deadline, and no implementation, activation, or publication is authorized by this specification alone.
