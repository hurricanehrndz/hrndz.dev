{pkgs}:
pkgs.writeShellApplication {
  name = "build-content";

  runtimeInputs = with pkgs; [
    coreutils
    gitMinimal
    rsync
  ];

  text = builtins.readFile ./script.sh;
}
