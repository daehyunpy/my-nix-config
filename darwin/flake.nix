{
  description = "Daehyun's nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = { self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, ... }: {
      nix.settings.experimental-features = "nix-command flakes";

      environment.systemPackages =
        builtins.map
        (name: pkgs.${name})
        ((import ../packages.nix) ++ (import ./packages.nix));
      environment.shells = [ pkgs.fish ];

      homebrew = {
        enable = true;
        brews = ["mas"];
        casks = import ./casks.nix;
        masApps = import ./mas-apps.nix;
      };

      programs.fish.enable = true;

      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 5;

      nixpkgs.config.allowUnfree = true;
      nixpkgs.hostPlatform = "aarch64-darwin";

      users.users.daehyun.shell = "${pkgs.fish}/bin/fish";
    };
  in
  {
    darwinConfigurations.morpheus = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "daehyun";
          };
        }
      ];
    };

    darwinConfigurations.thales = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "daehyun";
          };
        }
      ];
    };
  };
}
