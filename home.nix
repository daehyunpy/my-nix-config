{ pkgs, config, lib, ... }:
let
  homePathString = config.home.homeDirectory;
  makeOutOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home = {
    stateVersion = "24.11";
    username = lib.mkDefault "daehyun";
    homeDirectory = lib.mkDefault "/Users/daehyun";
    packages = import ./packages.nix pkgs;
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.local/share/npm/bin"
      "$HOME/.local/share/pnpm"
    ];
    sessionVariables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
      DOCKER_HOST = "unix:///var/run/docker.sock";
      NPM_CONFIG_PREFIX = "${homePathString}/.local/share/npm";
      PNPM_HOME = "${homePathString}/.local/share/pnpm";
      OCO_DESCRIPTION = "true";
      OCO_ONE_LINE_COMMIT = "true";
      OCO_GITPUSH = "false";
    } // builtins.fromJSON (builtins.readFile ./secret-envs.json);
    file = {
      ".config/conda".source = ./home-files/conda;
      ".config/direnv".source = ./home-files/direnv;
      ".config/lazygit".source = ./home-files/lazygit;
      ".config/nvim".source = makeOutOfStore "${homePathString}/.config/nix/home-files/nvim";
      ".config/tmux".source = ./home-files/tmux;
      ".config/wezterm".source = ./home-files/wezterm;
      ".config/zed".source = makeOutOfStore "${homePathString}/.config/nix/home-files/zed";
      ".cspell.yaml".source = ./home-files/cspell/cspell.yaml;
      ".ssh/config".source = makeOutOfStore "${homePathString}/.config/nix/home-files/ssh/config";
    };
  };

  programs.zsh.enable = true;
  programs.fish.enable = true;
  programs.git = {
    enable = true;
    userName = "Daehyun You";
    userEmail = lib.mkDefault "daehyun.park.you@proton.me";
    lfs.enable = true;
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
  programs.direnv.enable = true;
  programs.home-manager.enable = true;
}
