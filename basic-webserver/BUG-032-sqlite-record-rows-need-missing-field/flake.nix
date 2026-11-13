{
  description = "BUG-032 repro shell (basic-webserver 0.21.0 Sqlite missing_field) with Roc nightly-2026-11-12-ce942d6";

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
      # The newest nightly this was checked on, and the last one that works.
      rocFor = pkgs: pkgs.rocpkgs.nightly-2026-11-12-ce942d6;
      lastGoodRocFor = pkgs: pkgs.rocpkgs.nightly-2026-11-09-9e85de7;
      shellWith = pkgs: roc: pkgs.mkShell {
        packages = [
          roc
          pkgs.bash
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnused
        ];
      };
    in
    {
      packages = forAllSystems (system: {
        default = rocFor (pkgsFor system);
        last-good = lastGoodRocFor (pkgsFor system);
      });
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = shellWith pkgs (rocFor pkgs);
          last-good = shellWith pkgs (lastGoodRocFor pkgs);
        });
    };
}
