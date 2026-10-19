# my-nix-config

Cross-platform Nix configuration. Keep the checkout at `~/.config/nix`.

- `home.nix`, `packages.nix`: shared Home Manager configuration and packages.
- `darwin/`, `linux/`: platform and machine configuration.
- `home-files/`: managed dotfiles.

## Setup

Install [Nix](https://nixos.org/download/), then enable flakes:

```sh
mkdir -p ~/.config/nix
printf '%s\n' 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

### macOS

```sh
# Bootstrap nix-darwin
nix run nix-darwin -- switch --flake ~/.config/nix/darwin

# Apply changes
darwin-rebuild switch --flake ~/.config/nix/darwin
```

Homebrew formulae, casks, and App Store apps are declared in `darwin/`. Unrestricted passwordless sudo for the admin group is intentional.

### Linux

Replace `username@hostname` with a configuration from `linux/flake.nix`:

```sh
# Bootstrap Home Manager
nix run home-manager -- switch --flake ~/.config/nix/linux#username@hostname

# Apply changes
home-manager switch --flake ~/.config/nix/linux#username@hostname
```

To use the Nix-managed Fish as your login shell:

```sh
fish_path="$HOME/.nix-profile/bin/fish"
if ! grep -Fxq "$fish_path" /etc/shells; then
  printf '%s\n' "$fish_path" | sudo tee -a /etc/shells
fi
sudo chsh -s "$fish_path" "$USER"
```

Start a new login session after activation; reconnect remote editors to reload the shell.

## Maintenance

- Update inputs: `nix flake update --flake darwin` or `nix flake update --flake linux`, then apply.
- Format Nix files: `nixfmt **/*.nix`.
- Garbage collection runs weekly and removes unreferenced generations older than 30 days, making them unavailable for rollback.
- Approve trusted direnv configurations with `direnv allow`. `.env` is gitignored; see `.env.example`.

CI checks formatting and evaluates the Poseidon Home Manager configuration, both Darwin systems, and the generic NixOS Tailscale module. It does not activate a host or apply infrastructure. Evaluate locally:

```sh
nix eval --no-update-lock-file --raw ./darwin#darwinConfigurations.apollo.system.drvPath
nix eval --no-update-lock-file --raw ./darwin#darwinConfigurations.thales.system.drvPath
nix eval --no-update-lock-file --raw './linux#homeConfigurations."daehyun@poseidon".activationPackage.drvPath'
```

## Tailscale

Shared `packages.nix` installs the Tailscale CLI. `modules/tailscale.nix` enables the native daemon for both Darwin machines and is exported as `linux#nixosModules.tailscale` for the existing NixOS configuration. Home Manager does not start that daemon. Tailnet policy and DNS live in `infra/tailscale/`; CI does not apply them. See that directory for credentials, the Apollo client-preservation gate, and the separate Muse SSH apply.


## OMP

Install OMP separately and launch from the repository root:

```sh
omp --cwd ~/.config/nix
```

- `.omp/config.yml` prompts for Bash and Eval execution, including under `--auto-approve`; approval policies are not a sandbox.
- `.omp/lsp.json` uses `nil` and `nixfmt` without automatic formatting.
- `/nix-check [files...]` runs read-only formatting and syntax checks; semantic evaluation is opt-in.

### Cua Driver MCP

`.mcp.json` registers `cua-driver mcp` for OMP and Claude Code; the driver must be on the agent's `PATH`. macOS installation is managed by Homebrew through `darwin/casks.nix`; install the driver separately on Linux or Windows. On macOS, after activation:

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
