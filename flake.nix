{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";

    logseq_export_src.url = "github:viktomas/logseq-export";
    logseq_export_src.flake = false;
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;}
    {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = ["x86_64-linux" "aarch64-darwin"];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        import-to-hugo = pkgs.writeShellScriptBin "import-to-hugo" ''
          set -e

          if [[ -f $PWD/config.yaml ]]; then
            current_dir="$PWD"
          fi
          if [[ "$#" -ne 1 ]] && [[ -z "$current_dir" ]]; then
            echo "Usage: import-to-hugo \$PWD"
            exit 1
          fi
          current_dir="''${1:-$current_dir}"
          export_folder="$current_dir/export"
          blog_folder="$current_dir"

          pages_destination="$blog_folder/content/graph"
          assets_destination="$blog_folder/static/assets/graph"
          echo "Using following folders: "
          echo "export folder: $export_folder"
          echo "pages dest: $pages_destination"
          echo "assets dest: $assets_destination"

          mkdir -p "$pages_destination"
          mkdir -p "$assets_destination"

          ${pkgs.rsync}/bin/rsync --recursive --delete "$export_folder/logseq-pages/" "$pages_destination/"
          ${pkgs.rsync}/bin/rsync --recursive --delete "$export_folder/logseq-assets/" "$assets_destination/"

          ${pkgs.fd}/bin/fd \
            --type f \
            --full-path "$pages_destination" \
            --exec ${pkgs.sd}/bin/sd "/logseq-pages/" "$blog_folder/graph/"

          ${pkgs.fd}/bin/fd \
            --type f \
            --full-path "$pages_destination" \
            --exec ${pkgs.sd}/bin/sd "/logseq-assets/" "$blog_folder/assets/graph/"

          ${pkgs.fd}/bin/fd \
            --type f \
            --full-path "$pages_destination" \
            --exec ${pkgs.sd}/bin/sd -f sm '#\+BEGIN_([A-Z]*)[^\n]*(.*)#\+END_[^\n]*' '{{< logseq/org$1 >}}$2{{< / logseq/org$1 >}}'

          ${pkgs.fd}/bin/fd \
            --type f \
            --full-path "$pages_destination" \
            --exec ${pkgs.sd}/bin/sd -f sm '#\+BEGIN_([A-Z]*)[^\n]*(.*)#\+END_[^\n]*' '{{< logseq/org$1 >}}$2{{< / logseq/org$1 >}}'

          echo "Content moved successfully!"
        '';
      in {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
        packages.logseq-export = pkgs.buildGoModule rec {
          pname = "logseq-export";
          version = "master";
          src = inputs.logseq_export_src;
          vendorHash = "sha256-QMX8ms7RwT+eMVoUKfMXJN0BJjUUrBcSAOz6PVygsfA=";
        };
        packages.import-to-hugo = import-to-hugo;
        packages.default = pkgs.hello;

        devenv.shells.default = {
          name = "Logseq blog devenv";

          imports = [];

          # https://devenv.sh/reference/options/
          packages = [
            config.packages.default
            config.packages.logseq-export
            pkgs.hugo
            import-to-hugo
          ];

          languages.go.enable = true;

          # disable containers
          containers = pkgs.lib.mkForce {};

          enterShell = ''
            hello
          '';
        };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}
