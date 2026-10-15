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

## Zed

- Shared settings live in `home-files/zed`, linked to `~/.config/zed` by Home Manager.
- Install OMP separately and make `omp` available on Zed's `PATH`; the custom agent runs `omp acp`.
- Focus changes save files without automatic formatting or Ruff format actions. Manual formatting remains available, including Ruff import organization for Python.
- Edit predictions are disabled. Native and external agent requests still use their configured providers.
- Native agent model settings do not configure ACP agents, which manage their own model selection and authentication.
- Windows host settings at `%APPDATA%\Zed\settings.json` were merged manually, not automatically synchronized. SSH/WSL connections, MCP configuration, SQL formatter, and tool permissions remain host-only.
- The custom OMP entry remains in the shared Linux/macOS settings, not the Windows host configuration.

## NixOS
