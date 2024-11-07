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
    };
  };
}
