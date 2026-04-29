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

      settings = {
        statusLine = {
          type = "command";
          command = ''
            input=$(cat)
            used=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.context_window.used_percentage // empty')
            five=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.rate_limits.five_hour.used_percentage // empty')
            week=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.rate_limits.seven_day.used_percentage // empty')
            out=""
            [ -n "$used" ] && out="ctx:$(printf '%.0f' "$used")%"
            [ -n "$five" ] && out="$out 5h:$(printf '%.0f' "$five")%"
            [ -n "$week" ] && out="$out 7d:$(printf '%.0f' "$week")%"
            echo "$out"
          '';
        };

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
            "Grep(*)"
            "Glob(*)"
          ];
          ask = [
            "Bash(curl:*)"
            "WebFetch"
          ];
          deny = [
            "Bash(cargo publish:*)"
            "Read(./.env)"
            "Read(./secrets/**)"
          ];
          defaultMode = "acceptEdits";
          disableBypassPermissionsMode = "disable";
        };
      };

      agents = {
        typst-writer = ./agents/typst-writer.md;
        comptences = ./agents/comptences.md;
        canvas-submit = ./agents/canvas-submit.md;
      };
    };

    home.packages = [
      pkgs.claude-monitor
    ];
  };
}
