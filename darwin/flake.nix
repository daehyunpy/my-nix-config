{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs, # Expected warning
      nixpkgs-unstable,
      nix-darwin,
      nix-homebrew,
      home-manager,
    }:
    let
      configuration =
        { pkgs, lib, ... }:
        {
          nix.settings.experimental-features = "nix-command flakes";

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
            masApps = import ./mas-apps.nix;
          };

          programs.zsh.enable = true;
          programs.fish.enable = true;

          system.defaults = {
            dock = {
              persistent-apps = lib.mkDefault [
                "/System/Cryptexes/App/System/Applications/Safari.app"
                "/Applications/ChatGPT Atlas.app"
                "/Applications/ChatGPT.app"
                "/System/Applications/Messages.app"
                "/Applications/Slack.app"
                "/System/Applications/Mail.app"
                "/System/Applications/Calendar.app"
                "/System/Applications/Reminders.app"
                "/System/Applications/Notes.app"
                "/System/Applications/Stickies.app"
                "/System/Applications/iPhone Mirroring.app"
                "/System/Applications/Utilities/Screen Sharing.app"
                "/System/Applications/Utilities/Activity Monitor.app"
                "/Applications/WezTerm.app"
                "/Applications/Zed.app"
                "/Applications/Cursor.app"
                "/Applications/Fork.app"
                "/Applications/DBeaver.app"
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

          system.primaryUser = "daehyun";
          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 5;

          security.sudo.extraConfig = ''
            %admin ALL=(ALL) NOPASSWD: ALL
          '';

          users.users.daehyun = {
            home = "/Users/daehyun";
            shell = pkgs.fish;
          };
        };
    in
    {
      darwinConfigurations.morpheus = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "daehyun";
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
          {
            home-manager = {
              users.daehyun = import ../home.nix;
            };
          }
          {
            home-manager = {
              users.daehyun = import ./home.nix;
            };
          }
          {
            homebrew.brews = [
              "gdal"
            ];
            homebrew.casks = [
              "bitwarden"
              "docker-desktop"
              "latexit"
              "mactex-no-gui"
              "qgis"
            ];
          }
        ];
      };

      darwinConfigurations.apollo = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "daehyun";
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
          {
            home-manager = {
              users.daehyun = import ../home.nix;
            };
          }
          {
            home-manager = {
              users.daehyun = import ./home.nix;
            };
          }
        ];
      };

      darwinConfigurations.thales = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = "daehyun";
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
          {
            home-manager = {
              users.daehyun = import ../home.nix;
            };
          }
          {
            home-manager = {
              users.daehyun = import ./home.nix;
            };
          }
          {
            homebrew.casks = [ "plex-media-server" ];
            system.defaults.dock.persistent-apps = [
              "/System/Cryptexes/App/System/Applications/Safari.app"
              "/Applications/Tor Browser.app"
              "/Applications/ChatGPT Atlas.app"
              "/Applications/ChatGPT.app"
              "/System/Applications/Messages.app"
              "/System/Applications/Mail.app"
              "/System/Applications/Calendar.app"
              "/System/Applications/Reminders.app"
              "/System/Applications/Notes.app"
              "/System/Applications/Stickies.app"
              "/System/Applications/iPhone Mirroring.app"
              "/System/Applications/Utilities/Screen Sharing.app"
              "/System/Applications/Utilities/Activity Monitor.app"
              "/Applications/WezTerm.app"
              "/Applications/Zed.app"
              "/Applications/Cursor.app"
              "/Applications/Fork.app"
              "/Applications/Transmission.app"
            ];
          }
        ];
      };
    };
}
