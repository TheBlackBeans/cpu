{
  description = "CPU";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    utils.url = github:numtide/flake-utils;
    rust-overlay = {
      url = github:oxalica/rust-overlay;
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "utils";
      };
    };
    naersk.url = github:nix-community/naersk;
    beans.url = github:jthulhu/beans;
  };

  outputs = { self, nixpkgs, utils, naersk, rust-overlay, beans }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            rust-overlay.overlays.default
          ];
        };
        rust = pkgs.rust-bin.stable.latest.default.override {
          extensions = [
            "rust-src"
            "clippy"
          ];
        };
      in {
        devShell = pkgs.mkShell {
          packages = with pkgs; [
            svlint
            svls
            verilog
            fontconfig
            lmodern
            rust
            cargo
            cargo-edit
            rustfmt
            rustPackages.clippy
            rust-analyzer
            beans.defaultPackage.${system}
            (python3.withPackages (pypkgs: with pypkgs; [
              urwid
              ptpython
            ]))
            nodePackages.pyright
            ncurses
          ];
        };
      });
}
