{
  description = "A minimal rust development flake";

  inputs = {
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nci = {
      url = "github:yusdacra/nix-cargo-integration";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      imports = [
        inputs.devshell.flakeModule
        inputs.nci.flakeModule
        inputs.pre-commit-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        {
          pkgs,
          config,
          lib,
          ...
        }:
        let
          # Read Cargo.toml to derive crate names etc.
          toml = builtins.fromTOML (builtins.readFile ./Cargo.toml);

          # For simple crate
          crateNames = [ toml.package.name ];
          # For workspace
          # crateNames = toml.workspace.members
        in
        {
          devshells.default = {
            packages = [
              pkgs.nil
            ]
            ++ (lib.optionals pkgs.stdenv.isDarwin [
              pkgs.libiconv
            ]);

            devshell.startup.pre-commit.text = config.pre-commit.installationScript;

            env = [
              # For classic target/release/ paths
              {
                name = "CARGO_BUILD_TARGET";
                unset = true;
              }
            ]
            ++ (lib.optionals pkgs.stdenv.isDarwin [
              {
                # On darwin for example enables finding of libiconv
                name = "LIBRARY_PATH";
                eval = "$DEVSHELL_DIR/lib";
              }
            ]);
          };

          pre-commit.settings.hooks.treefmt.enable = true;

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              deadnix.enable = true;
              statix.enable = true;
              nixfmt.enable = true;
              taplo.enable = true;
              rustfmt = {
                enable = true;
                # For simple crate
                inherit (toml.package) edition;
                # For workspaces
                # inherit (toml.workspace.package) edition;
              };
            };
          };

          nci = {
            projects."A rust project" = {
              path = ./.;
              numtideDevshell = "default";
            };
            crates = lib.genAttrs crateNames (_: { });
          };
        };
    };
}
