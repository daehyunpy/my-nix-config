{
  home.homeDirectory = "/home/daehyun";
  programs.git.settings.user.email = "dyou@goremutual.ca";

  nixpkgs.overlays = [
    (_final: prev: {
      # Fedora's SSH supports the extensions in its system crypto policy.
      mosh = prev.mosh.override { openssh = "/usr"; };
    })
  ];
}
