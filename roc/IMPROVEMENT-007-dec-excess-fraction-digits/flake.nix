{
  description = "Dec fraction-digit repro shell with Roc nightly-2026-11-12-ce942d6";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    overlay0.url = "github:roc-lang/roc-overlay/67491987eb6ef2423d9a6e5901f6a8e439d8566c";
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
      rocFor = pkgs: pkgs.rocpkgs.nightly-2026-11-12-ce942d6;
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
