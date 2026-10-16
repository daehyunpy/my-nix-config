# my-nix-config

## macOS

1. Install `nix`

1. Leave the copy of this code at `~/.config/nix`

1. Enable experimental features

   ```sh
   echo "experimental-features = nix-command flakes" \
     | sudo tee -a /etc/nix/nix.conf
   ```

1. Install `nix-darwin`:

   ```sh
   nix run nix-darwin -- switch --flake ~/.config/nix/darwin
   ```

1. As you need, you can rebuild the system to apply changes by:

   ```sh
   darwin-rebuild switch --flake ~/.config/nix/darwin
   ```

1. To upgrade the system, you can run:

   ```sh
   nix flake update --flake ~/.config/nix/darwin
   ```

## Linux

1. Install `nix`

1. Leave the copy of this code at `~/.config/nix`

1. Enable experimental features

   ```sh
   echo "experimental-features = nix-command flakes" \
     | sudo tee -a /etc/nix/nix.conf
   ```

1. Install `home-manager` (replace `username@hostname` with a config defined in `linux/flake.nix`):

   ```sh
   nix run home-manager -- switch --flake ~/.config/nix/linux#username@hostname
   ```

1. Select the Nix-managed Fish as the login shell:

   ```sh
   fish_path="$HOME/.nix-profile/bin/fish"
   if ! grep -Fxq "$fish_path" /etc/shells; then
     printf '%s\n' "$fish_path" | sudo tee -a /etc/shells
   fi
   sudo chsh -s "$fish_path" "$USER"
   ```

   Start a new login session. Reconnect Zed to WSL so it reloads the shell.

1. As you need, you can rebuild the system to apply changes by:

   ```sh
   home-manager switch --flake ~/.config/nix/linux#username@hostname
   ```

1. To upgrade the system, you can run:

   ```sh
   nix flake update --flake ~/.config/nix/linux
   ```

## OMP

Start OMP from the repository root so it loads the project-local harness:

```sh
omp --cwd ~/.config/nix
```

- `.omp/config.yml` permits reads and workspace edits, but prompts for Bash and Eval execution, including under `--auto-approve`. Headless calls that require approval are rejected. Approval policies are not a sandbox.
- `.omp/lsp.json` selects `nil` for Nix intelligence, including root-level `home.nix`, and disables the duplicate `nixd` server. Diagnostics run after edits/writes; automatic formatting is off. Explicit LSP formatting uses `nixfmt`.
- `omp`, `nil`, `nixfmt`, and Nix must be on `PATH`. The shared Nix packages already include `nil` and `nixfmt`; install OMP separately.
- Existing `CLAUDE.md` instructions are discovered automatically; there is no second copy to maintain. Non-secret Unity Gateway providers are managed in `home-files/omp/models.yml`; preferences, sessions, and credentials remain in your user OMP profile.
- `/nix-check` is shared by Claude Code and OMP from `.claude/commands/nix-check.md`. It checks task-changed Nix files, or all non-empty Nix files when there are no task changes. Pass a scope, for example `/nix-check home.nix linux/home.nix`.
- `/nix-check` is an agent prompt for read-only formatting and syntax checks, not a shell script or automatic startup check. Semantic evaluation is opt-in; it must not activate configurations or update lock files.
- Launch from the root rather than `linux/` or `darwin/`: project settings, LSP overrides, and commands are cwd-scoped.

### Unity Gateway providers

`home-files/omp/models.yml` defines four providers: `unity-anthropic` (Claude), `unity-openai` (GPT), `unity-google` (Gemini), and `unity-oss` (DeepSeek, GLM, Kimi). Home Manager links it to `~/.omp/agent/models.yml` using the same live-link convention as Zed. It does not manage the rest of `~/.omp`.

Install OMP, [Unity Gateway](https://github.com/databricks/unity-gateway), and the Databricks CLI separately. `databricks` and `jq` must be on OMP's `PATH`; `jq` is included in the shared Nix packages. Authenticate the configured workspace/profile:

```sh
databricks auth login \
  --host https://adb-425124470313726.6.azuredatabricks.net \
  --profile adb-425124470313726
```

Deploy on this Linux machine:

```sh
home-manager switch --flake ~/.config/nix/linux#daehyun@charon
```

Select a model explicitly, or use `/model` inside OMP:

```sh
omp --model unity-anthropic/system.ai.claude-opus-5-5
omp --model unity-openai/system.ai.gpt-6-1-sol
omp --model unity-google/system.ai.gemini-4-argon
omp --model unity-oss/system.ai.kimi-k3
```

The existing default model is unchanged. The 41-model registry is an explicit snapshot; update it from `ug status` when gateway availability changes. Existing `~/.ucode` paths and `ucode/...` client metadata are compatibility names retained by Unity Gateway.

Tokens are resolved with `databricks auth token` against the same profile used by Unity Gateway, then extracted with `jq`; no token is stored in this repository or Nix configuration. Calling the Databricks CLI directly avoids `ug auth-token` startup exceeding OMP's 10-second command timeout. OMP caches successful command credentials for the process lifetime; explicit credential refresh and 401 recovery invalidate that cache. Unity Gateway's Pi refresh loop and Claude's helper TTL are not configured here.

Deployment verification: real OMP completions returned `UNITY_OK` through Claude Haiku 5.5, GPT-5.4 Mini, Gemini 3.5 Flash Lite, and DeepSeek V4.1 Flash. This covers all four API routes, not every advertised model, tool calling, image generation, long context, token-expiry recovery, or Zed's GUI. OMP's displayed fallback limits and capabilities for these custom IDs are not verified gateway capacity.

### Project plugins

[Superpowers](https://github.com/obra/superpowers) is installed at project scope (7.0.0 at setup). It supplies planning, systematic debugging, code review, and verification skills; no browser/MCP service or additional credentials are required.

From the repository root, restore the installation on another machine:

```sh
omp plugin marketplace add obra/superpowers-marketplace
omp plugin install --scope project superpowers@superpowers-marketplace
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin install pr-review-toolkit@claude-plugins-official --scope project
claude plugin install context7@claude-plugins-official --scope project

# OMP 18.10.4 omits the runtime link for this Pi-only package manifest.
plugin_dir="$(omp plugin list --json | jq -er '.marketplace[] | select(.id == "superpowers@superpowers-marketplace") | .entries[] | select(.scope == "project") | .installPath')"
mkdir -p .omp/plugins/node_modules
ln -sfn "$plugin_dir" .omp/plugins/node_modules/superpowers
```

`.claude/settings.json` is the shared declaration for PR Review Toolkit and Context7. Install them with the Claude CLI once per machine; OMP reuses their compatible components without a second OMP installation. The declarations do not download plugins or pin exact source revisions.

Superpowers remains an OMP installation because `.omp/config.yml` explicitly loads its Pi bootstrap through the runtime link above. `.omp/plugins/` is ignored because it holds machine-local registries, timestamps, and cache links. Keep Claude's registry/cache machine-local too. Restart both tools after installation; OMP-specific permissions, LSP settings, and the Superpowers bootstrap remain in `.omp/`.

Useful entry points:

- `/skill:brainstorming` — clarify a substantial change before implementation.
- `/skill:writing-plans` — turn an agreed design into implementation steps.
- `/skill:systematic-debugging` — investigate a failure before changing code.
- `/skill:requesting-code-review` — review implementation against requirements.
- `/skill:verification-before-completion` — require evidence before declaring success.
- `/pr-review-toolkit:review-pr code comments` — targeted code and documentation review.
- `/pr-review-toolkit:review-pr tests errors` — test coverage and error-handling review when applicable.

Skills provide workflow instructions, not new Nix tooling or permission bypasses. Repository instructions still apply: keep small config edits proportionate, use `/nix-check` for Nix checks, and do not activate configurations as part of validation. Bash/Eval approval also applies to headless subagents, so run approval-requiring checks in the interactive parent.

To upgrade, run `omp plugin upgrade --scope project superpowers@superpowers-marketplace`, refresh the runtime link with the commands above, and restart OMP. This fetches the marketplace version; it is not a Nix-pinned dependency.

#### PR Review Toolkit

The [official marketplace plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/pr-review-toolkit) adds six agents: `code-reviewer`, `comment-analyzer`, `pr-test-analyzer`, `silent-failure-hunter`, `type-design-analyzer`, and `code-simplifier`. Use only review aspects relevant to the change; type and application-test reviews usually add little to a package-list edit. The `simplify` aspect can modify files, so use `code comments` for a review without requesting simplification.

Verified in both Claude Code initialization and OMP discovery: `/pr-review-toolkit:review-pr` and all six review agents are available. The duplicate OMP project installation has been removed. To upgrade, run `claude plugin marketplace update claude-plugins-official` followed by `claude plugin update pr-review-toolkit@claude-plugins-official --scope project`, then restart the tools. Existing Claude cache entries can affect which version OMP selects; project enablement is not an exact version pin.

#### Context7 documentation tools

Context7 is declared in `.claude/settings.json` and installed through Claude Code at project scope using the shared installation commands above. OMP imports the plugin's MCP server definition; there is no separate `.omp/mcp.json` to maintain. Claude Code must be installed separately; keep its machine-local registry and cache outside this repository.

- Restart OMP after installation so it discovers the plugin-provided server as `context7:context7`.
- In OMP 18.10.4 RPC/ACP mode, `/mcp list` and `/mcp test` inspect native MCP files only; their output does not establish whether a plugin-provided server is available.
- Ask OMP to use Context7 to resolve a library, then query its docs. For example: “Use Context7 to look up standalone Home Manager flake configuration.”

Verified through OMP's actual MCP runtime: the Claude plugin connected and both `resolve-library-id` and `query-docs` successfully looked up `/nix-community/home-manager` and retrieved documentation. Documentation may target a different branch or version: match the repository's locked inputs rather than blindly copying examples.

OMP can reuse an older Claude cache entry when the same plugin has multiple installations. On this machine it currently selects the older `unknown` cache entry, which starts `npx -y @upstash/context7-mcp`; Node.js and `npx` are therefore required here. The newly installed plugin uses hosted HTTP, but OMP's selected cache entry is not an exact version pin.

Queries leave the machine. Do not send `.env` contents, credentials, private SSH material, or proprietary source. No credentials were added to this repository. Shared anonymous rate limits can apply; project settings and per-machine installation are both required.

## Zed

- Shared settings live in `home-files/zed`, linked to `~/.config/zed` by Home Manager.
- Install OMP separately and make `omp` available on Zed's `PATH`; the custom agent runs `omp acp`.
- Focus changes save files without automatic formatting or Ruff format actions. Manual formatting remains available, including Ruff import organization for Python.
- Edit predictions are disabled. Native and external agent requests still use their configured providers.
- Native agent model settings do not configure ACP agents, which manage their own model selection and authentication.
- Windows host settings at `%APPDATA%\Zed\settings.json` were merged manually, not automatically synchronized. SSH/WSL connections, MCP configuration, SQL formatter, and tool permissions remain host-only.
- The custom OMP entry remains in the shared Linux/macOS settings, not the Windows host configuration.

## NixOS
