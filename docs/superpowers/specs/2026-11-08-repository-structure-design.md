# INFRA-4 — Repository identity and responsibility-first structure

**Status:** Source-layout delivery complete; separately authorized operational gates remain pending.
**Ticket:** INFRA-4 (delivery record: [PR #9](https://github.com/daehyunpy/my-nix-config/pull/9), this specification, and Git history).
**Selected direction:** Responsibility-first layout; repository name `system-config`.

## Problem

The repository manages machine environments, dotfiles, and an existing OpenTofu-managed Tailscale tailnet, with deployment automation planned. Its current name, `my-nix-config`, presents Nix as the entire purpose. Shared Home Manager configuration lives at the root, platform flakes embed both shared settings and machine definitions, managed dotfiles live under `home-files/`, and infrastructure source lives under `terraform/tailscale/`.

The layout should make ownership clear without changing machine behavior or combining restructuring with infrastructure adoption. Current main has two Darwin outputs, `apollo` and `thales`, and one standalone Linux Home Manager output, `daehyun@charon`. These actual outputs, rather than older machine inventories in historical documents, define the migration baseline.

The implementation baseline is `origin/main` at `01ce185`, which integrated Tailscale management after this specification was first approved. Move that existing infrastructure configuration rather than creating an empty destination or restoring the older tailnet policy.

## Goals

- Name the repository `system-config`, covering machine environments, dotfiles, network infrastructure, and deployment automation.
- Separate Nix configuration, dotfile payloads, and external infrastructure by responsibility.
- Make shared platform configuration and machine-specific exceptions independently readable.
- Preserve all existing configuration outputs and effective machine settings.
- Update operational paths, validation, and documentation as one coherent cutover, with no obsolete entry-point aliases.

## Non-goals

- Consolidating flakes, updating dependencies, or changing package selections.
- Renaming hosts, changing Home Manager output keys, or adopting a full NixOS system.
- Implementing new Tailscale resources or host services, OpenTofu state backends, or deployment automation. These remain INFRA-2, INFRA-3, INFRA-5, and INFRA-6 work. Relocating existing infrastructure source is in scope.
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
│   ├── CLAUDE.md                  # Nix conventions and operational workflows
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
│   ├── CLAUDE.md                  # Existing scoped infrastructure workflow
│   ├── github/                   # Existing Terraform repository configuration
│   └── tailscale/                # Existing OpenTofu configuration
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
- `nix/CLAUDE.md` owns Nix-specific configuration conventions, package policy, validation, activation references, formatting, and dotfile installation guidance. Commands run from the repository/worktree root; the guide links to, and does not duplicate or override, the root authorization boundary.

### Dotfiles

Move the existing `home-files/` payloads to `dotfiles/` without changing their contents. A directory's presence does not mean all of its files are currently installed; do not add new Home Manager mappings during this migration.

Copied sources reference `../../dotfiles/...` from `nix/home/default.nix`. Existing out-of-store links target the corresponding files beneath `${home.homeDirectory}/.config/nix/dotfiles/...`. Their destination paths in the user's home directory remain unchanged.

Shared agent resources remain in root `.claude/`, and OMP integration remains in root `.omp/`. Repository-wide policy and authorization remain in the single root `CLAUDE.md`; Nix-specific conventions and workflows live in `nix/CLAUDE.md`, with infrastructure workflows in the existing scoped guides. Installed user configuration under `dotfiles/omp/` has a different role and is not merged into root `.omp/`.

### External infrastructure and deployment

Move the existing `terraform/tailscale/` OpenTofu root to `infra/tailscale/`, preserving its resource declarations, imports, policy, CLI pin, and provider lock byte-for-byte. Move its existing scoped workflow guide to `infra/CLAUDE.md`, updating operational paths but retaining the root authorization boundary. Host-side packages and service lifecycle configuration belong under `nix/`; they are not OpenTofu responsibilities.

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
| `terraform/tailscale/` tracked source | `infra/tailscale/`; no state or cache copied |
| `terraform/CLAUDE.md` | `infra/CLAUDE.md`; update scoped workflow references |
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

### Local infrastructure state preservation

Keep all existing ignored state files and backups local and outside Git, Nix sources, and verification output. Preserve their contents and locations during worktree implementation; do not copy an authoritative state into a second active checkout. Retain the existing broad ignore rules for state, backups, caches, saved plans, and secret variable files at the new source location.

Only tracked infrastructure source moves in this worktree. The active operator checkout's existing `terraform/tailscale/terraform.tfstate` and backups remain where they are. The relocated root is not ready for authenticated planning or application merely because validation passes: never initialize replacement resource ownership from an empty state.

Before an operator checkout adopts the new source layout, follow the scoped guide's state handoff procedure: establish exclusive ownership, validate a local recovery backup, reject an occupied destination, move the existing state and backups to that checkout's default `infra/tailscale/` location, verify unchanged bytes and bindings, and retire the former active location. This operational handoff is separate from the implementation and must not be performed implicitly by Git or validation. Keep the default local backend; do not select remote storage or a custom state path.

## Live-link cutover and recovery

Keeping the checkout location does not eliminate the `home-files/` rename hazard: already activated out-of-store links still point at the old payload paths. A Git checkout of the new layout alone can therefore break live editor, OMP, and SSH configuration links before Home Manager is activated.

Prepare and validate the migration in a separate root `.worktrees/` checkout while the main checkout and its live payloads remain unchanged. Evaluation or builds from a worktree do not prove that the main checkout's live links have been migrated.

Before moving the live checkout to the new layout, inventory the affected managed links and preserve locally modified payloads. Arrange an explicitly authorized maintenance window with the relevant activation build prepared and a recovery shell available. Treat the checkout update and authorized activation as one operational cutover; a brief broken-link interval is a known risk, not an atomic transaction. Do not rely on the SSH configuration being migrated as the only recovery path.

After authorized activation, verify that the managed destinations resolve to `dotfiles/` and their contents remain usable. If activation cannot proceed or fails, restore the previous layout and preserved local payloads before resuming normal use. Any configuration rollback also requires explicit authorization. No permanent old-path compatibility links remain after success.

Renaming the remote repository and changing remotes are separately authorized publication operations. The delivered source-layout ticket is retired from the active backlog; that retirement does not claim the remote rename, operator-state handoff, or host cutover has occurred. Those operational gates remain recorded below.

## Verification and acceptance criteria

### Repository implementation

- [x] New directories follow the ownership rules; no empty future-service scaffolds or obsolete entry points remain.
- [x] The three existing configuration outputs retain their names and evaluate at the new flake locations without lockfile updates.
- [x] Both lockfiles are unchanged, and effective package selections, identities, settings, and state-version baselines match a pre-migration inventory. Compare normalized behavior, allowing source/store paths to differ because files moved; derivation-path equality alone is not required.
- [ ] `bash scripts/check.sh all` succeeds, exercising formatting, Linux and Darwin evaluation, and validation error handling. Existing Linux and macOS CI jobs succeed through the same entry point.
- [ ] Validation-script regression coverage runs from `scripts/check-test.sh` through local validation and CI, with no old-path wrapper. Any existing subsystem tests and fixtures follow the ownership rules and remain runnable after migration.
- [ ] Build both Darwin system outputs on a suitable Darwin builder and the Linux activation package on a suitable Linux builder without activation. Record unavailable builders as unverified rather than substituting evaluation for build evidence.
- [x] Copied dotfiles are included in generated outputs, and generated live-link targets point to the intended `dotfiles/` paths without changing home-directory destinations.
- [x] Current operational documentation uses relocated entry points and distinguishes `system-config` from the retained `~/.config/nix` checkout. Historical references are not blindly rewritten.
- [x] No secrets, state files, private keys, infrastructure applies, host changes, or unrelated dependency updates are introduced.
- [x] Existing OpenTofu source, policy, CLI pin, and provider lock are byte-identical at `infra/tailscale/`; credential-free formatting, backend-disabled initialization, and validation succeed at that location.
- [x] Existing local state and backups remain ignored, local, and unchanged; no second active state is introduced. Operator documentation prevents authenticated use of the relocated root before the explicit state handoff.

### Authorized operational completion

- [ ] The remote repository is named `system-config`, and authorized local remote references use the new identity.
- [ ] Each affected machine's live-checkout cutover is coordinated with separately authorized activation; managed links resolve correctly afterward. Unavailable machines remain explicitly unverified.
- [ ] Smoke checks after authorized activation demonstrate that affected editor, OMP model configuration, and SSH configuration remain accessible without printing sensitive contents.
- [ ] No old-path compatibility symlinks or forwarding flakes remain, and recovery instructions describe restoring the old layout if activation fails.

Writing this specification or merging the structural changes does not satisfy the operational criteria by itself.

### Implementation evidence

- Rebased `docs/infra-4-structure` onto `origin/main` at `01ce185` and applied the source migration in its task worktree. The main checkout was not migrated.
- `bash scripts/check.sh all` passed after the final module correction, including formatting, malformed-Git-index failure coverage, and all three configuration evaluations. Running the script by absolute path from outside the checkout also passed; help and invalid-argument paths returned the expected 0 and 2 exit codes.
- Selected evaluated inventories matched the original baseline exactly for Apollo, Thales, and Charon, including ordered package lists and Fish initialization. The initial extraction changed Home Manager merge order; preserving the two original outer user-module definitions corrected it without priority overrides.
- All 17 tracked dotfile/infrastructure payloads and all three dependency lockfiles are byte-identical after relocation.
- Both final Darwin systems built successfully without activation. Generated Home Manager artifacts contain the three copied payloads unchanged and all three intended live links targeting `dotfiles/`.
- OpenTofu formatting, backend-disabled initialization with the read-only provider lock, and validation passed at `infra/tailscale/` with tailnet credential variables removed from the environment. No authenticated plan, refresh, import, or apply was run.
- All six inventoried local state/backup files remained unchanged at their original locations and ignored by Git. The relocated worktree root contains no active state, and the Nix source snapshot excludes state, operator secrets, worktrees, and provider caches.
- Independent Nix clarity and migration-boundary reviews found no remaining substantive issue after the merge-order correction.
- Subsequently rebased onto `origin/main` at `7a26e3f`. Preserved upstream repository-map and safe-formatting corrections and carried the newly integrated GitHub module into `infra/github/`, retaining its resource declarations and provider lock byte-for-byte. GitHub continues to use Terraform, not OpenTofu; its existing local state remains in the operator checkout until a separate handoff.
- After that rebase, the full local Nix validation and credential-free GitHub Terraform formatting, backend-disabled initialization, and validation passed. The staged migration was restored without losing unaffected files, and all six current local state/backup files were unchanged.
- Rebased again onto `origin/main` at `c8860fb`, preserving its reviewed-saved-plan workflow and split shared/provider-specific guides. The new Tailscale guide follows the directory rename into `infra/tailscale/`; command paths and links use `infra/`, and the common source-layout state-handoff gate remains enforced. All 48 unaffected migration paths matched the temporary stash exactly, all six local state/backup files were unchanged, and the full local Nix suite and integrity checks for 11 Markdown files passed.
- The pre-PR review found that crash-log exclusions were still anchored only to `terraform/`. Added matching `infra/` exclusions while retaining the original protections for operator locations awaiting handoff; all eight old/new-root crash-log cases are ignored, and production Terraform sources remain trackable. A fresh comparison against immutable `origin/main` matched all three selected evaluated inventories, 19 relocated payload/provider files, and both Nix lockfiles exactly. Credential-free checks passed for both infrastructure modules.
- At the user's request, moved Nix-specific conventions, package policy, validation, activation references, formatting, and dotfile installation guidance into `nix/CLAUDE.md`. The root guide retains unchanged repository-wide authorization, PR/merge, worktree-cleanup, and tool-compatibility rules. Retired delivered backlog entries INFRA-1 and INFRA-4 while retaining unfinished work and the operational gates in this specification.

**Unverified gates:** The Linux activation build was attempted but failed because it requires `x86_64-linux`; this `aarch64-darwin` host has no remote builder configured. Check hosted CI on the published PR; successful local checks are not hosted-CI evidence. Remote repository rename, operator-state handoff, live-link cutover, and host activation were not performed.

## Dependencies and review

Coordinate the migration with concurrent infrastructure and validation work so callers are updated once against the current integration baseline. Preserve the existing Terraform-only implementation from `01ce185` while relocating it to `infra/tailscale/`. The older Tailscale design's deferred host-service scope is not adopted by INFRA-4.

The user approved this specification, including the subsystem-local testing approach, and requested implementation after rebasing onto latest main. Local state preservation is an explicit implementation constraint. There is no scheduled deadline; host activation, remote repository rename, publication, and operator state handoff remain separately authorized operations.
