{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, fenix, crane, flake-parts, advisory-db, ... }:
    flake-parts.lib.mkFlake { inherit self inputs; } ({ withSystem, ... }: {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem = { lib, config, self', inputs', pkgs, system, ... }:
        let
          rustToolchain = with fenix.packages.${system};
            combine [
              (latest.withComponents [
                "rustc"
                "cargo"
                "rustfmt"
                "clippy"
                "rust-src"
              ])

              targets.wasm32-unknown-unknown.latest.rust-std
            ];

          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

          commonArgs = rec {
            pname = "nix-bevy-wasm";
            version = "v0.1.0";

            src = lib.cleanSourceWith {
              src = ./.;
              filter = path: type:
                (lib.hasSuffix "\.html" path) ||
                (lib.hasSuffix "\.scss" path) ||
                (lib.hasInfix "/assets/" path) ||
                (craneLib.filterCargoSources path type)
              ;
            };

            buildInputs = [ ];
            nativeBuildInputs = with pkgs; [ clang lld ];

            strictDeps = true;
            doCheck = false;

            CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
          };

          cargoArtifacts = craneLib.buildDepsOnly (commonArgs // { doCheck = false; });

          clippy-check = craneLib.cargoClippy (commonArgs // {
            inherit cargoArtifacts;

            cargoClippyExtraArgs = "--all-features -- --deny warnings";
          });

          rust-fmt-check = craneLib.cargoFmt ({
            inherit (commonArgs) src;
          });

          audit-check = craneLib.cargoAudit ({
            inherit (commonArgs) src;
            inherit advisory-db;
          });

          package = craneLib.buildTrunkPackage (commonArgs // {
            inherit cargoArtifacts;

            fixupPhase = ''
              substituteInPlace $out/index.html \
                --replace '"/' '"./' \
                --replace "'/" "'./"
            '';
          });
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = commonArgs.buildInputs ++ [
              rustToolchain
              pkgs.trunk
              pkgs.dart-sass
              pkgs.wasm-bindgen-cli
            ];

            nativeBuildInputs = commonArgs.nativeBuildInputs ++ [ ];
            CARGO_BUILD_TARGET = "wasm32-unknown-unknown";
          };

          packages.default = package;

          checks =
            {
              inherit clippy-check rust-fmt-check audit-check;
              inherit (builtios.attrValues self.packages);
            };

          formatter = pkgs.nixpkgs-fmt;
        };
    });

  nixConfig = {
    extra-trusted-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };
}
