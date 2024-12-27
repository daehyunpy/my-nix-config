{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nix-darwin, nixpkgs, nix-homebrew, home-manager }:
  let
    configuration = { pkgs, ... }: {
      nix.settings.experimental-features = "nix-command flakes";

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
        dock.persistent-apps = [
          "/System/Cryptexes/App/System/Applications/Safari.app"
          "/Applications/ChatGPT.app"
          "/System/Applications/Messages.app"
          "/Applications/Slack.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
          "/System/Applications/Reminders.app"
          "/System/Applications/Notes.app"
          "/System/Applications/Freeform.app"
          "/System/Applications/iPhone Mirroring.app"
          "/System/Applications/Utilities/Screen Sharing.app"
          "/System/Applications/Utilities/Activity Monitor.app"
          "/System/Applications/Utilities/Terminal.app"
          "/Applications/Visual Studio Code.app"
          "/Applications/Fork.app"
          "/Applications/DBeaver.app"
        ];
        finder.ShowPathbar = true;
        finder.ShowStatusBar = true;
        menuExtraClock.Show24Hour = true;
        NSGlobalDomain.AppleShowAllExtensions = true;
        NSGlobalDomain.AppleWindowTabbingMode = "always";
      };
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 5;

      nixpkgs.config.allowUnfree = true;

      users.users.daehyun = {
        home = "/Users/daehyun";
        shell = "${pkgs.fish}/bin/fish";
      };
    };
  in
  {
    darwinConfigurations.morpheus = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "daehyun";
          };
        }
        home-manager.darwinModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.daehyun = import ./home.nix;
          };
        }
      ];
    };

    darwinConfigurations.thales = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "daehyun";
          };
        }
        home-manager.darwinModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.daehyun = import ./home.nix;
          };
        }
      ];
    };
  };
}
