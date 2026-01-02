{
  pkgs,
  config,
  lib,
  ...
}:
let
  homePathString = config.home.homeDirectory;
  makeOutOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  home = {
    stateVersion = "25.11";
    username = lib.mkDefault "daehyun";
    homeDirectory = lib.mkDefault "/Users/daehyun";
    packages = import ./packages.nix pkgs;
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.local/share/npm/bin"
      "$HOME/.local/share/pnpm"
    ];
    sessionVariables = {
      EDITOR = "/usr/bin/vim";
      NPM_CONFIG_PREFIX = "${homePathString}/.local/share/npm";
      PNPM_HOME = "${homePathString}/.local/share/pnpm";
    }
    // builtins.fromJSON (builtins.readFile ./secret-envs.json);
    file = {
      ".config/conda".source = ./home-files/conda;
      ".config/direnv".source = ./home-files/direnv;
      ".config/tmux".source = ./home-files/tmux;
      ".config/wezterm".source = ./home-files/wezterm;
      ".config/zed".source = makeOutOfStore "${homePathString}/.config/nix/home-files/zed";
      ".ssh/config".source = makeOutOfStore "${homePathString}/.config/nix/home-files/ssh/config";
    };
  };

  programs.zsh.enable = true;
  programs.fish = {
    enable = true;
    shellInit = ''
      direnv export fish | source
    '';
  };
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = "Daehyun You";
      user.email = lib.mkDefault "daehyun.park.you@proton.me";
      branch.sort = "-committerdate";
      column.ui = "auto";
      diff = {
        algorithm = "histogram";
        colorMoved = "plain";
        mnemonicPrefix = "true";
        renames = "true";
      };
      fetch = {
        prune = "true";
        pruneTags = "true";
        all = "true";
      };
      init.defaultBranch = "main";
      merge.conflictstyle = "zdiff3";
      pull.rebase = "true";
      push.autoSetupRemote = "true";
      rebase = {
        autoSquash = "true";
        autoStash = "true";
        updateRefs = "true";
      };
      rerere = {
        enabled = "true";
        autoupdate = "true";
      };
      tag.sort = "version:refname";
    };
  };
  programs.direnv.enable = true;
  programs.home-manager.enable = true;
}
