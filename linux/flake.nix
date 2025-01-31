{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }:
  let
    configuration = { pkgs, config, lib, ... }:
    let
      homePathString = config.home.homeDirectory;
      makeOutOfStore = config.lib.file.mkOutOfStoreSymlink;
    in
    {
      nix.settings.experimental-features = "nix-command flakes";
      nix.package = pkgs.nix;

      home = {
        stateVersion = "24.11";
        username = lib.mkDefault "daehyun";
        homeDirectory = lib.mkDefault "/home/daehyun";
        packages =
          import ../packages.nix pkgs
          ++ import ./packages.nix pkgs;
        sessionPath = [ "$HOME/.local/bin" ];
        sessionVariables = {
          LANG = "en_US.UTF-8";
          LC_ALL = "en_US.UTF-8";
          EDITOR = "${pkgs.neovim}/bin/nvim";
        };
        file = {
          ".config/conda".source = ../home-files/conda;
          ".config/direnv".source = ../home-files/direnv;
          ".config/lazygit".source = ../home-files/lazygit;
          ".config/nvim".source = makeOutOfStore "${homePathString}/.config/nix/home-files/nvim";
          ".config/tmux".source = ../home-files/tmux;
          ".ssh/config".source = ../home-files/ssh/config;
        };
      };

      programs.zsh.enable = true;
      programs.fish.enable = true;
      programs.git = {
        enable = true;
        userName = "Daehyun You";
        userEmail = lib.mkDefault "daehyun.park.you@proton.me";
      };
      programs.direnv.enable = true;
      programs.home-manager.enable = true;

      nixpkgs.config.allowUnfree = true;
    };
  in
  {
    homeConfigurations."dhyou@octo60" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      modules = [
        configuration
        (
          { pkgs, ... }: {
            home.username = "dhyou";
            home.homeDirectory = "/home/dhyou";
            programs.git.userEmail = "dhyou@60hz.io";
            programs.fish.interactiveShellInit = ''
              eval /opt/anaconda3/bin/conda shell.fish hook | source
            '';
          }
        )
      ];
    };
  };
}
