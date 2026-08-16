{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.claude-code;

  # Deliberately a CLI and not an MCP server. The decision this has to serve is
  # "which hour do I ride", so it needs an hourly profile — which rules out
  # mcp-server-openmeteo (daily only). The one hourly-capable server,
  # @dangahagan/weather-mcp, loads 17 tool schemas into every session for the
  # two that would ever get used, and pulls in nine npm dependencies. Open-Meteo
  # is an unauthenticated GET, so a curl wrapper in the shape of intervals-icu.sh
  # costs one allowlist entry and no per-session context.
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

    # No secret to declare: Open-Meteo needs no API key, so unlike the
    # intervals.icu and Cronometer integrations this reads nothing from
    # /run/secrets. Lists merge across modules, so this appends to the
    # allowlist in ../default.nix rather than replacing it.
    programs.claude-code.settings.permissions.allow = [ "Bash(weather:*)" ];
  };
}
