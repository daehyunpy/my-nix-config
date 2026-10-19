{ lib, pkgs, ... }:
{
  # Native NixOS and nix-darwin modules own the privileged daemon.
  # Home Manager must not import this module or start another daemon.
  # Host roles (exit node, subnet routes, SSH) stay out of these defaults.
  services.tailscale = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.tailscale;
  };
}
