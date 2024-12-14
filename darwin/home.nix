{ pkgs, ... }: {
  home = {
    stateVersion = "24.11";
    username = "daehyun";
    homeDirectory = "/Users/daehyun";
    packages =
      builtins.map
      (name: pkgs.${name})
      (import ../packages.nix ++ import ./packages.nix);
    file = {
      ".config/direnv/direnv.toml".source = ../home-files/direnv.toml;
    };
  };

  programs.git = {
    enable = true;
    userName = "Daehyun You";
    userEmail = "daehyun.park.you@proton.me";
  };
  programs.direnv.enable = true;
}
