{ pkgs, ... }:
{
  home.packages = import ./packages.nix pkgs;
  programs.fish = {
    interactiveShellInit = ''
      eval /opt/homebrew/Caskroom/miniconda/base/bin/conda shell.fish hook | source
    '';
  };
}
