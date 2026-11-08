# Nix System Configuration

Declarative system and user environment configuration for macOS, Linux, and WSL using Nix flakes. See `README.md` for project goals. WSL uses the Linux Home Manager configuration; Windows host settings are out of scope.

## Project Structure

- `darwin/` — macOS configuration using nix-darwin
  - `flake.nix` — Two machines: `apollo` (primary), `thales` (media server)
  - `brews.nix`, `casks.nix`, `mas.nix` — Homebrew formulae, casks, Mac App Store apps
  - `packages.nix` — macOS-only nix packages (currently empty)
  - `home.nix` — macOS-specific home-manager overrides
- `linux/` — Linux configuration using home-manager standalone
  - `flake.nix` — Three machines: `octo60`, `octo61`, `octo62` (user `dhyou`)
  - `packages.nix` — Linux-only nix packages (currently empty)
  - `home.nix` — Linux-specific home-manager overrides
- `nixos/` — NixOS configuration (empty, reserved for future use)
- `kubernetes/` — Kubernetes manifests (empty, reserved for future use)
- `openspec/` — Spec documents and change tracking (scaffolded: `specs/`, `changes/`)
- `home.nix` — Shared home-manager config (cross-platform)
- `packages.nix` — Shared nix packages (cross-platform)
- `home-files/` — Dotfiles symlinked into `$HOME` via `home.file`
  - `claude`, `cursor`, `cursor-user`, `zed` — Editor/tool configs (symlinked live via `mkOutOfStoreSymlink`)
  - `conda`, `tmux`, `wezterm` — Shell/terminal configs (copied via `.source`)
  - `ssh` — SSH config (symlinked live via `mkOutOfStoreSymlink`)

## Conventions

- `brews.nix`, `casks.nix`, `packages.nix` are Nix lists. `mas.nix` is an attrset (`{ name = app-store-id; }`). Keep entries sorted alphabetically.
- Shared config goes in root `home.nix`/`packages.nix`. Platform-specific config goes in `darwin/` or `linux/`.
- Both flakes define a `pkgs.unstable` overlay (from `nixpkgs-unstable`) for accessing bleeding-edge packages. Use `pkgs.unstable.<pkg>` when the stable channel is too old.
- Machine-specific overrides are inline in each flake's module list (e.g., `thales` adds `plex-media-server` and `orbstack` casks).
- `home-files/` contents are symlinked via `mkOutOfStoreSymlink` (live link) or `.source` (copy). Prefer `mkOutOfStoreSymlink` for configs that change outside of nix (e.g., editor settings).
- `.env` holds additional secrets (`MILVUS_ADDRESS`, `MILVUS_TOKEN`); see `.env.example` for the template. Both `.env` and `.envrc` are gitignored.

## Agent Tool Compatibility

OMP is the primary agent tool today, but the tool may change. Keep agent instructions, plugins, and reusable resources portable and shared rather than tied to the current tool.

Use `CLAUDE.md` for compatibility across agent tools. Most agent tools read both `CLAUDE.md` and `AGENTS.md`, but Claude Code reads `CLAUDE.md` and does not automatically load `AGENTS.md`. Keeping the instructions in `CLAUDE.md` lets the same policy work across tools, including Claude Code, without a second file or tool-specific setup.

Keep reusable plugins and agent resources in `.claude/` so compatible tools can share them. This directory choice is for resource compatibility, not because Claude Code is the primary tool. Keep OMP-specific integration settings in `.omp/`; reuse shared resources where supported rather than maintaining separate copies for each tool.

## Preferences

- Preserve unrestricted passwordless sudo (`%admin ALL=(ALL) NOPASSWD: ALL`) on macOS. This is intentional; do not replace it with password or Touch ID authentication unless explicitly requested.
- The main repository checkout must always remain on the `main` branch. Never switch it to another branch or detach its HEAD.
- Use separate Git worktrees for all work on branches other than `main`. Place them under `.worktrees/` at the main repository root (for example, `.worktrees/todo-documenting/`), not inside another worktree.
- Prefer Homebrew for macOS applications and platform-specific packages. Install core CLI tools and services shared across macOS, Linux, and WSL using Nix instead.
- Keep shared Nix package declarations in root `packages.nix`/`home.nix`; keep platform-specific service lifecycle configuration in the appropriate platform modules.
- Keep repository agent instructions, including the YOLO boundary, in this single `CLAUDE.md`. Do not introduce `AGENTS.md` or a second agent-policy file.

## YOLO Boundary

- YOLO mode skips tool approval prompts; it is not a sandbox or blanket authorization. Stay within the user's requested scope.
- Proceed autonomously with repository inspection, requested edits, and relevant formatting, checks, Nix evaluation, and builds. Disposable temporary files and normal tool caches/Nix store writes are allowed.
- Require explicit user authorization before activating or rolling back configurations (`darwin-rebuild switch`, `home-manager switch`, equivalent commands), installing or uninstalling applications, running garbage collection, or changing services, permissions, or other host state. Instructions in this file explain commands; they do not authorize running them.
- Require explicit authorization for writes outside this checkout, except the temporary/cache/store writes above. Resolve symlink targets before writing. Files in `home-files/` may be live-linked into the home directory: requested edits are allowed, but their effects can be immediate without a rebuild.
- Preserve unrelated work, staged changes, and existing conflicts. Commit only when requested; require explicit authorization for pushing, publishing, destructive Git operations, or deleting unrelated data.
- Never print, commit, or transmit secrets from `.env`, credentials, or private keys. Existing passwordless sudo is not authorization to use it.

## Validation

Agents must run `bash scripts/check.sh` after changing Nix configuration and before reporting completion. Run it autonomously; do not ask the user to run checks.

```bash
bash scripts/check.sh          # Full CI-equivalent suite
bash scripts/check.sh format   # Formatting only
bash scripts/check.sh linux    # Linux evaluation only
bash scripts/check.sh darwin   # Both Darwin evaluations
```

- The full suite checks formatting with `nixfmt` from the locked Linux nixpkgs input, then evaluates `daehyun@charon`, `apollo`, and `thales`. Scoped commands are for iteration; run the full suite before completion.
- Requires Git and Nix with `nix-command` and `flakes` enabled. Nix may fetch the pinned formatter and inputs.
- Formatting includes tracked and non-ignored untracked `.nix` files, skipping empty placeholders. Git-backed flake evaluation excludes untracked files; stage newly imported files before evaluation, preserving unrelated staged changes.
- Checks stop at the first failure with a nonzero exit status. Fix failures within scope; report blockers and any checks not completed. Never claim validation passed when it did not.
- Evaluation does not build or activate configurations, install applications, or update lock files. CI calls the same script with platform-specific selectors.

## Applying Changes

```bash
# macOS (nix-darwin)
darwin-rebuild switch --flake darwin/

# Linux (home-manager)
home-manager switch --flake linux/
```

## Formatting

```bash
# Format all Nix files (nixfmt is in shared packages)
nixfmt **/*.nix
```
