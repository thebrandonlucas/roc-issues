{
  description = "BUG-036 repro shell (a package path naming a type module is accepted) with Roc nightly-2026-11-14-a87808d";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    overlay0.url = "github:roc-lang/roc-overlay/b69e059db9ea70f63ac9055838ddfd55736a9c27";
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
      rocFor = pkgs: pkgs.rocpkgs.nightly-2026-11-14-a87808d;
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
