{
  description = "BUG-016 repro shell with Roc nightly-2026-10-21-5349569";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    roc-overlay = {
      url = "github:roc-lang/roc-overlay/0563d2a0ba55a751449c54058328832309b0f3a1";
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
      rocFor = system: roc-overlay.packages.${system}.nightly-2026-10-21-5349569;
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
