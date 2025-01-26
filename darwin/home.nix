{ pkgs, ... }:
{
  home = {
    stateVersion = "24.11";
    username = "daehyun";
    homeDirectory = "/Users/daehyun";
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
      ".condarc".source = ../home-files/conda.yaml;
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
    userEmail = "daehyun.park.you@proton.me";
  };
  programs.direnv.enable = true;
  programs.home-manager.enable = true;
}
