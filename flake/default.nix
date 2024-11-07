{...}: {
  imports = [
    ./packages
  ];
  perSystem = {
    config,
    self',
    inputs',
    pkgs,
    system,
    ...
  }: {
    devenv.shells.default = {
      name = "DevEnv for publishing notes";

      # https://devenv.sh/reference/options/
      packages = [
        pkgs.hugo
        self'.packages.build-content
      ];

      languages.go.enable = true;

      # disable containers
      containers = pkgs.lib.mkForce {};
    };
  };
}
