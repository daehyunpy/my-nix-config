{
  description = "Daehyun's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      environment.systemPackages = import ../packages.nix pkgs;

      nix.settings.experimental-features = "nix-command flakes";

      programs.fish.enable = true;

      system.configurationRevision = self.rev or self.dirtyRev or null;

      system.stateVersion = 5;

      environment.shells = [ pkgs.fish ];

      nixpkgs.config.allowUnfree = true;
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    darwinConfigurations.morpheus = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };

    darwinConfigurations.thales = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
