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
        "x86_64-darwin"
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
          ...
        }:
        let
          crateName = "my-crate";
          projectName = crateName;
        in
        {
          devshells.default = {
            packages = [
              pkgs.nil
            ];
            devshell.startup.pre-commit.text = config.pre-commit.installationScript;
          };

          pre-commit.settings.hooks.treefmt.enable = true;

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              deadnix.enable = true;
              statix.enable = true;
              nixfmt.enable = true;
              taplo.enable = true;
              rustfmt =
                let
                  toml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
                in
                {
                  enable = true;
                  inherit (toml.workspace.package) edition;
                  # If not using workspaces:
                  # inherit (toml.package) edition;
                };
            };
          };

          nci = {
            projects.${projectName} = {
              path = ./.;
              numtideDevshell = "default";
            };
            crates.${crateName} = { };
          };

          packages.default = config.nci.${crateName}.packages.release;
        };
    };
}
