{
  description = "A minimal rust development flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nci.url = "github:yusdacra/nix-cargo-integration";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      imports = [
        inputs.devshell.flakeModule
        inputs.nci.flakeModule
      ];

      perSystem = {
        pkgs,
        config,
        ...
      }: let
        crateName = "my_crate";
        projectName = crateName;
        crateOutput = config.nci.outputs.${crateName};
      in {
        formatter = pkgs.alejandra;
        nci = {
          projects.${projectName}.path = ./.;
          crates.${crateName} = {};
        };
        devShells.default = crateOutput.devShell.overrideAttrs (old: {
          nativeBuildInputs =
            (with pkgs; [
              nil
              rust-analyzer
            ])
            ++ old.nativeBuildInputs;
        });
        packages.default = crateOutput.packages.release;
      };
    };
}
