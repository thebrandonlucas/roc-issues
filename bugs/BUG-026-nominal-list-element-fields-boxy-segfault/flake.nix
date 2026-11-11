{
  description = "BUG-026 repro shell with Roc nightly-2026-11-11-7679cc5";

  # roc-overlay has no nightly-2026-11-11 yet, so the compiler is Roc's own
  # download for each platform, pinned by hash.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      tag = "nightly-2026-11-11-7679cc5";
      assets = {
        x86_64-linux = {
          url = "https://github.com/roc-lang/nightlies/releases/download/${tag}/roc_nightly-linux_x86_64-2026-11-11-7679cc5.tar.gz";
          hash = "sha256-RFPhnA2EyMBrndbSDv/qzYFR3mIZEz08udNhI1WpsYk=";
        };
        aarch64-linux = {
          url = "https://github.com/roc-lang/nightlies/releases/download/${tag}/roc_nightly-linux_arm64-2026-11-11-7679cc5.tar.gz";
          hash = "sha256-EgZtWaouXfY4FbdK/DbYllCtFbCu5bKe7VEOKrL7aWo=";
        };
      };
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      rocFor =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "roc";
          version = tag;
          src = pkgs.fetchurl assets.${system};
          sourceRoot = ".";
          dontStrip = true;
          installPhase = ''
            mkdir -p $out/bin
            cp "$(find . -type f -name roc | head -1)" $out/bin/roc
          '';
        };
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
