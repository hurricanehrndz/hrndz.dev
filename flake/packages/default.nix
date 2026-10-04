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
      publish = import ./publish {
        inherit pkgs;
      };
      mdformat = pkgs.callPackage ./mdformat.nix {};
    };
  };
}
