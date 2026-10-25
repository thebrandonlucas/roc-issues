{
  description = "BUG-019 repro shell with Roc nightly-2026-10-23-18478ff";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    roc-overlay = {
      url = "github:roc-lang/roc-overlay/d0ad2328b1d81e2f6dcfcdf1fc800d9e74838a4d";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, roc-overlay, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      rocFor = system: roc-overlay.packages.${system}.nightly-2026-10-23-18478ff;
    in
    {
      packages = forAllSystems (system: {
        default = rocFor system;
      });
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              (rocFor system)
              pkgs.bash
              pkgs.coreutils
              pkgs.gnugrep
            ];
          };
        });
    };
}
