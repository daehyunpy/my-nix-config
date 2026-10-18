{ pkgs, config, ... }:
{
  home.packages = import ./packages.nix pkgs;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
    persistent = true;
  };

  # Editors and child processes must use the same Fish as the login shell.
  home.sessionVariables.SHELL = "${config.home.profileDirectory}/bin/fish";
}
