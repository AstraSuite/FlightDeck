{
  description = "FlightDeck - Qt6 GUI controller and management cockpit for Hyprland and Caelestia";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    m3shapes = {
      url = "github:soramanew/m3shapes/bdc327b29f95394a732baf3c9b19658ba23755b6";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = fn:
      nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux (
        system: fn nixpkgs.legacyPackages.${system}
      );
  in {
    packages = forAllSystems (pkgs: rec {
      flightdeck = pkgs.callPackage ./nix {
        inherit (inputs) m3shapes;
      };
      default = flightdeck;
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          cmake
          ninja
          pkg-config
          qt6.qtbase
          qt6.qtdeclarative
          qt6.qtshadertools
          qt6.qtsvg
          hyprland
          lua5_4
          glib
          dconf
          xrdb
        ];
      };
    });

    apps = forAllSystems (pkgs: {
      default = {
        type = "app";
        program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/flightdeck";
        meta.description = "Launch FlightDeck GUI controller";
      };
      flightdeck = {
        type = "app";
        program = "${self.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/flightdeck";
        meta.description = "Launch FlightDeck GUI controller";
      };
    });

    homeManagerModules.default = {
      config,
      lib,
      pkgs,
      ...
    }:
      with lib; let
        pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        cfg = config.programs.flightdeck;
      in {
        options.programs.flightdeck = {
          enable = mkEnableOption "FlightDeck - Qt6 GUI controller and management cockpit for Hyprland and Caelestia";
          package = mkOption {
            type = types.package;
            default = pkg;
            description = "The FlightDeck package to use.";
          };
        };

        config = mkIf cfg.enable {
          home.packages = [cfg.package];
        };
      };

    homeModules.default = self.homeManagerModules.default;
  };
}
