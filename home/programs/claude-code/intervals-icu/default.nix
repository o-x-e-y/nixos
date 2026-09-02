{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.claude-code;

  intervals-icu-mcp = pkgs.callPackage ./package.nix { };

  # Same athlete the ../intervals-icu.sh reader hardcodes. intervals.icu ids
  # carry the `i` prefix in every API path, and config.py passes ATHLETE_ID
  # straight through to the URL, so the prefixed form is what belongs here.
  athleteId = "i563199";
in
{
  config = lib.mkIf cfg.enable {
    # As in ../cronometer: only `programs.mcp.servers` runs env file refs
    # through `wrapEnvFilesCommand`, so the key is read from /run/secrets at
    # spawn time instead of being baked into a world-readable store JSON. The
    # secret already exists -- ../intervals-icu.sh reads the same file.
    programs.mcp = {
      enable = true;

      servers.intervals-icu = {
        command = lib.getExe intervals-icu-mcp;
        env = {
          INTERVALS_API_KEY.file = "/run/secrets/intervals_icu_key";
          ATHLETE_ID = athleteId;
        };
      };
    };

    # Lists merge across modules, so these append to the allow/ask/deny lists in
    # ../default.nix rather than replacing them.
    programs.claude-code.settings.permissions = {
      # The read half, and the reason this sits alongside intervals-icu.sh
      # rather than replacing it: the script returns raw API JSON, while these
      # return the consolidated week/fuelling/metrics shapes the coaching
      # prompts are built around. validate_week_plan only checks a plan against
      # the upload schema -- it touches nothing.
      allow = [
        "mcp__intervals-icu__prepare_week_data"
        "mcp__intervals-icu__get_coach_input"
        "mcp__intervals-icu__get_fueling_analysis"
        "mcp__intervals-icu__get_latest_metrics"
        "mcp__intervals-icu__get_activity_streams_sampled"
        "mcp__intervals-icu__list_library_workouts"
        "mcp__intervals-icu__validate_week_plan"
      ];

      # Gated rather than denied -- writing the plan IS the point of adding this
      # over the read-only script, but not unattended. save_week_plan writes the
      # local plan file; upload_week_plan pushes it to the intervals.icu
      # calendar, which Garmin and Zwift then sync, and its `clear` argument
      # deletes the existing event range first. That is outward-facing and
      # destructive, so both ask.
      ask = [
        "mcp__intervals-icu__save_week_plan"
        "mcp__intervals-icu__upload_week_plan"
      ];
    };
  };
}
