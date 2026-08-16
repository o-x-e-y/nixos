{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps.claude-code;
  status-line = import ./commands/status-line.nix { inherit pkgs; };

  # cronometer-api-mcp is not in nixpkgs, and nixpkgs' python3Packages.mcp
  # (1.27.1) is below the >=1.29 it requires, so it is run from PyPI through
  # uvx rather than built here. Pinned, and pointed at nixpkgs' Python so uv
  # never downloads a non-NixOS interpreter.
  cronometer-mcp-version = "0.2.1";

  intervals-icu = pkgs.writeShellApplication {
    name = "intervals-icu";
    runtimeInputs = with pkgs; [
      curl
      jq
      coreutils
    ];
    text = builtins.readFile ./intervals-icu.sh;
  };
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

    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;

      settings = {
        statusLine = status-line;

        model = "opus";
        effortLevel = "xhigh";
        tui = "fullscreen";

        permissions = {
          allow = [
            "Bash(git diff:*)"
            "Bash(ls:*)"
            "Bash(bun run:*)"
            "Bash(* --version)"
            "Bash(* --help:*)"
            "Bash(grep:*)"
            "Bash(cat:*)"
            "Bash(cargo:*)"
            "Bash(plantuml:*)"
            "Bash(find:*)"
            "Bash(typst compile:*)"
            "Bash(wasm-pack:*)"
            "Bash(git * log:*)"
            "Grep(*)"
            "Glob(*)"
            "Bash(curl:*)"
            "Bash(intervals-icu:*)"
            "WebFetch"

            # The read half of Cronometer: what was logged, and the weight
            # series fuel.py calibrates against.
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
          ask = [ ];
          deny = [
            # Cronometer is an evidence base, not something to edit. Reading
            # the log is the coaching use; writing to it is not.
            "mcp__cronometer__add_food_entry"
            "mcp__cronometer__remove_food_entry"
            "mcp__cronometer__add_custom_food"
            "mcp__cronometer__copy_day"
            "mcp__cronometer__mark_day_complete"

            "Bash(cargo publish:*)"
            "Bash(npm publish:*)"
            "Bash(twine upload:*)"

            "Bash(git push --force:*)"
            "Bash(git push -f:*)"
            "Bash(git reset --hard:*)"
            "Bash(git clean -f:*)"

            "Bash(rm -rf:*)"

            "Read(./.env)"
            "Read(**/.env)"
            "Read(**/.env.*)"
            "Read(./secrets/**)"
            "Read(~/.ssh/**)"
            "Read(~/.gnupg/**)"
            "Read(~/.aws/credentials)"
            "Read(**/*.pem)"
            "Read(**/*.key)"
          ];
          defaultMode = "auto";
          additionalDirectories = [
            "~/Repos"
            "~/Documents/fontys"
          ];
        };
      };

      agents = {
        typst-writer = ./agents/typst-writer.md;
        comptences = ./agents/comptences.md;
        canvas-submit = ./agents/canvas-submit.md;
      };

      commands = {
        coach = ./commands/coach.md;
      };

      plugins = [
        (pkgs.fetchFromGitHub {
          owner = "obra";
          repo = "superpowers";
          rev = "6fd4507659784c351abbd2bc264c7162cfd386dc";
          sha256 = "sha256-P/FD8HTQO+QzvMe3A/B2v2vjs8T6ZmIYH3MPp79dSzo=";
        })
      ];
    };

    home.packages = [
      pkgs.claude-monitor
      intervals-icu
    ];
  };
}
