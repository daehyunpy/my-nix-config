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

## Zed

- Shared settings live in `home-files/zed`, linked to `~/.config/zed` by Home Manager.
- Install OMP separately and make `omp` available on Zed's `PATH`; the custom agent runs `omp acp`.
- Focus changes save files without automatic formatting or Ruff format actions. Manual formatting remains available, including Ruff import organization for Python.
- Edit predictions are disabled. Native and external agent requests still use their configured providers.
- Native agent model settings do not configure ACP agents, which manage their own model selection and authentication.
- Windows host settings at `%APPDATA%\Zed\settings.json` were merged manually, not automatically synchronized. SSH/WSL connections, MCP configuration, SQL formatter, and tool permissions remain host-only.
- The custom OMP entry remains in the shared Linux/macOS settings, not the Windows host configuration.

## NixOS
