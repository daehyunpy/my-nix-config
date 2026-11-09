{ pkgs, nixpkgs-unstable, ... }:
{
  nix.settings.experimental-features = "nix-command flakes";
  nix.package = pkgs.nix;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      unstable = import nixpkgs-unstable {
        system = prev.system;
        config.allowUnfree = true;
      };
    })
  ];
}
