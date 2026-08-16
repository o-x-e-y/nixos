{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.claude-code;

  # cronometer-api-mcp is not in nixpkgs, and nixpkgs' python3Packages.mcp
  # (1.27.1) is below the >=1.29 it requires, so it is run from PyPI through
  # uvx rather than built here. Pinned, and pointed at nixpkgs' Python so uv
  # never downloads a non-NixOS interpreter.
  cronometer-mcp-version = "0.2.1";
in
{
  config = lib.mkIf cfg.enable {
    # Only `programs.mcp.servers` runs env file refs through
    # `wrapEnvFilesCommand`; `programs.claude-code.mcpServers` would write the
    # values verbatim into a world-readable /nix/store JSON. Credentials must
    # therefore be declared here, and read from /run/secrets at spawn time.
    programs.mcp = {
      enable = true;

      servers.cronometer = {
        command = lib.getExe' pkgs.uv "uvx";
        args = [
          "--python"
          "${pkgs.python314}/bin/python3"
          "cronometer-api-mcp==${cronometer-mcp-version}"
        ];
        env = {
          CRONOMETER_USERNAME.file = "/run/secrets/cronometer-email";
          CRONOMETER_PASSWORD.file = "/run/secrets/cronometer-password";
          CRONOMETER_ACCOUNT_TZ = "Europe/Amsterdam";
          UV_PYTHON_DOWNLOADS = "never";
        };
      };
    };

    # Lists merge across modules, so these append to the allow/deny lists in
    # ../default.nix rather than replacing them.
    programs.claude-code.settings.permissions = {
      # The read half of Cronometer: what was logged, and the weight
      # series fuel.py calibrates against.
      allow = [
        "mcp__cronometer__get_food_log"
        "mcp__cronometer__get_daily_nutrition"
        "mcp__cronometer__get_nutrition_scores"
        "mcp__cronometer__get_macro_targets"
        "mcp__cronometer__search_foods"
        "mcp__cronometer__get_food_details"
        "mcp__cronometer__list_biometrics"
        "mcp__cronometer__get_biometrics"
        "mcp__cronometer__get_fasting_history"
        "mcp__cronometer__get_fasting_stats"
      ];

      # Cronometer is an evidence base, not something to edit. Reading
      # the log is the coaching use; writing to it is not.
      deny = [
        "mcp__cronometer__add_food_entry"
        "mcp__cronometer__remove_food_entry"
        "mcp__cronometer__add_custom_food"
        "mcp__cronometer__copy_day"
        "mcp__cronometer__mark_day_complete"
      ];
    };
  };
}
