# Nix System Configuration

Declarative system and user environment configuration using Nix flakes.

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
  - `conda`, `direnv`, `tmux`, `wezterm` — Shell/terminal configs (copied via `.source`)
  - `ssh` — SSH config (symlinked live via `mkOutOfStoreSymlink`)

## Conventions

- `brews.nix`, `casks.nix`, `packages.nix` are Nix lists. `mas.nix` is an attrset (`{ name = app-store-id; }`). Keep entries sorted alphabetically.
- Shared config goes in root `home.nix`/`packages.nix`. Platform-specific config goes in `darwin/` or `linux/`.
- Both flakes define a `pkgs.unstable` overlay (from `nixpkgs-unstable`) for accessing bleeding-edge packages. Use `pkgs.unstable.<pkg>` when the stable channel is too old.
- Machine-specific overrides are inline in each flake's module list (e.g., `thales` adds `openclaw-cli` brew, `plex-media-server` and `orbstack` casks).
- `home-files/` contents are symlinked via `mkOutOfStoreSymlink` (live link) or `.source` (copy). Prefer `mkOutOfStoreSymlink` for configs that change outside of nix (e.g., editor settings).
- `secret-envs.json` contains API keys and is encrypted via `git-crypt`. Never log or expose its contents.
- `.env` holds additional secrets (`MILVUS_ADDRESS`, `MILVUS_TOKEN`); see `.env.example` for the template. Both `.env` and `.envrc` are gitignored.

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
