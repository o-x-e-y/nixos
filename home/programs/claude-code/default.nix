{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.claude-code;
in
{
  options.apps.claude-code = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Claude Code configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
    };
    
    home.packages = [
      pkgs.claude-monitor
    ];
  };
}
