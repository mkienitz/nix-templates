{
  description = "A template for a simple Python dev environment";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      imports = [
        inputs.devshell.flakeModule
      ];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
        devshells.default = {
          packages = [
            pkgs.nil
            (pkgs.python3.withPackages (pyPkgs: [
              # Add your python packages here
            ]))
          ];
        };
      };
    };
}
