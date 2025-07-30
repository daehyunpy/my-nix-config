{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager }:
    let
      configuration = { pkgs, config, lib, ... }: {
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
      };
    in {
      homeConfigurations."dhyou@octo60" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          modules = [
            configuration
            (import ../home.nix)
            (import ./home.nix)
            ({ pkgs, ... }: {
              home.username = "dhyou";
              home.homeDirectory = "/home/dhyou";
              programs.git.userEmail = "dhyou@60hz.io";
              programs.fish.interactiveShellInit = ''
                eval /opt/anaconda3/bin/conda shell.fish hook | source
              '';
            })
          ];
        };
      homeConfigurations."dhyou@octo61" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          modules = [
            configuration
            (import ../home.nix)
            (import ./home.nix)
            ({ pkgs, ... }: {
              home.username = "dhyou";
              home.homeDirectory = "/home/dhyou";
              programs.git.userEmail = "dhyou@60hz.io";
              programs.fish.interactiveShellInit = ''
                eval /opt/anaconda3/bin/conda shell.fish hook | source
              '';
            })
          ];
        };
    };
}
