# System Configuration

Declarative machine environments and network infrastructure for macOS, Linux, and WSL using Nix, Terraform, and OpenTofu. See `README.md` for project goals. WSL uses the Linux Home Manager configuration; Windows host settings are out of scope.

## Project Structure

- `nix/` — Machine and user environments; read [nix/CLAUDE.md](nix/CLAUDE.md) for configuration conventions, package policy, validation, activation, and formatting.
- `dotfiles/` — Managed user configuration payloads; installation and live-link behavior are owned by the [Nix guide](nix/CLAUDE.md#dotfile-installation).
- `infra/` — Independent Terraform-compatible root modules; read [infra/CLAUDE.md](infra/CLAUDE.md) for the shared workflow and module-local guides for provider details. Tailscale uses pinned OpenTofu; GitHub uses Terraform.
- `scripts/check.sh` — Shared local/CI Nix validation; follow the [Nix validation workflow](nix/CLAUDE.md#validation) when changing it or Nix configuration.
- Subsystem-local `tests/` directories hold behavioral tests and fixtures when needed; do not create empty test scaffolds.
- `docs/superpowers/specs/`, `docs/superpowers/plans/` — Design specifications and implementation plans.

## Local Secrets

- `.env` holds additional secrets (`MILVUS_ADDRESS`, `MILVUS_TOKEN`); see `.env.example` for the template. Both `.env` and `.envrc` are gitignored.

## Coding Guidance

Humans do not code directly; agents own implementation, verification, and review. Follow [Anthropic’s guidance](https://code.claude.com/docs/en/best-practices) on instructions versus deterministic enforcement and [OpenAI’s guidance](https://developers.openai.com/codex/learn/best-practices) on verification and review. Apply them through this repository’s workflow; repository policies take precedence, and shared checks must remain portable across agent tools.

## Agent Tool Compatibility

OMP is the primary agent tool today, but the tool may change. Keep agent instructions, plugins, and reusable resources portable and shared rather than tied to the current tool.

Use `CLAUDE.md` for compatibility across agent tools. Most agent tools read both `CLAUDE.md` and `AGENTS.md`, but Claude Code reads `CLAUDE.md` and does not automatically load `AGENTS.md`. Keeping the instructions in `CLAUDE.md` lets the same policy work across tools, including Claude Code, without a second file or tool-specific setup.

Keep reusable plugins and agent resources in `.claude/` so compatible tools can share them. This directory choice is for resource compatibility, not because Claude Code is the primary tool. Keep OMP-specific integration settings in `.omp/`; reuse shared resources where supported rather than maintaining separate copies for each tool.

## Preferences

- The main repository checkout must always remain on the `main` branch. Never switch it to another branch or detach its HEAD.
- Before making any repository changes—including code, configuration, documentation, and agent instructions—establish the working checkout. You may ask the user which existing worktree to use, whether to create a new one, or whether to work without a worktree. Honor an already specified choice without asking again.
- Unless the user explicitly chooses to work without a worktree, create or reuse a task-specific branch in a separate Git worktree. Do not edit or commit directly in the main checkout without that explicit authorization.
- Place worktrees under `.worktrees/` at the main repository root (for example, `.worktrees/todo-documenting/`), not inside another worktree. Perform edits, validation, and requested commits in the selected checkout; keep the main checkout on `main`.
- Keep repository-wide agent policy, including the YOLO boundary, in this root `CLAUDE.md`. Scoped `CLAUDE.md` workflow guides belong alongside their code and must not duplicate or override the root authorization boundary. Do not introduce `AGENTS.md`.
- Keep coding workflows and operational details in the appropriate scoped `CLAUDE.md`; keep `README.md` focused on human-facing goals, capabilities, and orientation.

## YOLO Boundary

- YOLO mode skips tool approval prompts; it is not a sandbox or blanket authorization. Stay within the user's requested scope.
- Proceed autonomously with repository inspection, requested edits, and relevant formatting, checks, Nix evaluation, and builds. Disposable temporary files and normal tool caches/Nix store writes are allowed.
- Require explicit user authorization before activating or rolling back configurations (`darwin-rebuild switch`, `home-manager switch`, equivalent commands), installing or uninstalling applications, running garbage collection, or changing services, permissions, or other host state. Instructions in this file explain commands; they do not authorize running them.
- Require explicit authorization for writes outside this checkout, except the temporary/cache/store writes above. Resolve symlink targets before writing. Files in `dotfiles/` may be live-linked into the home directory: requested edits are allowed, but their effects can be immediate without a rebuild.
- Preserve unrelated work, staged changes, and existing conflicts. Commit only when requested; require explicit authorization for pushing, publishing, destructive Git operations, or deleting unrelated data.
- Never print, commit, or transmit secrets from `.env`, credentials, or private keys. Existing passwordless sudo is not authorization to use it.

## Pull Requests and Merging

- Integrate task branches through a GitHub PR targeting `main`, using squash merge. A request to "merge" means merge the PR, not merge a task branch into local `main`. If no PR exists, follow the [authorization boundary](#yolo-boundary) before committing or publishing the branch and creating one.
- Before merging, inspect the current PR head, CI results, and review findings. Resolve failures and material findings; merge only the reviewed head.
- Keep task commits off local `main` until the PR is merged remotely. After verifying the remote merge, run the following from the clean main checkout, which must already be on `main`:

  ```sh
  git fetch origin main
  git merge --ff-only origin/main
  ```

- Do not use plain `git pull` for synchronization: the shared Git configuration enables rebasing. If fast-forwarding fails, preserve local-only commits and working changes, report the divergence, and obtain authorization before rewriting history.
- Merging does not authorize branch or worktree cleanup; follow the separate procedure below only when requested.

## Branch and Worktree Cleanup

- Clean up only when requested. Before post-merge cleanup, verify the PR is actually `MERGED` into its target branch and record its merge commit and published head. A pushed branch or clean status is not proof of merging.
- Inspect tracked, staged, untracked, and ignored files before removal. Git worktree removal can erase ignored data, including state, backups, credentials, and local configuration. Preserve non-regenerable files privately outside the worktree; discard only identified reproducible caches.
- Hand off authoritative state to a retained operator checkout before removing its current home. Verify the backup and destination, retain one active state, and follow the [Terraform state handoff](infra/CLAUDE.md#worktree-state-handoff) when applicable. Do not treat Git as a backup for ignored files.
- Run `git worktree remove <path>` from a retained checkout, keeping the main checkout on `main`. Do not use force to bypass dirty or unpreserved data.
- Delete the local branch with `git branch -d <branch>` after worktree removal. If squash merging prevents ancestry-based deletion, use `-D` only when deletion was explicitly requested, the published head matches the local tip, the PR is verified merged, and local-only data is preserved.
- Verify the directory, worktree registration, and local branch are gone and retained state remains usable. Do not delete other worktrees, branches, stashes, or remote branches; existing server-side branch auto-deletion is separate repository policy. Cleanup never authorizes infrastructure destruction, state removal from management, or host activation.

## OMP

Install OMP separately and launch from the selected checkout or worktree root:

```sh
omp --cwd .
```

- `.omp/config.yml` enables YOLO mode (no tool approval prompts) for this project; approval policies are not a sandbox.
- `.omp/lsp.json` uses `nil` and `nixfmt` without automatic formatting.
- `/nix-check [files...]` follows the [scoped Nix validation guidance](nix/CLAUDE.md#validation).

### Cua Driver MCP

`.omp/mcp.json` registers `cua-driver mcp` for OMP; Claude Code requires separate MCP registration. The driver must be on the agent's `PATH`. macOS installation is managed by Homebrew through `nix/darwin/casks.nix`; install the driver separately on Linux or Windows. On macOS, after activation:

```sh
open -n -g -a CuaDriver --args serve
cua-driver permissions grant
```

On macOS, grant Accessibility, Screen Recording, and direct capture consent, then restart the agent. Check the connection with `/mcp test cua-driver` in OMP or `claude mcp get cua-driver`. The default mode allows input to every app, not just this project.

### Unity Gateway

Home Manager links `dotfiles/omp/models.yml` into OMP. Install [Unity Gateway](https://github.com/databricks/unity-gateway) and the Databricks CLI separately; `databricks` and `jq` must be on `PATH`.

```sh
databricks auth login \
  --host https://adb-425124470313726.6.azuredatabricks.net \
  --profile adb-425124470313726
omp --model unity-openai/system.ai.gpt-6-1-sol
```

Use `/model` to select from `unity-anthropic`, `unity-openai`, `unity-google`, or `unity-oss`. Refresh the model registry from `ug status` when availability changes. Tokens are resolved at runtime, never stored in this repository.

## Zed

`dotfiles/zed` is linked to `~/.config/zed`. The external agent runs `omp acp`, so OMP must be on Zed's `PATH`; its model configuration is separate from Zed's native agent. Windows host settings are not managed here.

Zed terminals explicitly use `fish` and its virtual-environment activation script. Keep `terminal.shell.program` set to `fish`: selecting `activate_script` alone does not control Python toolchain activation in Windows-to-WSL sessions. Open a new terminal after changing these settings; no Home Manager rebuild is needed for the live link.
