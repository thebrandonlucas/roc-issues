{
  description = "BUG-033 repro shell (roc docs broken links reported as an unreported error) with Roc nightly-2026-11-12-ce942d6";

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
      # The newest nightly in the pinned roc-overlay this reproduces on.
      rocFor = pkgs: pkgs.rocpkgs.nightly-2026-11-12-ce942d6;
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
      });
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = shellWith pkgs (rocFor pkgs);
        });
    };
}
