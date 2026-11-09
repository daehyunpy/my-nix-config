{
  pkgs,
  lib,
  self,
  nixpkgs-unstable,
  ...
}:
{
  imports = [
    { home-manager.users.daehyun = import ../home; }
    { home-manager.users.daehyun = import ./home.nix; }
  ];

  nix.settings.experimental-features = "nix-command flakes";

  nix.gc = {
    automatic = true;
    interval = [
      {
        Weekday = 7;
        Hour = 3;
        Minute = 15;
      }
    ];
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      unstable = import nixpkgs-unstable {
        system = prev.system;
        config.allowUnfree = true;
      };
    })
  ];

  environment.systemPackages = [ pkgs.fish ];
  environment.shells = [ pkgs.fish ];

  homebrew = {
    enable = true;
    brews = import ./brews.nix;
    casks = import ./casks.nix;
    masApps = import ./mas.nix;
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  programs.zsh.enable = true;
  programs.fish.enable = true;

  system.defaults = {
    dock = {
      persistent-apps = lib.mkDefault [
        # Conversation browser; CoreServices/Siri.app invokes the assistant.
        "/System/Applications/Siri AI.app"
        "/System/Cryptexes/App/System/Applications/Safari.app"
        "/System/Applications/Messages.app"
        "/System/Applications/Mail.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/Stickies.app"
        "/System/Applications/Notes.app"
        "/System/Applications/iPhone Mirroring.app"
        "/System/Applications/Utilities/Screen Sharing.app"
        "/System/Applications/Utilities/Activity Monitor.app"
        "/Applications/WezTerm.app"
        "/Applications/Zed.app"
        "/Applications/Fork.app"
      ];
      appswitcher-all-displays = true;
      largesize = 128;
      magnification = true;
      mru-spaces = false;
    };

    finder.ShowPathbar = true;
    finder.ShowStatusBar = true;

    menuExtraClock.Show24Hour = true;

    NSGlobalDomain = {
      AppleICUForce24HourTime = true;
      AppleMetricUnits = 1;
      AppleTemperatureUnit = "Celsius";

      AppleShowAllExtensions = true;
      AppleWindowTabbingMode = "always";
    };

    CustomUserPreferences = {
      "NSGlobalDomain" = {
        NSQuitAlwaysKeepsWindows = true;
      };
      "com.apple.dock" = {
        workspaces-auto-swoosh = false;
      };
    };

    NSGlobalDomain.KeyRepeat = 1;
    NSGlobalDomain."com.apple.trackpad.scaling" = 3.0;
    ".GlobalPreferences"."com.apple.mouse.scaling" = 3.0;
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 5;

  security.sudo.extraConfig = ''
    %admin ALL=(ALL) NOPASSWD: ALL
  '';
}
