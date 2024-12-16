{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }:
  let
    configuration = { pkgs, ... }: {
      nix.settings.experimental-features = "nix-command flakes";
      nix.package = pkgs.nix;

      home = {
        stateVersion = "24.11";
        username = "dhyou";
        homeDirectory = "/home/dhyou";
        packages =
          builtins.map
          (name: pkgs."${name}")
          (import ../packages.nix ++ import ./packages.nix);
        sessionPath = [ "$HOME/.local/bin" ];
        sessionVariables = {
          EDITOR = "${pkgs.neovim}/bin/nvim";
        };
        file = {
          ".config/direnv/direnv.toml".source = ../home-files/direnv.toml;
        };
      };

      programs.zsh.enable = true;
      programs.fish.enable = true;
      programs.git = {
        enable = true;
        userName = "Daehyun You";
        userEmail = "daehyun.park.you@proton.me";
      };
      programs.direnv.enable = true;
      programs.home-manager.enable = true;

      nixpkgs.config.allowUnfree = true;
    };
  in
  {
    homeConfigurations."dhyou@octo60" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      modules = [ configuration ];
    };
  };
}
