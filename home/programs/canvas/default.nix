{ pkgs, ... }:
let
  canvasScript =
    name:
    pkgs.writers.writePython3Bin name {
      libraries = [ pkgs.python3Packages.requests ];
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
