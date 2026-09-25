{
  description = "basic-cli platform built from roc-lang/basic-cli 473caa2 (PR #499)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/241313f4e8e508cb9b13278c2b0fa25b9ca27163";

    # No published basic-cli release works with Roc nightly-2026-09-23-c7852fd:
    # 0.22.2 and 0.23.0-rc1 both hang `roc check` (roc-lang/roc#11621).
    basic-cli-src = {
      url = "github:roc-lang/basic-cli/473caa2cc4f3fe9ce4e4682158bb80ebc2e19169";
      flake = false;
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay/fb058ecf6d14837ea152a3d5225ce7f88ee5cde1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      basic-cli-src,
      rust-overlay,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      rustTargetFor = {
        x64musl = "x86_64-unknown-linux-musl";
        arm64musl = "aarch64-unknown-linux-musl";
      };

      basicCliFor =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };
          rustToolchain = pkgs.rust-bin.fromRustupToolchain {
            channel =
              (builtins.fromTOML (builtins.readFile "${basic-cli-src}/rust-toolchain.toml")).toolchain.channel;
            components = [ "llvm-tools-preview" ];
            targets = lib.attrValues rustTargetFor;
          };
          rustPlatform = pkgs.makeRustPlatform {
            cargo = rustToolchain;
            rustc = rustToolchain;
          };
          buildTarget = rocTarget: rustTarget: ''
            python3 scripts/build.py --target ${rocTarget}
            # Keep the unstripped host; Kai strips its final executables.
            cp target/${rustTarget}/release/libhost.a platform/targets/${rocTarget}/libhost.a
          '';
        in
        rustPlatform.buildRustPackage {
          pname = "basic-cli-platform";
          version = "0.23.0-pr499";
          src = basic-cli-src;
          cargoLock.lockFile = "${basic-cli-src}/Cargo.lock";
          nativeBuildInputs = [
            pkgs.python3
            pkgs.zig_0_16
          ];
          postPatch = ''
            patchShebangs ci scripts
          '';
          buildPhase = ''
            runHook preBuild
            export CARGO_NET_OFFLINE=true
            export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
            ${lib.concatStrings (lib.mapAttrsToList buildTarget rustTargetFor)}
            runHook postBuild
          '';
          # Roc supplies the host's unresolved symbols when linking an app.
          doCheck = false;
          dontStrip = true;
          installPhase = ''
            runHook preInstall
            mkdir -p "$out"
            cp -R platform/. "$out/"
            runHook postInstall
          '';
        };
    in
    {
      packages = lib.genAttrs supportedSystems (system: {
        default = basicCliFor system;
      });
    };
}
