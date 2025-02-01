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
    packages =
      import ../packages.nix pkgs
      ++ import ./packages.nix pkgs;
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
    };
    file = {
      ".config/conda".source = ../home-files/conda;
      ".config/direnv".source = ../home-files/direnv;
      ".config/lazygit".source = ../home-files/lazygit;
      ".config/nvim".source = makeOutOfStore "${homePathString}/.config/nix/home-files/nvim";
      ".config/tmux".source = ../home-files/tmux;
      ".config/wezterm".source = ../home-files/wezterm;
      ".config/zed".source = makeOutOfStore "${homePathString}/.config/nix/home-files/zed";
      ".cspell.yaml".source = ../home-files/cspell/cspell.yaml;
      ".ssh/config".source = ../home-files/ssh/config;
    };
  };

  programs.zsh.enable = true;
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      eval /opt/homebrew/Caskroom/miniconda/base/bin/conda shell.fish hook | source
    '';
  };
  programs.git = {
    enable = true;
    userName = "Daehyun You";
    userEmail = lib.mkDefault "daehyun.park.you@proton.me";
  };
  programs.direnv.enable = true;
  programs.home-manager.enable = true;
}
