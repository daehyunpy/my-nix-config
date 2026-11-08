# my-nix-config

Maintain a single source of truth for my macOS, Linux, and WSL environments: packages, applications, dotfiles, and machine-specific settings. Make environments reproducible and straightforward to rebuild, share configuration where practical, and keep platform-specific exceptions explicit. Prefer declarative changes over undocumented manual setup; keep secrets outside the repository.

WSL uses the Linux Home Manager configuration; Windows host settings are not managed here. Keep the checkout at `~/.config/nix`.

Prefer Homebrew for macOS applications and platform-specific packages. Use Nix for core CLI tools and services shared across macOS, Linux, and WSL; share package declarations while keeping platform-specific service management explicit.

- `home.nix`, `packages.nix`: shared Home Manager configuration and packages.
- `darwin/`, `linux/`: platform and machine configuration.
- `home-files/`: managed dotfiles.
- `terraform/`: Terraform-compatible infrastructure configuration, executed with OpenTofu.
- `terraform/github/`: GitHub repository rules managed separately from Nix.

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

The Dock pins `/System/Applications/Siri AI.app` for browsing Siri conversations, not the CoreServices Siri assistant.

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

## Tailscale tailnet management

`terraform/tailscale/` declaratively manages the existing tailnet's policy, DNS, device key-expiry settings, and route approvals. CI validates configuration without applying it.

Host-side Tailscale installation and Nix-managed services remain deferred. Live DNS is Cloudflare-only, matching the declared configuration and verified deployment.

Agent workflow, credentials, state, adoption, recovery, and verification guidance live in [terraform/CLAUDE.md](terraform/CLAUDE.md).

## Maintenance

- Update inputs: `nix flake update --flake darwin` or `nix flake update --flake linux`, then apply.
- Garbage collection runs weekly and removes unreferenced generations older than 30 days, making them unavailable for rollback.
- Approve trusted direnv configurations with `direnv allow`. `.env` is gitignored; see `.env.example`.

## Agent Workflows

Coding, validation, and agent/editor setup instructions live in [CLAUDE.md](CLAUDE.md). Agents perform repository changes and checks; system activation and other protected host changes require explicit user authorization.
