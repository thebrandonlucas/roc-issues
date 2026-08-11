{
  description = "Reproductions of Roc compiler issues, pinned to the compiler they were found on";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Intel macOS is no longer supported by nixos-unstable.
    nixpkgs-x86-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    # Pin the overlay catalog so every recorded compiler remains reproducible.
    # The default shell still uses the compiler these bugs were found on.
    roc-overlay = {
      url = "github:thebrandonlucas/roc-overlay/9fb8a897144075e042c3aac7705d76ddf8ea0d6f";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin.follows = "nixpkgs-x86-darwin";
    };
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-x86-darwin,
      roc-overlay,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs supportedSystems;
      pkgsFor =
        system:
        import (if system == "x86_64-darwin" then nixpkgs-x86-darwin else nixpkgs) {
          inherit system;
          overlays = [ roc-overlay.overlays.default ];
        };

      foundVersion = "nightly-2026-July-14-c9147c2";
      mkRocShell =
        pkgs: roc:
        pkgs.mkShell {
          packages = [
            roc
            pkgs.llvmPackages.bintools
          ];
        };
    in
    {
      # Expose every compiler recorded by roc-overlay. `default`, `found`, and
      # `roc` select the compiler the bug was found on; `latest` tracks the
      # newest compiler in this pinned overlay catalog.
      packages = forAllSystems (
        system:
        let
          versions = roc-overlay.packages.${system};
          found = versions.${foundVersion};
        in
        versions
        // {
          inherit found;
          roc = found;
          default = found;
          latest = versions.nightly;
        }
      );

      # `nix develop .#<release-tag>` switches the active Roc compiler while
      # retaining the common debugging tools.
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          versions = roc-overlay.packages.${system};
          versionShells = lib.mapAttrs (_: roc: mkRocShell pkgs roc) versions;
          found = mkRocShell pkgs versions.${foundVersion};
        in
        versionShells
        // {
          inherit found;
          roc = found;
          default = found;
          latest = mkRocShell pkgs versions.nightly;
        }
      );
    };
}
