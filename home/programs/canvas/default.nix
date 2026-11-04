{ pkgs, ... }:
let
  python = pkgs.python3;

  canvas-api = python.pkgs.toPythonModule (
    pkgs.runCommand "canvas-api" { } ''
      install -Dm644 ${./canvas_api.py} $out/${python.sitePackages}/canvas_api.py
    ''
  );

  canvasScript =
    name:
    pkgs.writers.writePython3Bin name {
      libraries = [
        python.pkgs.requests
        canvas-api
      ];
      flakeIgnore = [ "E501" ];
    } (builtins.readFile ./${name}.py);
in
{
  home.packages = [
    (canvasScript "canvas-assignment")
    (canvasScript "canvas-outcomes")
  ];

  home.sessionVariables.CANVAS_EDITOR = "codium --wait";
}
