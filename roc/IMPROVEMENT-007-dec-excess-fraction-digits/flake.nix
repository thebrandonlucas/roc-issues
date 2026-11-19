{
  description = "Dec fraction-digit repro shell with Roc nightly-2026-11-18-a520eed";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    overlay0.url = "github:roc-lang/roc-overlay/69640a7dd0ad1e8d8123ff4a34dff5c57c19fa3a";
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
      rocFor = pkgs: pkgs.rocpkgs.nightly-2026-11-18-a520eed;
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
