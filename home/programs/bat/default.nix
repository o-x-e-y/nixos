{
  config,
  lib,
  ...
}:
let
  cfg = config.apps.bat;
in
{
  options.apps.bat = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable bat, a cat replacement with syntax highlighting";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config = {
        theme = "ansi";
        squeeze-blank = "true";
      };
    };
  };
}
