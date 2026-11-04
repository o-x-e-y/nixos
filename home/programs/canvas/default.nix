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

  canvas-feedback = canvasScript "canvas-feedback";
in
{
  home.packages = [
    (canvasScript "canvas-assignment")
    (canvasScript "canvas-outcomes")
    canvas-feedback
  ];

  systemd.user.services.canvas-feedback = {
    Unit.Description = "Notify about new feedback on Canvas submissions";
    Service = {
      Type = "oneshot";
      Environment = "PATH=${pkgs.libnotify}/bin";
      ExecStart = "${pkgs.lib.getExe canvas-feedback} --notify";
    };
  };

  systemd.user.timers.canvas-feedback = {
    Unit.Description = "Check Canvas for new feedback every hour";
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  home.sessionVariables.CANVAS_EDITOR = "codium --wait";
}
