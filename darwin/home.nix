{ pkgs, lib, ... }:
let
  splitByDot = with builtins; string: filter isString (split "\\." string);
  getAttrFromStrPath = string: lib.attrsets.getAttrFromPath (splitByDot string);
in {
  home = {
    stateVersion = "24.11";
    username = "daehyun";
    homeDirectory = "/Users/daehyun";
    packages =
      builtins.map
      (name: getAttrFromStrPath name pkgs)
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
}
