{ pkgs, config, ... }:
{
  home.packages = import ./packages.nix pkgs;

  # Editors and child processes must use the same Fish as the login shell.
  home.sessionVariables.SHELL = "${config.home.profileDirectory}/bin/fish";
}
