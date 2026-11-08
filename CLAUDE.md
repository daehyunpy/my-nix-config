# Nix System Configuration

Declarative system and user environment configuration for macOS, Linux, and WSL using Nix flakes. See `README.md` for project goals. WSL uses the Linux Home Manager configuration; Windows host settings are out of scope.

## Project Structure

- `darwin/` — macOS configuration using nix-darwin
  - `flake.nix` — Two machines: `apollo` (primary), `thales` (media server)
  - `brews.nix`, `casks.nix`, `mas.nix` — Homebrew formulae, casks, Mac App Store apps
  - `packages.nix` — macOS-only nix packages (currently empty)
  - `home.nix` — macOS-specific home-manager overrides
- `linux/` — Linux configuration using home-manager standalone
  - `flake.nix` — One configuration: `daehyun@charon` (`x86_64-linux`)
  - `packages.nix` — Linux-only nix packages (currently empty)
  - `home.nix` — Linux-specific home-manager overrides
- `nixos/` — NixOS configuration (empty, reserved for future use)
- `kubernetes/` — Kubernetes manifests (empty, reserved for future use)
- `openspec/` — Spec documents and change tracking (scaffolded: `specs/`, `changes/`)
- `terraform/` — Independent OpenTofu root modules; read [terraform/CLAUDE.md](terraform/CLAUDE.md) before working on them.
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

## Coding Guidance

Humans do not code directly; agents own implementation, verification, and review. Follow [Anthropic’s guidance](https://code.claude.com/docs/en/best-practices) on instructions versus deterministic enforcement and [OpenAI’s guidance](https://developers.openai.com/codex/learn/best-practices) on verification and review. Apply them through this repository’s workflow; repository policies take precedence, and shared checks must remain portable across agent tools.

## Agent Tool Compatibility

OMP is the primary agent tool today, but the tool may change. Keep agent instructions, plugins, and reusable resources portable and shared rather than tied to the current tool.

Use `CLAUDE.md` for compatibility across agent tools. Most agent tools read both `CLAUDE.md` and `AGENTS.md`, but Claude Code reads `CLAUDE.md` and does not automatically load `AGENTS.md`. Keeping the instructions in `CLAUDE.md` lets the same policy work across tools, including Claude Code, without a second file or tool-specific setup.

Keep reusable plugins and agent resources in `.claude/` so compatible tools can share them. This directory choice is for resource compatibility, not because Claude Code is the primary tool. Keep OMP-specific integration settings in `.omp/`; reuse shared resources where supported rather than maintaining separate copies for each tool.

## Preferences

- Preserve unrestricted passwordless sudo (`%admin ALL=(ALL) NOPASSWD: ALL`) on macOS. This is intentional; do not replace it with password or Touch ID authentication unless explicitly requested.
- The main repository checkout must always remain on the `main` branch. Never switch it to another branch or detach its HEAD.
- Before making any repository changes—including code, configuration, documentation, and agent instructions—establish the working checkout. You may ask the user which existing worktree to use, whether to create a new one, or whether to work without a worktree. Honor an already specified choice without asking again.
- Unless the user explicitly chooses to work without a worktree, create or reuse a task-specific branch in a separate Git worktree. Do not edit or commit directly in the main checkout without that explicit authorization.
- Place worktrees under `.worktrees/` at the main repository root (for example, `.worktrees/todo-documenting/`), not inside another worktree. Perform edits, validation, and requested commits in the selected checkout; keep the main checkout on `main`.
- Prefer Homebrew for macOS applications and platform-specific packages. Install core CLI tools and services shared across macOS, Linux, and WSL using Nix instead.
- Keep shared Nix package declarations in root `packages.nix`/`home.nix`; keep platform-specific service lifecycle configuration in the appropriate platform modules.
- Keep repository-wide agent policy, including the YOLO boundary, in this root `CLAUDE.md`. Scoped `CLAUDE.md` workflow guides belong alongside their code and must not duplicate or override the root authorization boundary. Do not introduce `AGENTS.md`.
- Keep coding workflows and operational details in the appropriate scoped `CLAUDE.md`; keep `README.md` focused on human-facing goals, capabilities, and orientation.

## YOLO Boundary

- YOLO mode skips tool approval prompts; it is not a sandbox or blanket authorization. Stay within the user's requested scope.
- Proceed autonomously with repository inspection, requested edits, and relevant formatting, checks, Nix evaluation, and builds. Disposable temporary files and normal tool caches/Nix store writes are allowed.
- Require explicit user authorization before activating or rolling back configurations (`darwin-rebuild switch`, `home-manager switch`, equivalent commands), installing or uninstalling applications, running garbage collection, or changing services, permissions, or other host state. Instructions in this file explain commands; they do not authorize running them.
- Require explicit authorization for writes outside this checkout, except the temporary/cache/store writes above. Resolve symlink targets before writing. Files in `home-files/` may be live-linked into the home directory: requested edits are allowed, but their effects can be immediate without a rebuild.
- Preserve unrelated work, staged changes, and existing conflicts. Commit only when requested; require explicit authorization for pushing, publishing, destructive Git operations, or deleting unrelated data.
- Never print, commit, or transmit secrets from `.env`, credentials, or private keys. Existing passwordless sudo is not authorization to use it.

## Branch and Worktree Cleanup

- Clean up only when requested. Before post-merge cleanup, verify the PR is actually `MERGED` into its target branch and record its merge commit and published head. A pushed branch or clean status is not proof of merging.
- Inspect tracked, staged, untracked, and ignored files before removal. Git worktree removal can erase ignored data, including state, backups, credentials, and local configuration. Preserve non-regenerable files privately outside the worktree; discard only identified reproducible caches.
- Hand off authoritative state to a retained operator checkout before removing its current home. Verify the backup and destination, retain one active state, and follow the [Terraform state handoff](terraform/CLAUDE.md#worktree-state-handoff) when applicable. Do not treat Git as a backup for ignored files.
- Run `git worktree remove <path>` from a retained checkout, keeping the main checkout on `main`. Do not use force to bypass dirty or unpreserved data.
- Delete the local branch with `git branch -d <branch>` after worktree removal. If squash merging prevents ancestry-based deletion, use `-D` only when deletion was explicitly requested, the published head matches the local tip, the PR is verified merged, and local-only data is preserved.
- Verify the directory, worktree registration, and local branch are gone and retained state remains usable. Do not delete other worktrees, branches, stashes, or remote branches; existing server-side branch auto-deletion is separate repository policy. Cleanup never authorizes infrastructure destruction, state removal from management, or host activation.

## Validation

Agents must run `bash scripts/check.sh` after changing Nix configuration and before reporting completion. Run it autonomously; do not ask the user to run checks.

```bash
bash scripts/check.sh          # Full CI-equivalent suite
bash scripts/check.sh format   # Formatting only
bash scripts/check.sh linux    # Linux evaluation only
bash scripts/check.sh darwin   # Both Darwin evaluations
```

- The full suite checks validation error handling and formatting with `nixfmt` from the locked Linux nixpkgs input, then evaluates `daehyun@charon`, `apollo`, and `thales`. Scoped commands are for iteration; run the full suite before completion.
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

## OMP

Install OMP separately and launch from the selected checkout or worktree root:

```sh
omp --cwd .
```

- `.omp/config.yml` enables YOLO mode (no tool approval prompts) for this project; approval policies are not a sandbox.
- `.omp/lsp.json` uses `nil` and `nixfmt` without automatic formatting.
- `/nix-check [files...]` provides focused, read-only formatting and syntax checks; it does not replace the full validation required above.

### Cua Driver MCP

`.omp/mcp.json` registers `cua-driver mcp` for OMP; Claude Code requires separate MCP registration. The driver must be on the agent's `PATH`. macOS installation is managed by Homebrew through `darwin/casks.nix`; install the driver separately on Linux or Windows. On macOS, after activation:

```sh
open -n -g -a CuaDriver --args serve
cua-driver permissions grant
```

On macOS, grant Accessibility, Screen Recording, and direct capture consent, then restart the agent. Check the connection with `/mcp test cua-driver` in OMP or `claude mcp get cua-driver`. The default mode allows input to every app, not just this project.

### Unity Gateway

Home Manager links `home-files/omp/models.yml` into OMP. Install [Unity Gateway](https://github.com/databricks/unity-gateway) and the Databricks CLI separately; `databricks` and `jq` must be on `PATH`.

```sh
databricks auth login \
  --host https://adb-425124470313726.6.azuredatabricks.net \
  --profile adb-425124470313726
omp --model unity-openai/system.ai.gpt-6-1-sol
```

Use `/model` to select from `unity-anthropic`, `unity-openai`, `unity-google`, or `unity-oss`. Refresh the model registry from `ug status` when availability changes. Tokens are resolved at runtime, never stored in this repository.

## Zed

`home-files/zed` is linked to `~/.config/zed`. The external agent runs `omp acp`, so OMP must be on Zed's `PATH`; its model configuration is separate from Zed's native agent. Windows host settings are not managed here.

Zed terminals explicitly use `fish` and its virtual-environment activation script. Keep `terminal.shell.program` set to `fish`: selecting `activate_script` alone does not control Python toolchain activation in Windows-to-WSL sessions. Open a new terminal after changing these settings; no Home Manager rebuild is needed for the live link.
