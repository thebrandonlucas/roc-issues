{
  description = "BUG-010 repro shell with Roc nightly-2026-09-26-d6267b4";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    overlay0.url = "github:thebrandonlucas/roc-overlay/75e0d3ae5c9a4d99eb14d2b13cac5a0e22fcd89d";
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
      rocFor = pkgs: pkgs.rocpkgs.nightly-2026-09-26-d6267b4;
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
              pkgs.python3
            ];
          };
        });
    };
}
