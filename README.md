# my-nix-config

## macOS

1. Install `nix`

1. Leave the copy of this code at ~/.config/nix

1. Install `nix-darwin`:
   ```sh
   nix --extra-experimental-features "nix-command flakes" \
     run nix-darwin \
     -- switch --flake ~/.config/nix/darwin
   ```

1. As you need, you can rebuild the system to apply changes by:
   ```sh
   darwin-rebuild switch --flake ~/.config/nix/darwin
   ```

## Linux

1. Install `nix`

1. Leave the copy of this code at ~/.config/nix

1. Install `home-manager`:
   ```sh
   nix --extra-experimental-features "nix-command flakes" \
     run home-manager \
     -- switch --flake ~/.config/nix/linux
   ```

1. As you need, you can rebuild the system to apply changes by:
   ```sh
   home-manager switch --flake ~/.config/nix/linux
   ```

## NixOS
