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

1. Install `fish` and add it to `/etc/shells`

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

1. As you need, you can rebuild the system to apply changes by:

   ```sh
   home-manager switch --flake ~/.config/nix/linux#username@hostname
   ```

1. To upgrade the system, you can run:

   ```sh
   nix flake update --flake ~/.config/nix/linux
   ```


## NixOS
