{
  description = "Reproductions of Roc compiler issues, pinned to the compiler they were found on";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Intel macOS is no longer supported by nixos-unstable.
    nixpkgs-x86-darwin.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    # This overlay commit's `nightly` is nightly-2026-July-14-c9147c2
    # (`roc version` = release-fast-c9147c28), the compiler these bugs were
    # found on.
    roc-overlay = {
      url = "github:thebrandonlucas/roc-overlay/a9afdcfed9bf90c53e6b4b1443e00676a939e971";
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
    in
    {
      packages = forAllSystems (system: {
        roc = (pkgsFor system).rocpkgs."nightly-2026-July-14-c9147c2";
        default = (pkgsFor system).rocpkgs."nightly-2026-July-14-c9147c2";
      });

      devShells = forAllSystems (system: {
        default = (pkgsFor system).mkShell {
          packages = [
            (pkgsFor system).rocpkgs."nightly-2026-July-14-c9147c2"
            (pkgsFor system).llvmPackages.bintools
          ];
        };
      });
    };
}
