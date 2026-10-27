{ pkgs, ... }:
let
  canvas-assignment = pkgs.writers.writePython3Bin "canvas-assignment" {
    libraries = [ pkgs.python3Packages.requests ];
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./canvas-assignment.py);
in
{
  home.packages = [ canvas-assignment ];

  home.sessionVariables.CANVAS_EDITOR = "codium --wait";
}
