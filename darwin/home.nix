{ pkgs, ... }:
{
  home.packages = import ./packages.nix pkgs;

  # Preserve the current app handling independently of home.stateVersion.
  targets.darwin.copyApps.enable = true;
  targets.darwin.linkApps.enable = false;

  # Use the system man command instead of installing another implementation.
  programs.man.package = null;

  programs.fish = {
    interactiveShellInit = ''
      eval /opt/homebrew/Caskroom/miniconda/base/bin/conda shell.fish hook | source
    '';
  };
}
