{
  python3Packages,
  lib,
  runCommand,
}:
runCommand "mdformat-wrapped" {
  name = "mdformat";
  inherit (python3Packages.mdformat) version;
  nativeBuildInputs = [
    python3Packages.wrapPython
  ];
  pythonInputs = with python3Packages; [
    mdformat
    mdformat-gfm
    mdformat-frontmatter
    # mdformat-footnote
    mdformat-gfm-alerts
  ];
} ''
  buildPythonPath "$pythonInputs"

  makeWrapper ${lib.getExe python3Packages.mdformat} $out/bin/mdformat \
    --prefix PYTHONPATH : "$program_PYTHONPATH"
''
