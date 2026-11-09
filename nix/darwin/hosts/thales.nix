{ pkgs, ... }:
{
  system.primaryUser = "daehyun";
  nix-homebrew.user = "daehyun";

  users.users.daehyun = {
    home = "/Users/daehyun";
    shell = pkgs.fish;
  };

  homebrew.casks = [
    "plex-media-server"
    "orbstack"
  ];
}
