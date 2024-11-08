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
      pre-commit.hooks = {
        # lint shell scripts
        shellcheck.enable = true;
        # lint nix files
        alejandra.enable = true;

        trim-trailing-whitespace = {
          enable = true;
          excludes = [
            "^\.gitignore$"
          ];
        };
        end-of-file-fixer.enable = true;
        check-added-large-files.enable = true;
        check-yaml.enable = true;
        check-toml.enable = true;
        markdownlint.enable = true;
        treefmt = {
          enable = true;
          settings.formatters = [
            pkgs.alejandra
            self'.packages.mdformat
          ];
        };
      };

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
