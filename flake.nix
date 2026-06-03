{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
  in {
    packages = forAllSystems (system: rec {
      default = firmwareWithReset;

      firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
        name = "firmware";

        src = nixpkgs.lib.sourceFilesBySuffices self [ ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi" ".json" ".keymap" ".overlay" ".shield" ".yml" "Kconfig.defconfig" "Kconfig.shield" "_defconfig" ];

        board = "nice_nano_v2";
        shield = "Corne_%PART%";
        parts = [ "L" "R" ];
        centralPart = "L";
        enableZmkStudio = true;

        zephyrDepsHash = "sha256-F03oJNHWmHlpFc1JHyvqX02WL+Pg6ZcNWpCaiDfJANA=";

        meta = {
          description = "ZMK firmware";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      settings-reset = zmk-nix.legacyPackages.${system}.buildKeyboard {
        name = "settings-reset";

        src = nixpkgs.lib.sourceFilesBySuffices self [ ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi" ".json" ".keymap" ".overlay" ".shield" ".yml" "Kconfig.defconfig" "Kconfig.shield" "_defconfig" ];

        board = "nice_nano_v2";
        shield = "settings_reset";
        westDeps = firmware.westDeps;

        zephyrDepsHash = "sha256-F03oJNHWmHlpFc1JHyvqX02WL+Pg6ZcNWpCaiDfJANA=";

        meta = {
          description = "ZMK settings reset firmware";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      firmwareWithReset = nixpkgs.legacyPackages.${system}.runCommand "firmware-with-reset" {} ''
        mkdir "$out"
        ln -s ${firmware}/zmk_L.uf2 "$out/zmk_L.uf2"
        ln -s ${firmware}/zmk_R.uf2 "$out/zmk_R.uf2"
        ln -s ${settings-reset}/zmk.uf2 "$out/settings_reset.uf2"
      '';

      flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
      update = zmk-nix.packages.${system}.update;
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
