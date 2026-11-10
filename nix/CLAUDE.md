# Nix Configuration

Read the [root repository policy](../CLAUDE.md), especially its [authorization boundary](../CLAUDE.md#yolo-boundary). This guide owns Nix-specific conventions and workflows; it does not authorize activation or other protected host changes. Human setup and maintenance instructions remain in [README.md](../README.md).

Paths and commands below are relative to the selected repository/worktree root, not the `nix/` directory. Run commands from that root.

## Configuration layout

- `nix/home/default.nix`, `nix/home/packages.nix` — Shared cross-platform Home Manager configuration and packages.
- `nix/darwin/` — Independent nix-darwin flake with outputs `apollo` and `thales`; shared system settings in `configuration.nix`, user overrides in `home.nix`, and machine identity/exceptions in `hosts/`.
  - `brews.nix`, `casks.nix`, `mas.nix` — Homebrew formulae, casks, and Mac App Store apps.
- `nix/linux/` — Independent standalone Home Manager flake with output `daehyun@poseidon` (`x86_64-linux`); shared setup in `configuration.nix`, user overrides in `home.nix`, and machine identity/exceptions in `hosts/`.
- `dotfiles/` — Payloads installed through Home Manager; installation behavior is described below.
- `scripts/check.sh`, `scripts/check-test.sh` — Shared local/CI Nix validation and its failure-handling regression check.

WSL uses the Linux Home Manager configuration; Windows host settings are not managed here. There is no root flake.

## Conventions and package policy

- Keep entries in `brews.nix`, `casks.nix`, and package lists sorted alphabetically. `mas.nix` is an attrset (`{ name = app-store-id; }`).
- Shared user configuration goes in `nix/home/default.nix` and `nix/home/packages.nix`. Platform-specific configuration goes in `nix/darwin/` or `nix/linux/`.
- Both flakes define a `pkgs.unstable` overlay from `nixpkgs-unstable`. Use `pkgs.unstable.<pkg>` when the stable channel is too old.
- Flakes explicitly compose ordinary modules. Shared settings belong in platform `configuration.nix` files; machine-specific overrides belong in `hosts/*.nix`, such as Thales's extra casks.
- Preserve the separate outer Home Manager user-module definitions when composing Darwin shared and platform settings. Collapsing them into `users.daehyun.imports` changes package and Fish initialization merge order.
- Keep separate Darwin and Linux input sets and lockfiles, configuration output names, and state-version baselines unless changing those is explicitly in scope.
- Prefer Homebrew for macOS applications and platform-specific packages. Install core CLI tools and services shared across macOS, Linux, and WSL using Nix instead.
- Keep shared Nix package declarations in `nix/home/packages.nix`/`nix/home/default.nix`; keep platform-specific service lifecycle configuration in the appropriate platform modules.
- Preserve unrestricted passwordless sudo (`%admin ALL=(ALL) NOPASSWD: ALL`) on macOS. This is intentional; do not replace it with password or Touch ID authentication unless explicitly requested.
- Place behavioral tests and fixtures with their owning Nix subsystem when needed; do not create empty test scaffolds. Explicitly expose applicable tests through flake `checks` outputs; test directories are not automatically discovered.

## Dotfile installation

`dotfiles/` contents are installed via `mkOutOfStoreSymlink` (live link) or `.source` (copy). Prefer live links for configurations that change outside Nix, such as editor settings. Preserve the installation mode when relocating existing files.

- Zed, OMP models, and SSH configuration use live out-of-store links.
- Conda, tmux, and WezTerm use copied sources.
- Existing live sources target the main checkout beneath `${home.homeDirectory}/.config/nix/dotfiles/`, not a task worktree.

Before updating an existing live checkout to the new source layout, follow the [dotfile cutover and recovery requirements](../docs/superpowers/specs/2026-11-08-repository-structure-design.md#live-link-cutover-and-recovery). Moving source paths alone can break activated links; worktree evaluation and builds do not prove live activation.

## Validation

Agents must run `bash scripts/check.sh` after changing Nix configuration and before reporting completion. Run it autonomously; do not ask the user to run checks.

```bash
bash scripts/check.sh          # Full Nix validation suite
bash scripts/check.sh format   # Formatting only
bash scripts/check.sh linux    # Linux evaluation only
bash scripts/check.sh darwin   # Both Darwin evaluations
```

- The full suite checks validation error handling and formatting with `nixfmt` from the locked Linux nixpkgs input, then evaluates `daehyun@poseidon`, `apollo`, and `thales`. Scoped commands are for iteration; run the full suite before completion.
- Requires Git and Nix with `nix-command` and `flakes` enabled. Nix may fetch the pinned formatter and inputs.
- Formatting includes tracked and non-ignored untracked `.nix` files, skipping empty files. Git-backed flake evaluation excludes untracked files; stage newly imported files before evaluation, preserving unrelated staged changes.
- Checks stop at the first failure with a nonzero exit status. Fix failures within scope; report blockers and any checks not completed. Never claim validation passed when it did not.
- Evaluation does not build or activate configurations, install applications, or update lockfiles. CI calls the same script with platform-specific selectors.
- `/nix-check [files...]` provides focused, read-only formatting and syntax checks; it does not replace the full validation required above.

## Applying changes

Activation remains subject to the root authorization boundary. These are command references, not permission to execute them:

```bash
# macOS (nix-darwin)
darwin-rebuild switch --flake nix/darwin/

# Linux (home-manager)
home-manager switch --flake nix/linux#daehyun@poseidon
```

## Formatting

Run from the selected checkout root in Bash. This uses the same Git-based discovery as `scripts/check.sh`: tracked and non-ignored untracked Nix files, excluding empty files.

```bash
# Format Nix files (nixfmt is in shared packages)
bash -euo pipefail <<'BASH'
git ls-files --cached --others --exclude-standard -z -- '*.nix' |
  while IFS= read -r -d '' file; do
    if [[ -s "$file" ]]; then
      nixfmt "./$file"
    fi
  done
BASH
```
