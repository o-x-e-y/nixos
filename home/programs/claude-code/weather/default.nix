{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.claude-code;

  # A CLI rather than an MCP server: the only hourly-capable one loads 17 tool
  # schemas into every session for the two that would get used.
  weather = pkgs.writeShellApplication {
    name = "weather";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
      util-linux # column, for the hourly table
    ];
    text = builtins.readFile ./weather.sh;
  };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ weather ];

    programs.claude-code.settings.permissions.allow = [ "Bash(weather:*)" ];
  };
}
