{ pkgs, config, ... }:
let
  homePathString = config.home.homeDirectory;
  makeOutOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home.packages = import ./packages.nix pkgs;
  home.file = {
    "Library/Application Support/Cursor/User".source =
      makeOutOfStore "${homePathString}/.config/nix/home-files/cursor-user";
  };

  programs.fish = {
    interactiveShellInit = ''
      eval /opt/homebrew/Caskroom/miniconda/base/bin/conda shell.fish hook | source
    '';
  };
}
