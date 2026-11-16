{
  description = "Dec fraction-digit repro shell with Roc nightly-2026-11-15-f25da45";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    overlay0.url = "github:roc-lang/roc-overlay/1181a21dee94818725b9ecfa5ed54e7d9219cd0e";
  };

  outputs =
    { nixpkgs, overlay0, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ overlay0.overlays.default ];
      };
      rocFor = pkgs: pkgs.rocpkgs.nightly-2026-11-15-f25da45;
    in
    {
      packages = forAllSystems (system: {
        default = rocFor (pkgsFor system);
      });
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              (rocFor pkgs)
              pkgs.bash
              pkgs.coreutils
              pkgs.gnugrep
            ];
          };
        });
    };
}
