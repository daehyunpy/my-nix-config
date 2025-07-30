# my-nix-config

## How to decrypt on a new machine

1. Generate a GPG key on the new machine and publish the key

   ```sh
   gpg --full-generate-key
   gpg --send-keys $KEY_ID
   ```

1. Get the public key on the decrypted machine and register it

   ```sh
   gpg --receive-keys $KEY_ID
   echo $KEY_ID:6: | gpg --import-ownertrust
   git-crypt add-gpg-user $KEY_ID
   ```

1. Decrypt the repository on the new machine

   ```sh
   git-crypt unlock
   ```


## macOS

1. Install `nix`

1. Leave the copy of this code at `~/.config/nix`

1. Decrpyt the repository using git-crypt and a GPG key

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

1. Decrpyt the repository using git-crypt and a GPG key

1. Enable experimental features

   ```sh
   echo "experimental-features = nix-command flakes" \
     | sudo tee -a /etc/nix/nix.conf
   ```

1. Install `home-manager`:

   ```sh
   nix run home-manager -- switch --flake ~/.config/nix/linux
   ```

1. As you need, you can rebuild the system to apply changes by:

   ```sh
   home-manager switch --flake ~/.config/nix/linux
   ```

1. To upgrade the system, you can run:

   ```sh
   nix flake update --flake ~/.config/nix/darwin
   ```


## NixOS
