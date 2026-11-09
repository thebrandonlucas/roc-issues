{
  description = "BUG-020 repro shell with Roc nightly-2026-11-03-34bd006";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    roc-overlay = {
      url = "github:roc-lang/roc-overlay/46bac4118b0c1538129de5a23afe4d75a654edc4";
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
      rocFor = system: roc-overlay.packages.${system}.nightly-2026-11-03-34bd006;
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
