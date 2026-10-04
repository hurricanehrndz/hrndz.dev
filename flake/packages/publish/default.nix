{pkgs}:
pkgs.writeShellApplication {
  name = "publish";

  runtimeInputs = with pkgs; [
    coreutils
    findutils
    gawk
    gitMinimal
    gnugrep
    gnused
    vips
  ];

  text = builtins.readFile ./script.sh;
}
