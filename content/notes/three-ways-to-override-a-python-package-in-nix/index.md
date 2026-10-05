---
# vim: set ft=markdown tw=72:
date: 2025-03-02T20:20:59-0700
lastmod: 2025-03-04T18:26:24-0700
draft: false
publish: true
aliases: [/notes/qep3x1bi/]
tags: [nix]
title: "Three ways to override a Python package in Nix"
---

Recently, I found myself needing to run a more recent version of a
Python package. Like any good Nixer, I concluded that a package override
was in order. For whatever reason, my immediate approach, documented as
the default shell below, kept failing me and a solution eluded me.

After some time banging my head against the wall, I ended up retreating
to the Nix manual. That's when I discovered three other solutions.

Below, you will find the three solutions plainly documented in three
distinct and obvious development shells. You can play with each one by
just running `nix develop`, adjusting the command for whichever shell
you wish to explore.

```nix
{
  description = "Example of overridePythonAttrs";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # newer python packages sources
    mdformat-src.url = "github:hukkin/mdformat";
    mdformat-src.flake = false;
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        # does not work/broken
        devShells.default = let
          myCustomPython = pkgs.python3.withPackages (ps:
            with ps; [
              (mdformat.overridePythonAttrs (old: {
                src = inputs.mdformat-src;
              }))
            ]);
        in
          pkgs.mkShell
          {
            nativeBuildInputs = with myCustomPython.pkgs; [
              mdformat
            ];
          };
        # create a custom python runtime with the mdformat package overridden
        devShells.solution1 = let
          myCustomPython = pkgs.python3.withPackages (ps:
            with ps; [
              (mdformat.overridePythonAttrs (old: {
                version = "0.7.22";
                src = inputs.mdformat-src;
              }))
            ]);
        in
          pkgs.mkShell
          {
            nativeBuildInputs = [
              myCustomPython
            ];
          };
        # override mdformat package
        devShells.solution2 = let
          # old is omitted per documentation as it is not accessed
          # https://ryantm.github.io/nixpkgs/using/overrides/#sec-pkg-overrideAttrs
          custom-mdformat = pkgs.python3Packages.mdformat.overridePythonAttrs {
            version = "0.7.22";
            src = inputs.mdformat-src;
          };
        in
          pkgs.mkShell
          {
            nativeBuildInputs = [
              custom-mdformat
            ];
          };
        # override packages in python3 derivation, use mdformat from new python3 definition (py3)
        devShells.solution3 = let
          py3 = let
            packageOverrides = final: prev: {
              mdformat = prev.mdformat.overridePythonAttrs (old: rec {
                version = "0.7.22";
                src = inputs.mdformat-src;
              });
            };
          in
            pkgs.python3.override {
              inherit packageOverrides;
              self = py3;
            };
        in
          pkgs.mkShell
          {
            nativeBuildInputs = [
              py3.pkgs.mdformat
            ];
          };
      };
    };
}
```
