# system-config

Maintain a single source of truth for my macOS, Linux, and WSL environments and network infrastructure: packages, applications, dotfiles, machine-specific settings, and Tailscale tailnet configuration. Make environments reproducible and straightforward to rebuild, share configuration where practical, and keep platform-specific exceptions explicit. Prefer declarative changes over undocumented manual setup; keep secrets outside the repository. Deployment automation remains planned work in [BACKLOG.md](BACKLOG.md).

WSL uses the Linux Home Manager configuration; Windows host settings are not managed here. Keep the checkout at `~/.config/nix`, independently of the repository name. The GitHub repository rename from `my-nix-config` to `system-config` is pending a separately authorized operation.

Prefer Homebrew for macOS applications and platform-specific packages. Use Nix for core CLI tools and services shared across macOS, Linux, and WSL; share package declarations while keeping platform-specific service management explicit.

- `nix/home/`: shared Home Manager configuration and packages.
- `nix/darwin/`, `nix/linux/`: independent platform flakes, shared platform configuration, and machine-specific `hosts/` modules.
- `dotfiles/`: managed configuration payloads; Nix declares their installation.
- `infra/`: independent provider-based infrastructure configurations.
- `infra/tailscale/`: existing Terraform-compatible tailnet configuration, executed with OpenTofu.
- `infra/github/`: GitHub repository rules managed separately from Nix, using Terraform.
- `scripts/check.sh`: shared local and CI Nix validation; subsystem tests live with their owning configuration.

## Setup

Install [Nix](https://nixos.org/download/), then enable flakes:

```sh
mkdir -p ~/.config/nix
printf '%s\n' 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

### macOS

```sh
# Bootstrap nix-darwin
nix run nix-darwin -- switch --flake ~/.config/nix/nix/darwin

# Apply changes
darwin-rebuild switch --flake ~/.config/nix/nix/darwin
```

Homebrew formulae, casks, and App Store apps are declared in `nix/darwin/`. Unrestricted passwordless sudo for the admin group is intentional.

The Dock pins `/System/Applications/Siri AI.app` for browsing Siri conversations, not the CoreServices Siri assistant.

### Linux

Poseidon (Fedora/WSL) uses the `daehyun@poseidon` configuration from `nix/linux/flake.nix`. Its Nix-managed Mosh uses Fedora's `/usr/bin/ssh` for compatibility with Fedora's system crypto policy:

```sh
# Bootstrap Home Manager
nix run home-manager -- switch --flake ~/.config/nix/nix/linux#daehyun@poseidon

# Apply changes
home-manager switch --flake ~/.config/nix/nix/linux#daehyun@poseidon
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

## Tailscale tailnet management

`infra/tailscale/` declaratively manages the existing tailnet's policy, DNS, device key-expiry settings, and route approvals. CI validates configuration without applying it.

Host-side Tailscale installation and Nix-managed services remain deferred. Live DNS is Cloudflare-only, matching the declared configuration and verified deployment.

Tailscale commands, credentials, adoption, and provider-specific verification live in the [module guide](infra/tailscale/CLAUDE.md). Common planning, approval, state, and recovery rules live in the [shared Terraform workflow](infra/CLAUDE.md). The source relocation does not move ignored operator state: complete the documented state handoff before authenticated use of a relocated root.

## Maintenance

- Validate without activation: `bash scripts/check.sh` checks formatting and discovers every declared Home Manager and Darwin configuration; empty configuration sets or failed evaluations fail validation.
- Update inputs: `nix flake update --flake nix/darwin` or `nix flake update --flake nix/linux`, then apply.
- Garbage collection runs weekly and removes unreferenced generations older than 30 days, making them unavailable for rollback.
- Approve trusted direnv configurations with `direnv allow`. `.env` is gitignored; see `.env.example`.
- Before updating an existing live checkout to this layout, review the [dotfile cutover and recovery requirements](docs/superpowers/specs/2026-11-08-repository-structure-design.md#live-link-cutover-and-recovery). Moving `home-files/` to `dotfiles/` requires coordinated, authorized activation to repair existing live-link targets.

## Agent Workflows

Repository-wide coding policy and agent/editor setup instructions live in [CLAUDE.md](CLAUDE.md). Nix conventions and workflows live in [nix/CLAUDE.md](nix/CLAUDE.md); infrastructure workflows live in [infra/CLAUDE.md](infra/CLAUDE.md) and its module guides. Agents perform repository changes and checks; system activation and other protected host changes require explicit user authorization.

The repository's OMP configuration includes shared model-role defaults for coding, planning, and background work; provider credentials stay in the user's OMP profile.
