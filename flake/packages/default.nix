{inputs, ...}: {
  perSystem = {
    inputs',
    system,
    config,
    lib,
    pkgs,
    ...
  }: {
    packages = {
      build-content = import ./build-content {
        inherit pkgs;
      };
      mdformat = pkgs.callPackage ./mdformat.nix {};
    };
  };
}
