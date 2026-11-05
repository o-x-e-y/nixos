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
    # spawn time instead of being baked into a world-readable store JSON.
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

    programs.claude-code.settings.permissions = {
      # Alongside intervals-icu.sh: these return the consolidated shapes the
      # coaching prompts use, the script raw JSON. validate_week_plan touches
      # nothing.
      allow = [
        "mcp__intervals-icu__prepare_week_data"
        "mcp__intervals-icu__get_coach_input"
        "mcp__intervals-icu__get_fueling_analysis"
        "mcp__intervals-icu__get_latest_metrics"
        "mcp__intervals-icu__get_activity_streams_sampled"
        "mcp__intervals-icu__list_library_workouts"
        "mcp__intervals-icu__validate_week_plan"
      ];

      # Asked, not denied: writing the plan is why this exists. upload_week_plan
      # pushes to the calendar Garmin and Zwift sync from, and its `clear`
      # deletes the existing event range first.
      ask = [
        "mcp__intervals-icu__save_week_plan"
        "mcp__intervals-icu__upload_week_plan"
      ];
    };
  };
}
